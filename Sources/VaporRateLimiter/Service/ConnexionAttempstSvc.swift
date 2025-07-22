//
//  ConnexionAttempsSvc.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor
import Fluent

public struct ConnexionAttempstSvc {
    private let repo: ConnexionAttemptRepository

    public init(repo: ConnexionAttemptRepository) {
        self.repo = repo
    }

    // MARK: - Read

    public func all() async throws -> [ConnexionAttempt] {
        try await repo.all()
    }

    func findBy(ip: String, or mail: String) async throws -> ConnexionAttempt? {
        try await repo.find(by: ip, or: mail)
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String, mail: String) async throws -> Int {
        try await repo.incrementAndReturnCount(ip: ip, mail: mail)
    }

    // MARK: - delete

    public func delete(_ mail: String, logger: Logger) async throws {
        try await repo.delete(mail)
        logger.warning("- ✅ user: \(mail) loged successfully")
    }
}

extension Request {
    public var connexionAttempsSvc: ConnexionAttempstSvc {
        .init(repo: .init(db: self.db))
    }
}
