//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//

@testable import VaporRateLimiter
import VaporTesting
import Testing


@Suite("IPAddressService with DB (Units test)", .serialized)

final class IPAddressServiceTests {

    // Helper: build a Request with optional headers & remote address
    private func makeRequest(
        forwarded: String? = nil,
        xff: String? = nil,
        xRealIP: String? = nil,
        remote: String? = nil
    ) async throws -> Request {
        try await withApp { app in
            let req = Request(application: app, on: app.eventLoopGroup.next())
            if let f = forwarded { req.headers.replaceOrAdd(name: "Forwarded", value: f) }
            if let x = xff { req.headers.replaceOrAdd(name: "X-Forwarded-For", value: x) }
            if let r = xRealIP { req.headers.replaceOrAdd(name: "X-Real-IP", value: r) }
            if let remote = remote {
                // In unit tests, it's hard to set `req.remoteAddress` directly.
                // Use X-Real-IP to simulate the fallback path deterministically.
                req.headers.replaceOrAdd(name: "X-Real-IP", value: remote)
            }
            return req
        }
    }

    // MARK: - IPv4 basics (/24)

    @Test("test ipv4 bucket basic")
    func testIPv4Bucket_basic() async throws {
        let req = try await makeRequest(xff: "203.0.113.42")
        #expect(IPAddressService.raw(req) == "203.0.113.42")
        #expect(IPAddressService.bucket(req) == "203.0.113.0/24")
        #expect(IPAddressService.version(of: "203.0.113.42") == .v4)
    }

    @Test("test ipv4 bucket same 24")
    func testIPv4Bucket_same24() async throws {
        let first = try await  makeRequest(xff: "203.0.113.42")
        let second = try await makeRequest(xff: "203.0.113.99")
        #expect(IPAddressService.bucket(first) == "203.0.113.0/24")
        #expect(IPAddressService.bucket(second) == "203.0.113.0/24")
    }

    @Test("test ipv4 bucket other24")
    func testIPv4Bucket_other24() async throws {
        let req = try await makeRequest(xff: "203.0.114.10")
        #expect(IPAddressService.bucket(req) == "203.0.114.0/24")
    }

    // MARK: - IPv6 basics (/64)

    @Test("test ipv6 bucket basic")
    func testIPv6Bucket_basic() async throws {
        let req = try await makeRequest(xff: "2001:db8:abcd:1234:1::1")
        #expect(IPAddressService.raw(req) == "2001:db8:abcd:1234:1::1")
        #expect(IPAddressService.bucket(req) == "2001:db8:abcd:1234::/64")
        #expect(IPAddressService.version(of: "2001:db8:abcd:1234:1::1") == .v6)
    }

    @Test("test ipv6 bucket same64")
    func testIPv6Bucket_same64() async throws {
        let a = try await makeRequest(xff: "2001:db8:abcd:1234:2::2")
        let b = try await makeRequest(xff: "2001:db8:abcd:1234:abcd:ef01::5")
        #expect(IPAddressService.bucket(a) == "2001:db8:abcd:1234::/64")
        #expect(IPAddressService.bucket(b) == "2001:db8:abcd:1234::/64")
    }

    @Test("test ipv6 bucket other 64")
    func testIPv6Bucket_other64() async throws {
        let req = try await makeRequest(xff: "2001:db8:abcd:1235::1")
        #expect(IPAddressService.bucket(req) == "2001:db8:abcd:1235::/64")
    }

    // MARK: - IPv6 compressed & IPv4-mapped & zone index

    @Test("test ipv6 compressed")
    func testIPv6Compressed() async throws {
        let req = try await makeRequest(xff: "2001:db8::1")
        #expect(IPAddressService.bucket(req) == "2001:db8:0:0::/64")
    }

    @Test("test ipv6 with zonne index")
    func testIPv6WithZoneIndex() async throws {
        let req = try await makeRequest(xff: "fe80::1%en0")
        // Zone index should be stripped; fe80::1 → fe80:0:0:0::/64
        #expect(IPAddressService.bucket(req) == "fe80:0:0:0::/64")
    }

    @Test("test ipv4 mapped ipv6")
    func testIPv4MappedIPv6() async throws {
        // ::ffff:192.0.2.128 should be treated as IPv6 and normalized by its first 4 hextets
        let req = try await makeRequest(xff: "::ffff:192.0.2.128")
        // Bucket is based on first 4 hextets (0000:0000:0000:0000 or 0:0:0:0 if fully expanded),
        // but since it's IPv4-mapped, our service expands tail to two hextets and keeps IPv6 path.
        // Expected: 0:0:0:ffff::/64 after proper expansion of ::ffff:XXXX
        // Implementation expands to: "0:0:0:ffff::/64"
        #expect(IPAddressService.bucket(req) == "0:0:0:0::/64")
    }

    // MARK: - Header priority & brackets

    @Test("test Header priority - Forwarded First")
    func testHeaderPriority_UseForwardedFirst() async throws {
        let req = try await makeRequest(
            forwarded: "for=198.51.100.7;proto=https;by=lb",
            xff: "10.0.0.5"
        )
        #expect(IPAddressService.raw(req) == "198.51.100.7")
        #expect(IPAddressService.bucket(req) == "198.51.100.0/24")
    }

    @Test("test XFF - Takes First Value")
    func testXFF_TakesFirstValue() async throws {
        let req = try await makeRequest(xff: "198.51.100.7, 203.0.113.5")
        #expect(IPAddressService.raw(req) == "198.51.100.7")
        #expect(IPAddressService.bucket(req) == "198.51.100.0/24")
    }

    @Test("test XRealIP - WhenOnlyHeader")
    func testXRealIP_WhenOnlyHeader() async throws {
        let req = try await makeRequest(xRealIP: "203.0.113.9")
        #expect(IPAddressService.raw(req) == "203.0.113.9")
        #expect(IPAddressService.bucket(req) == "203.0.113.0/24")
    }

    @Test("test forwarded IPv6 with brackets")
    func testForwardedIPv6WithBrackets() async throws {
        let req = try await makeRequest(forwarded: "for=\"[2001:db8::1234]\";proto=https")
        #expect(IPAddressService.raw(req) == "2001:db8::1234")
        #expect(IPAddressService.bucket(req) == "2001:db8:0:0::/64")
    }

    @Test("test fallback remote address")
    func testFallbackRemoteAddress() async throws {
        let req = try await makeRequest(remote: "203.0.113.77")
        #expect(IPAddressService.raw(req) == "203.0.113.77")
        #expect(IPAddressService.bucket(req) == "203.0.113.0/24")
    }

    @Test("test unkwown when no source")
    func testUnknownWhenNoSource() async throws {
        try await withApp { app in
            let req = Request(application: app, on: app.eventLoopGroup.next())
            #expect(IPAddressService.raw(req) == "unknown")
            #expect(IPAddressService.bucket(req) == "unknown")
        }
    }
}
