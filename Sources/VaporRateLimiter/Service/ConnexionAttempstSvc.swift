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
    private let logger: Logger

    public init(repo: ConnexionAttemptRepository, logger: Logger) {
        self.repo = repo
        self.logger = logger
    }

    // MARK: - Read

    public func all() async throws -> [VRLConnexionAttempt] {
        try await repo.all()
    }

    func findBy(ip: String, or mail: String) async throws -> VRLConnexionAttempt? {
        try await repo.find(by: ip, or: mail)
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String, keyId: String) async throws -> Int {
        try await repo.incrementAndReturnCount(ip: ip, keyId: keyId)
    }

    // MARK: - delete

    public func userIsLoged(_ keyID: String) async throws {
        try await repo.delete(keyID)
        logger.warning("- ✅ user: \(keyID) loged successfully")
    }
}

extension Request {
    public var connexionAttempsSvc: ConnexionAttempstSvc {
        .init(repo: .init(db: self.db), logger: self.logger)
    }
}
