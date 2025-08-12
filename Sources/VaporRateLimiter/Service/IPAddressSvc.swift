//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//

import Vapor


/// Returns a *bucketed* client network identifier:
/// - IPv4 -> "a.b.c.0/24"
/// - IPv6 -> "hhhh:hhhh:hhhh:hhhh::/64"
/// Falls back to the raw IP or "unknown" if parsing fails.
/// NOTE: if you are behind an untrusted proxy, consider restricting which headers you trust.
func fetchIPBucket(_ req: Request) -> String { return IPAddressService.bucket(req) }

/// Returns the raw client IP as observed (without bucketing).
/// Order of trust: Forwarded (for=), X-Forwarded-For (first), X-Real-IP, then remoteAddress.
/// May return "unknown" if none are present.
func fetchRawIP(_ req: Request) -> String { return IPAddressService.raw(req) }

/// Centralized IP extraction & bucketing for rate limiting and abuse prevention.
public struct IPAddressService {
    public enum IPVersion { case v4, v6, unknown }

    public static func raw(_ req: Request) -> String {
        return extractClientIP(req)
    }

    public static func bucket(_ req: Request) -> String {
        let ip = extractClientIP(req)
        guard ip != "unknown" else { return "unknown" }
        if let v4 = normalizeIPv4To24(ip) { return v4 }
        if let v6 = normalizeIPv6To64(ip) { return v6 }
        return ip
    }

    public static func version(of ip: String) -> IPVersion {
        if normalizeIPv4To24(ip) != nil { return .v4 }
        if normalizeIPv6To64(ip) != nil { return .v6 }
        return .unknown
    }

    // MARK: - Client IP extraction

    /// Heuristics to extract the client IP from headers.
    /// Order: Forwarded (for=), X-Forwarded-For (first), X-Real-IP, then remoteAddress.
    /// Trims spaces and ignores empty values.
    private static func extractClientIP(_ req: Request) -> String {
        // RFC 7239: Forwarded: for=ip;proto=https;by=...
        if let fwd = req.headers.first(name: "Forwarded") {
            // Can contain multiple, take first "for="
            // Example: for=192.0.2.60, for="[2001:db8::1234]"
            let parts = fwd.split(separator: ";").flatMap { $0.split(separator: ",") }
            for part in parts {
                let trimmed = part.trimmingCharacters(in: .whitespaces)
                if trimmed.lowercased().hasPrefix("for=") {
                    var value = trimmed.dropFirst(4).trimmingCharacters(in: .whitespaces)
                    value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    // Strip brackets for IPv6: [2001:db8::1]
                    if value.hasPrefix("[") && value.hasSuffix("]") {
                        value = String(value.dropFirst().dropLast())
                    }
                    let ip = value
                    if !ip.isEmpty { return ip }
                }
            }
        }

        // X-Forwarded-For: client, proxy1, proxy2
        if let xff = req.headers.first(name: "X-Forwarded-For") {
            let first = xff.split(separator: ",").first?.trimmingCharacters(in: .whitespaces) ?? ""
            if !first.isEmpty { return first }
        }

        // X-Real-IP
        if let xri = req.headers.first(name: "X-Real-IP"), !xri.isEmpty {
            return xri.trimmingCharacters(in: .whitespaces)
        }

        // Fallback: remoteAddress
        if let ip = req.remoteAddress?.ipAddress, !ip.isEmpty {
            return ip
        }

        return "unknown"
    }

    // MARK: - IPv4

    /// Normalize IPv4 "a.b.c.d" into "a.b.c.0/24".
    private static func normalizeIPv4To24(_ ip: String) -> String? {
        let parts = ip.split(separator: ".")
        guard parts.count == 4,
              let a = UInt8(parts[0]),
              let b = UInt8(parts[1]),
              let c = UInt8(parts[2]),
              let _ = UInt8(parts[3]) else {
            return nil
        }
        return "\(a).\(b).\(c).0/24"
    }

    // MARK: - IPv6

    /// Normalize IPv6 to its /64 bucket: "hhhh:hhhh:hhhh:hhhh::/64".
    /// Robust to compressed forms and IPv4-embedded tails (e.g., ::ffff:192.0.2.128).
    private static func normalizeIPv6To64(_ ip: String) -> String? {
        var cleaned = ip
        // Drop zone index if present (e.g., %en0)
        if let percent = cleaned.firstIndex(of: "%") {
            cleaned = String(cleaned[..<percent])
        }
        guard let hextets = expandIPv6(cleaned) else { return nil }
        let first4 = hextets.prefix(4).map { $0.lowercased() }
        return first4.joined(separator: ":") + "::/64"
    }

    /// Expand an IPv6 string (possibly compressed) into exactly 8 hextets (each 1–4 hex chars, lowercased).
    /// Handles IPv4-embedded suffix.
    private static func expandIPv6(_ ip: String) -> [String]? {
        // If it contains an embedded IPv4, convert last two hextets accordingly.
        func ipv4ToTwoHextets(_ v4: String) -> [String]? {
            let parts = v4.split(separator: ".")
            guard parts.count == 4,
                  let a = UInt8(parts[0]),
                  let b = UInt8(parts[1]),
                  let c = UInt8(parts[2]),
                  let d = UInt8(parts[3]) else { return nil }
            let high = UInt16(a) << 8 | UInt16(b)
            let low  = UInt16(c) << 8 | UInt16(d)
            return [String(format: "%x", high), String(format: "%x", low)]
        }

        let lower = ip.lowercased()

        // Split once on '::'
        let doubleColonSplit = lower.split(separator: "::", omittingEmptySubsequences: false)
        if doubleColonSplit.count > 2 { return nil } // invalid

        var leftParts: [String] = []
        var rightParts: [String] = []

        if doubleColonSplit.count == 2 {
            leftParts = doubleColonSplit[0].isEmpty ? [] : doubleColonSplit[0].split(separator: ":").map(String.init)
            rightParts = doubleColonSplit[1].isEmpty ? [] : doubleColonSplit[1].split(separator: ":").map(String.init)
        } else {
            leftParts = lower.split(separator: ":").map(String.init)
        }

        // Handle IPv4 tail in the last part of right or left
        func convertIPv4Tail(in parts: inout [String]) -> Bool {
            if let last = parts.last, last.contains("."),
               let converted = ipv4ToTwoHextets(last) {
                parts.removeLast()
                parts.append(contentsOf: converted)
                return true
            }
            return false
        }
        _ = convertIPv4Tail(in: &leftParts)
        _ = convertIPv4Tail(in: &rightParts)

        // Total hextets must be <= 8 before zero-fill
        let totalCount = leftParts.count + rightParts.count
        if doubleColonSplit.count == 2 {
            if totalCount > 8 { return nil }
            let zerosToInsert = 8 - totalCount
            let expanded = leftParts + Array(repeating: "0", count: zerosToInsert) + rightParts
            return expanded.map { $0.trimmingCharacters(in: .whitespaces) }.map { $0.isEmpty ? "0" : $0 }
        } else {
            // No '::' → must be exactly 8 hextets after possible IPv4 conversion
            if leftParts.count != 8 { return nil }
            return leftParts
        }
    }
}
