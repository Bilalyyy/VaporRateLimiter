//
//  withApp.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 21/07/2025.
//

import VaporRateLimiter
import Testing
import Fluent
import FluentPostgresDriver
import Vapor


func withApp(_ test: @escaping (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)

        // MARK: - Sessions
        sessionConfiguration(app)

    do {

        // MARK: - Database
        app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
            database: Environment.get("DATABASE_NAME") ?? "vapor_database",
            tls: .prefer(try .init(configuration: .clientDefault)))
        ), as: .psql)


        // MARK: - Out-of-package migration
        app.migrations.add(CreateUser())
        app.migrations.add(SessionRecord.migration)


        // MARK: - Package Migrations
        app.migrations.add(CreateConnexionAttempt())
        app.migrations.add(CreateSignUpAttempt())

        try await app.autoMigrate()


        // MARK: - Routes

        let routes1 = app.routes.grouped("testWithMail")
        let routes2 = app.routes.grouped("testWithAPI")

        let limitedRoutes = routes1.grouped(LoginRateLimiter())
        limitedRoutes.post("login") { req async throws -> HTTPStatus in
            let content = try req.content.decode(LoginReq.self)

            do {
                let userCanLogin = try await req.authSvc.canLogin(from: content)
                try await req.connexionAttempsSvc.userIsLoged(userCanLogin.mail)
                req.authSvc.login(auth: req.auth, user: userCanLogin)

                return .ok
            } catch let error as AuthSvc.AuthError {
                switch error {
                case .authFailled:
                    throw Abort(.unauthorized, reason: "Incorrect username or password")
                }
            } catch {
                // Pour tout autre type d'erreur, retourne une erreur générique
                throw Abort(.internalServerError, reason: "An unexpected error has occurred")
            }
        }


        let limitedWithAPIKey = routes2.grouped(LoginRateLimiter(keyToRegister: "apiKey"))
        limitedWithAPIKey.post("login") { req async throws -> HTTPStatus in

            let content = try req.content.decode(LoginReqByAPI.self)

            do {
                // ... authentication logic ...
                // ... simulate user is authenticated
                try await req.connexionAttempsSvc.userIsLoged(content.apiKey)

                return .ok
            } catch let error as AuthSvc.AuthError {
                switch error {
                case .authFailled:
                    throw Abort(.unauthorized, reason: "Incorrect username or password")
                }
            } catch {
                // Pour tout autre type d'erreur, retourne une erreur générique
                throw Abort(.internalServerError, reason: "An unexpected error has occurred")
            }
        }

        let routes3 = app.routes.grouped("test-ip")
        let protected = routes3.grouped(SignUpRateLimiter())
        protected.post("sign-up") { req async throws -> HTTPStatus in
            let _ = try req.content.decode(SignUpReq.self)

            return .ok
        }

        // MARK: - Tests

        try await test(app)
        try await app.autoRevert()
        try await app.asyncShutdown()

    } catch {
        try await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
}
