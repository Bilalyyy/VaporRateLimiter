
//
//  LoginRateMiddlewareTests.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 17/07/2025.
//
// Unit tests for the VaporRateLimiter middleware.
// - Verifies the behavior of the middleware alone: threshold management, penalty activation and lifting, timeout calculation, etc.
// - These tests are isolated from the actual authentication logic.
//
// Uses a test database (Fluent/Postgres) to simulate attempts.

@testable import VaporRateLimiter
import VaporTesting
import Testing
import Fluent


@Suite("Login RateLimiter with DB (Units test)", .serialized)

struct LoginRateMiddlewareTests {
    
    @Test("allows requests under threshold")
    func testAllowsRequestsUnderThreshold() async throws {
        try await withApp { app in
            // Simulates a user with only 3 attempts (< threshold 5)
            let attempts = VRLConnexionAttempt.createAnAttempt(count: 3)

            try await attempts.save(on: app.db)

            let loginReq: LoginReq = .init(mail: attempts.keyId, password: "pass")

            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.1")

            }, afterResponse: { res async throws in

                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test("blocks requests above threshold")
    func testBlocksRequestsAboveThreshold() async throws {
        try await withApp { app in
            // Simulates a user with 7 attempts (threshold = 5)
            let attempts = VRLConnexionAttempt.createAnAttempt(count: 7)

            try await attempts.save(on: app.db)

            let loginReq: LoginReq = .init(mail: attempts.keyId, password: "pass")

            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.1")
            }, afterResponse: { res async throws in
                let bodyString = res.body.string
                #expect(bodyString.contains("Too many attempts"))
                #expect(res.status == .tooManyRequests)
            })
        }
    }

    @Test("Middleware should not return 429 on first attempt; downstream returns 401")
    func testNoAttempsRegistered() async throws {
        try await withApp { app in
            let loginReq: LoginReq = .init(mail: "test@test.com", password: "pass")

            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.1")
            }, afterResponse: { res async throws in
                #expect(res.status != .tooManyRequests)
            })

        }
    }

    @Test("penalty is active during penalty window and lifted after delay")
    func testPenaltyActiveAndLiftedAfterDelay() async throws {
        let attempt = ConnexionAttemptDto(id: UUID(), count: 5, timestamp: .now)

        let penaltyIsActive = isPenaltyActive(for: attempt, baseTimeFrame: 60,
                                              now: .now.addingTimeInterval(30), threshold: 5)
        let penaltyIsActiveAfterDelay = isPenaltyActive(for: attempt, baseTimeFrame: 60,
                                                            now: .now.addingTimeInterval(70), threshold: 5)

        #expect(penaltyIsActive == true, "We expect penality is true but got false")
        #expect(penaltyIsActiveAfterDelay == false, "We expect penality is false but got true")
    }

    @Test("penalty calculator")
    func testPenaltyCalculator() async throws {
        let nbrAttempts: [Int]              = [0, 1, 2, 3, 4, 5, 6, 10, 16, 21, 26, 31, 36, 41]
        let expectedPenalty: [TimeInterval] = [0, 0, 0, 0, 0, 60, 60, 120, 240, 480, 960, 1_920, 3_840, 7_680]

        for (index, attempts) in nbrAttempts.enumerated() {
            let expected = expectedPenalty[index]
            let actual = penaltyCalculator(attempts, threshold: 5)
            #expect(actual == expected, "For \(attempts) attempts, expected \(expected), got \(actual)")
        }
    }
}
