//
//  FluentRepository.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 21/07/2025.
//


import Fluent

struct FluentRepository<M: Model>: CRUDProtocol where M.IDValue == UUID {

    typealias Entity = M
    let db: any Database

    // MARK: - Read

    func all() async throws -> [M] {
        try await M.query(on: db).all()
    }

    func find(_ id: UUID) async throws -> M? {
        try await M.find(id, on: db)
    }

    //MARK: - Create

    func create(_ model: M) async throws {
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
