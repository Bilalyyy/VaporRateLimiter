//
//  ConnexionAttempRepository.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Foundation
import Fluent
import SQLKit

public typealias ConnexionAttemptRepository = VRLFluentRepository<VRLConnexionAttempt>

// MARK: - CRUD
extension ConnexionAttemptRepository {

    // MARK: - Read

    func find(by ip: String, or keyId: String) async throws -> VRLConnexionAttempt? {
        try await M.query(on: db)
            .group(.or) { group in
                group.filter((\.$ip == ip))
                group.filter((\.$keyId == keyId))
            }
            .first()
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String, keyId: String) async throws -> Int {
        let sql = db as! any SQLDatabase
        let query: SQLQueryString = """
        INSERT INTO connexion_attempts (id, ip, key_id, count, timestamp)
        VALUES (\(bind: UUID()), \(bind: ip), \(bind: keyId), 1, NOW())
        ON CONFLICT (ip, key_id)
        DO UPDATE SET count = connexion_attempts.count + 1, timestamp = NOW()
        RETURNING count;
        """

        guard let row = try await sql.raw(SQLQueryString(stringInterpolation: query)).first(decoding: AttemptRow.self) else {
            throw FluentError.internalServerError("Impossible de récupérer le compteur")
        }
        return row.count
    }


    // MARK: - delete

    func delete(_ keyId: String) async throws {
        try await M.query(on: db)
            .filter(\.$keyId == keyId)
            .delete()
    }
}

// MARK: - Utilities

extension ConnexionAttemptRepository {
    struct AttemptRow: Decodable { let count: Int }

    enum FluentError: Error {
        case internalServerError(String)
    }
}
