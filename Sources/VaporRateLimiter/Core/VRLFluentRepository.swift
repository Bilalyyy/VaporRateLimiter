//
//  FluentRepository.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 21/07/2025.
//

import Foundation
import Fluent

public struct VRLFluentRepository<M: Model>: VRLCRUDProtocol where M.IDValue == UUID {

    typealias Entity = M
    public let db: any Database

    public init(db: any Database) {
        self.db = db
    }

    // MARK: - Read

    func all() async throws -> [M] {
        try await M.query(on: db).all()
    }

    func find(_ id: UUID) async throws -> M? {
        try await M.find(id, on: db)
    }

    //MARK: - Create

    public func create(_ model: M) async throws {
        try await model.create(on: db)
    }

    //MARK: - Update

    func update(_ model: M) async throws {
        try await model.update(on: db)
    }

    //MARK: - Delete

    func delete(_ id: UUID) async throws {
        try await M.query(on: db)
            .filter( \._$id == id)
            .delete()
    }

}

// MARK: - Utilities

extension VRLFluentRepository {
    struct AttemptRow: Decodable { let count: Int }

    enum FluentError: Error {
        case internalServerError(String)
    }
}
