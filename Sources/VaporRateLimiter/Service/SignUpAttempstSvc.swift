//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//

import Vapor
import Fluent

public struct SignUpAttempstSvc {
    private let repo: SignUpAttemptRepository
    private let logger: Logger

    public init(repo: SignUpAttemptRepository, logger: Logger) {
        self.repo = repo
        self.logger = logger
    }

    // MARK: - Read

    public func all() async throws -> [VRLSignUpAttempt] {
        try await repo.all()
    }

    func findBy(ip: String) async throws -> VRLSignUpAttempt? {
        try await repo.find(by: ip)
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String, mail: String) async throws -> Int {
        try await repo.incrementAndReturnCount(ip: ip, mail: mail)
    }

    // MARK: - delete

    public func userIsLoged(_ ip: String) async throws {
        try await repo.delete(ip)
        logger.warning("- ✅ user: \(ip) loged successfully")
    }
}

extension Request {
    public var signUpAttempsSvc: SignUpAttempstSvc {
        .init(repo: .init(db: self.db), logger: self.logger)
    }
}
