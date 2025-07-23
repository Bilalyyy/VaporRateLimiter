//
//  AuthControllerTests.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 17/07/2025.
//
// Integration tests for the VaporRateLimiter middleware in a real-world setting.
// - Verifies the middleware's integration with the authentication and session system.
// - Simulates user login scenarios, attempt management, deletion after success, blocking after threshold exceedance, etc.
// - Ensures that the middleware functions correctly in the real-world application environment.
//
// Uses a test database (Fluent/Postgres) and VaporTesting.

@testable import VaporRateLimiter
import VaporTesting
import Testing
import Fluent


@Suite("Auth / Sessions controller with DB (integration tests)", .serialized)

struct AuthControllerTests {
// MARK: - Login
    // MARK: login is successfully

    @Test("The user successfully login")
    func successfullyLogin() async throws {
        try await withApp { app in
            // 1. Create user in DB
            let newUser = CreateUserReq(name: "testuser", mail: "test@test.com", password: "password")
            let req = Request(application: app, on: app.db.eventLoop)
            try await newUser.toModel().save(on: req.db)

            // 2. Create content request
            let loginReq: LoginReq = .init(mail: newUser.mail, password: newUser.password)

            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let setCookieHeader = res.headers["set-cookie"]
                #expect(setCookieHeader.count > 0) // There must be a session cookie
            })
        }
    }

    @Test("Delete attempt when user is loged")
    func testDeleteAttemptWhenUserIsLoged() async throws {
        try await withApp { app in
            let req = Request(application: app, on: app.db.eventLoop)
            let newUser = CreateUserReq(name: "Bilal", mail: "test@test.com", password: "pass")
            try await req.userSvc.create(from: newUser)

            let attempt = ConnexionAttempt(ip: "127.0.0.1", keyId: "test@test.com", count: 2)
            try await attempt.save(on: req.db)

            let loginReq = LoginReq(mail: "test@test.com", password: "pass")
            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            let savedAttempts = try await req.connexionAttempsSvc.all()
            #expect(!savedAttempts.contains(where: { $0.keyId == attempt.keyId }))

        }
    }

    // MARK: - login fails

    @Test("User fails to log in (bad password)")
    func failsLoginByPassword() async throws {
        try await withApp { app in
            // 1. Create user in DB
            let newUser = CreateUserReq(name: "testuser", mail: "test@test.com", password: "password")
            try await newUser.toModel().save(on: app.db)


            let req = Request(application: app, on: app.db.eventLoop)

            // 2. Create content request
            let loginReq: LoginReq = .init(mail: newUser.mail, password: "bad password")

            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
                let setCookieHeader = res.headers["set-cookie"]
                #expect(setCookieHeader.count == 0) // It should not have a session cookie

                let attemps = try await req.connexionAttempsSvc.all()
                #expect(attemps.contains(where: { $0.keyId == newUser.mail }))
            })
        }
    }

    @Test("User fails to log in (user not foound)")
    func failsLoginByUserNotFound() async throws {
        try await withApp { app in
            // 1. Create user in DB
            let newUser = CreateUserReq(name: "testuser", mail: "test@test.com", password: "password")
            let req = Request(application: app, on: app.db.eventLoop)
            try await newUser.toModel().save(on: req.db)

            // 2. Create content request
            let loginReq: LoginReq = .init(mail: "bad@mail.com", password: newUser.password)

            try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
                let setCookieHeader = res.headers["set-cookie"]
                #expect(setCookieHeader.count == 0) // It should not have a session cookie

                let attemps = try await req.connexionAttempsSvc.all()
                #expect(attemps.contains(where: { $0.keyId == loginReq.mail }))

            })
        }
    }

    
    @Test("Test multiple non concurrent requests with bad credentials")
    func testMultipleLoginReqWithoutConcurrent() async throws {
        try await withApp { app in
            let req = Request(application: app, on: app.db.eventLoop)

            let loginReq: LoginReq = .init(mail: "bad@mail.com", password: "bad credentiel")

            let updateCount = 250
            var statuses: [HTTPStatus] = []
            for _ in 0..<updateCount {
                try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                    try req.content.encode(loginReq)
                }, afterResponse: { res async throws in
                    statuses.append(res.status)
                })
            }

            // Vérifie les réponses
            let unauthorizedCount = statuses.filter { $0 == .unauthorized }.count
            let tooManyRequestsCount = statuses.filter { $0 == .tooManyRequests }.count

            #expect(unauthorizedCount <= 5, "We expect a maximum of 5 unauthorized cases before the rate limit is reached: \(unauthorizedCount)")
            #expect(tooManyRequestsCount >= (updateCount - 5), "The following must be blocked (\(tooManyRequestsCount) == \(updateCount - 5))")

            // Check that the base counter is correct
            let attempts = try await req.connexionAttempsSvc.all()
            guard let attempt = attempts.first(where: { $0.keyId == loginReq.mail }) else {
                throw Abort(.notFound, reason: "No attempts found for this email")
            }

            #expect(attempt.count == updateCount, "The counter should be at \(updateCount), found: \(attempt.count)")
        }
    }

    @Test("Test multiple concurrent requests with bad credentials")
    func testMultipleLoginReq() async throws {
        try await withApp { app in
            let req = Request(application: app, on: app.db.eventLoop)

            let loginReq: LoginReq = .init(mail: "bad@mail.com", password: "bad credentiel")

            let updateCount = 150
            let statusesActor = StatusesActor()

            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0..<updateCount {
                    group.addTask {
                        try await app.testing().test(.POST, "testWithMail/login", beforeRequest: { req in
                            try req.content.encode(loginReq)
                        }, afterResponse: { res async throws in
                            await statusesActor.append(res.status)
                        })
                    }
                }
                try await group.waitForAll()
            }

            // Check results
            let statusesResponse = await statusesActor.all()
            let unauthorizedCount = statusesResponse.filter { $0 == .unauthorized }.count
            let tooManyRequestsCount = statusesResponse.filter { $0 == .tooManyRequests }.count

            let tolerance = Int(Double(updateCount) * 0.95)

            #expect(unauthorizedCount <= 5, "unauthorized must not be higher than 5 (threshold). We found some (\(unauthorizedCount))")
            #expect(tooManyRequestsCount >= (updateCount - 5), "tooManyRequestsCount must not be less than \(updateCount - 5). We found some (\(tooManyRequestsCount))")
            #expect(unauthorizedCount + tooManyRequestsCount >= tolerance , "Total number of responses found is higher than the tolerance threshold. Expected = \(tolerance), found =\(unauthorizedCount + tooManyRequestsCount)")

            // Vérifie que le compteur en base est correct
            let attempts = try await req.connexionAttempsSvc.all()
            guard let attempt = attempts.first(where: { $0.keyId == loginReq.mail }) else {
                throw Abort(.notFound, reason: "No attempts found for this email")
            }

            #expect(attempt.count >= tolerance, "The counter should be at \(updateCount), only \(attempt.count) were recorded.")
        }
    }

    @Test("with a key other than 'mail'")
    func withKeyOtherThanMail() async throws {
        try await withApp { app in
            let req = Request(application: app, on: app.db.eventLoop)
            // create attempt to simulate 2 fails
            let attempt = ConnexionAttempt(ip: "127.0.0.1", keyId: "My_API_Key", count: 2)
            try await attempt.save(on: req.db)

            let loginReq = LoginReqByAPI(apiKey: "My_API_Key", password: "pass")

            try await app.testing().test(.POST, "testWithAPI/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })

            let savedAttempts = try await req.connexionAttempsSvc.all()
            #expect(!savedAttempts.contains(where: { $0.keyId == attempt.keyId }))

        }
    }
}

struct LoginReqByAPI: Content {
    let apiKey: String
    let password: String
}

actor StatusesActor {
    private var array: [HTTPStatus] = []
    func append(_ status: HTTPStatus) {
        array.append(status)
    }
    func all() -> [HTTPStatus] { array }
}
