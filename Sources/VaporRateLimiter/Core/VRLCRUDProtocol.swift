//
//  CRUDProtocol.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 21/07/2025.
//

import Foundation

protocol VRLCRUDProtocol {
    associatedtype Entity

    func all() async throws -> [Entity]
    func find(_ id: UUID) async throws -> Entity?
    func create(_ entity: Entity) async throws
    func update(_ entity: Entity) async throws
    func delete(_ id: UUID) async throws
}

