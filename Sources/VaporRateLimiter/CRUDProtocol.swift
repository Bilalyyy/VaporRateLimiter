// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation


protocol CRUDProtocol {
    associatedtype Entity

    func all() async throws -> [Entity]
    func find(_ id: UUID) async throws -> Entity?
    func create(_ entity: Entity) async throws
    func update(_ entity: Entity) async throws
    func delete(_ id: UUID) async throws
}

