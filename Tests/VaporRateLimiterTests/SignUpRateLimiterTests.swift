//
//  SignInRateLimiterTests.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//
//  Unit tests for the SignInRateLimiter middleware.
//  - Verifies threshold behavior, penalty activation and lifting, timeout calculation.
//  - Mirrors RateMiddlewareTests but targets the /signin path and a stricter threshold (2).
//

@testable import VaporRateLimiter
import VaporTesting
import Testing
import Fluent

@Suite("Sign up RateLimiter with DB (Units test)", .serialized)
struct SignUpRateLimiterTests {
    
    @Test("allows requests under threshold (threshold=2)")
    func testAllowsRequestsUnderThreshold() async throws {
        try await withApp { app in
            // Simulate a user with only 1 attempt (< threshold 2)
            let attempts = VRLConnexionAttempt.createAnAttempt(count: 1)
            try await attempts.save(on: app.db)

            let signinReq: SignUpReq = .init(ip: attempts.ip, mail: "test@mail.com")

            try await app.testing().test(.POST, "test-ip/sign-up", beforeRequest: { req in
                try req.content.encode(signinReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.42")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)

            })
        }
    }

    @Test("blocks requests above threshold (threshold=2)")
    func testBlocksRequestsAboveThreshold() async throws {
        try await withApp { app in
            // Simulate a user already over the threshold (e.g., 3 attempts)
            let attempts = VRLSignUpAttempt.createAnAttempt(count: 3)
            try await attempts.save(on: app.db)

            let signinReq: SignUpReq = .init(ip: attempts.ip, mail: "test@mail.com")

            try await app.testing().test(.POST, "test-ip/sign-up", beforeRequest: { req in
                try req.content.encode(signinReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.1")
            }, afterResponse: { res async throws in
                let bodyString = res.body.string
                #expect(bodyString.contains("Too many sign in"))
                #expect(res.status == .tooManyRequests)
            })
        }
    }

    @Test("Middleware should not return 429 on first attempt; downstream returns 401")
    func testPassesThroughWhenNoAttempts() async throws {
        try await withApp { app in
            let signinReq: LoginReq = .init(mail: "test-signin@test.com", password: "pass")
            
            try await app.testing().test(.POST, "test-ip/sign-up", beforeRequest: { req in
                try req.content.encode(signinReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.9")
            }, afterResponse: { res async throws in
                // No attempts -> middleware should let the pipeline continue (here ends in 401)
                #expect(res.status != .tooManyRequests)
            })
        }
    }

    @Test("penalty is active during penalty window and lifted after delay (threshold=2)")
    func testPenaltyActiveAndLiftedAfterDelay() async throws {
        // For threshold=2, the first penalty step is 60s at 2 attempts
        let attempt = AttemptDto(id: UUID(), count: 2, timestamp: .now)
        
        let active = isPenaltyActive(for: attempt, baseTimeFrame: 240, now: .now.addingTimeInterval(30), threshold: 2)
        let lifted = isPenaltyActive(for: attempt, baseTimeFrame: 240, now: .now.addingTimeInterval(250), threshold: 2)
        
        #expect(active == true, "Expected penalty to be active at +30s for threshold=2")
        #expect(lifted == false, "Expected penalty to be lifted at +70s for threshold=2")
    }

    @Test("penalty calculator with threshold=2")
    func testPenaltyCalculator() async throws {
        // For threshold=2:
        // attempts < 2 -> 0s
        // 2..3 -> 240s
        // 4..5 -> 480s
        // 6..7 -> 960s
        // 8..9 -> 960s
        let attempts: [Int]              = [0, 1, 2, 3, 4, 5, 6, 7]
        let expected: [TimeInterval]     = [0, 0, 240, 240, 480, 480, 960, 960]
        
        for (i, count) in attempts.enumerated() {
            let exp = expected[i]
            let got = penaltyCalculator(count, baseTimeFrame: 240, threshold: 2)
            #expect(got == exp, "For \(count) attempts, expected \(exp), got \(got)")
        }
    }
}
