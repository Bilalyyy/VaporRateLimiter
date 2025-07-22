//
//  ConnexionAttempsSvc.swift
//  Mirage
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

    // MARK: - Create

    func create(_ dto: NewAttempt) async throws {
        let model = dto.toModel()
        try await repo.create(model)
    }

    // MARK: - Read

    func all() async throws -> [ConnexionAttempt] {
        try await repo.all()
    }

    func find(_ id: UUID) async throws -> ConnexionAttemptDto? {
        try await repo.find(id)?.toDto()
    }

    func findBy(ip: String, or mail: String) async throws -> ConnexionAttempt? {
        try await repo.find(by: ip, or: mail)
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String, mail: String) async throws -> Int {
        try await repo.incrementAndReturnCount(ip: ip, mail: mail)
    }

    // MARK: - delete

    public func delete(_ mail: String) async throws {
        try await repo.delete(mail)
    }

    func delete(_ id: UUID) async throws {
        try await repo.delete(id)
    }

}

extension Request {
    var connexionAttempsSvc: ConnexionAttempstSvc {
        .init(repo: .init(db: self.db))
    }
}
