//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//

import Foundation
import Fluent
import SQLKit

public typealias SignUpAttemptRepository = VRLFluentRepository<VRLSignUpAttempt>

// MARK: - CRUD
extension SignUpAttemptRepository {

    // MARK: - Read

    func find(by ip: String) async throws -> VRLSignUpAttempt? {
        try await M.query(on: db)
            .group(.or) { group in
                group.filter((\.$ip == ip))
            }
            .first()
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String) async throws -> Int {
        let sql = db as! any SQLDatabase
        let query: SQLQueryString = """
        INSERT INTO sign_up_attempts (id, ip, count, timestamp)
        VALUES (\(bind: UUID()), \(bind: ip), 1, NOW())
        ON CONFLICT (ip)
        DO UPDATE SET count = sign_up_attempts.count + 1,
                      timestamp = NOW()
        RETURNING count;
        """

        guard let row = try await sql.raw(SQLQueryString(stringInterpolation: query)).first(decoding: AttemptRow.self) else {
            throw FluentError.internalServerError("Impossible de récupérer le compteur")
        }
        return row.count
    }

    // MARK: - delete

    func delete(_ ip: String) async throws {
        try await M.query(on: db)
            .filter(\.$ip == ip)
            .delete()
    }
}
