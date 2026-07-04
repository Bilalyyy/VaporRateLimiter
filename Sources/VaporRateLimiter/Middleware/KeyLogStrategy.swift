//
//  KeyLogStrategy.swift
//  VaporRateLimiter
//
//  Created by Codex on 04/07/2026.
//

public enum KeyLogStrategy: Sendable, Equatable {
    case redacted
    case prefix(Int)
    case prefixAndSuffix(Int, Int)
    case none

    public func logValue(for key: String) -> String {
        switch self {
        case .redacted:
            return "[redacted]"
        case .prefix(let count):
            let count = max(0, count)
            guard count > 0, key.count > count else {
                return "[redacted]"
            }

            return "\(key.prefix(count))..."
        case .prefixAndSuffix(let prefixCount, let suffixCount):
            let prefixCount = max(0, prefixCount)
            let suffixCount = max(0, suffixCount)
            guard prefixCount > 0 || suffixCount > 0 else {
                return "[redacted]"
            }
            guard key.count > prefixCount + suffixCount else {
                return "[redacted]"
            }

            return "\(key.prefix(prefixCount))...\(key.suffix(suffixCount))"
        case .none:
            return "[not logged]"
        }
    }
}
