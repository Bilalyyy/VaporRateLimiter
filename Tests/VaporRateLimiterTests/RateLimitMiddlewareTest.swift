//
//  File.swift
//  Mirage
//
//  Created by Bilal Larose on 17/07/2025.
//

@testable import VaporRateLimiter
import VaporTesting
import Testing
import Fluent


@Suite("RateLimiter with DB", .serialized)

struct RateMiddlewareTests {
    
    @Test("allows requests under threshold")
    func testAllowsRequestsUnderThreshold() async throws {
        try await withApp { app in
            // Simule un user avec 3 tentatives seulement (< seuil 5)
            let attempts = ConnexionAttempt(
                ip: "127.0.0.1",
                mail: "foo@bar.com",
                count: 3)

            try await attempts.save(on: app.db)

            let loginReq: LoginReq = .init(mail: attempts.mail, password: "pass")

            try await app.testing().test(.POST, "test/login", beforeRequest: { req in
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
            // Simule un user avec 10 tentatives (seuil = 5, penalty exponentiel)

            let attempts = ConnexionAttempt(
                ip: "127.0.0.1",
                mail: "foo@bar.com",
                count: 7)

            try await attempts.save(on: app.db)

            let loginReq: LoginReq = .init(mail: attempts.mail, password: "pass")

            try await app.testing().test(.POST, "test/login", beforeRequest: { req in
                try req.content.encode(loginReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.1")
            }, afterResponse: { res async throws in
                let bodyString = res.body.string
                #expect(bodyString.contains("Too many attempts"))
                #expect(res.status == .tooManyRequests)
            })
        }
    }

    @Test("allows requests first time, while no attempts are registered")
    func testNoAttempsRegistered() async throws {
        try await withApp { app in
            let loginReq: LoginReq = .init(mail: "test@test.com", password: "pass")

            try await app.testing().test(.POST, "test/login", beforeRequest: { req in
                try req.content.encode(loginReq)
                req.headers.replaceOrAdd(name: .init("X-Forwarded-For"), value: "127.0.0.1")
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })

        }
    }

    @Test("penalty is active during penalty window and lifted after delay")
    func testPenaltyActiveAndLiftedAfterDelay() async throws {
        let sut = RateLimit()
        let attempt = ConnexionAttemptDto(id: UUID(), count: 5, timestamp: .now)

        let penaltyIsActive = sut.isPenaltyActive(for: attempt,
                                                  now: .now.addingTimeInterval(30))
        let penaltyIsActiveAfterDelay = sut.isPenaltyActive(for: attempt,
                                                            now: .now.addingTimeInterval(70))

        #expect(penaltyIsActive == true, "We expect penality is true but got false")
        #expect(penaltyIsActiveAfterDelay == false, "We expect penality is false but got true")
    }

    @Test("penalty calculator")
    func testPenaltyCalculator() async throws {
        let sut = RateLimit()

        let nbrAttempts: [Int]              = [0, 1, 2, 3, 4, 5, 6, 10, 16, 21, 26, 31, 36, 41]
        let expectedPenalty: [TimeInterval] = [0, 0, 0, 0, 0, 60, 60, 120, 240, 480, 960, 1_920, 3_840, 7_680]

        for (index, attempts) in nbrAttempts.enumerated() {
            let expected = expectedPenalty[index]
            let actual = sut.penaltyCalculator(attempts)
            #expect(actual == expected, "For \(attempts) attempts, expected \(expected), got \(actual)")
        }
    }
}
