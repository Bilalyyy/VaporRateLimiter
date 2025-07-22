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

        try await app.autoMigrate()


        // MARK: - Routes

        let routes = app.routes.grouped("test")

        let limitedRoutes = routes.grouped(RateLimiter())
        limitedRoutes.post("login") { req async throws -> HTTPStatus in
            let content = try req.content.decode(LoginReq.self)

            do {
                let userCanLogin = try await req.authSvc.canLogin(from: content)
                try await req.connexionAttempsSvc.delete(userCanLogin.mail,logger: req.logger)
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
