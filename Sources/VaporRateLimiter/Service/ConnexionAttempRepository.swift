//
//  ConnexionAttempRepository.swift
//  Mirage
//
//  Created by Bilal Larose on 17/07/2025.
//

import Fluent
import SQLKit

public typealias ConnexionAttemptRepository = FluentRepository<ConnexionAttempt>

// MARK: - CRUD
extension ConnexionAttemptRepository {

    // MARK: - Read

    func find(by ip: String, or mail: String) async throws -> ConnexionAttempt? {
        try await M.query(on: db)
            .group(.or) { group in
                group.filter((\.$ip == ip))
                group.filter((\.$mail == mail))
            }
            .first()
    }

    // MARK: - Update

    func incrementAndReturnCount(ip: String, mail: String) async throws -> Int {
        let sql = db as! any SQLDatabase
        let query: SQLQueryString = """
        INSERT INTO connexion_attempts (id, ip, mail, count, timestamp)
        VALUES (\(bind: UUID()), \(bind: ip), \(bind: mail), 1, NOW())
        ON CONFLICT (mail)
        DO UPDATE SET count = connexion_attempts.count + 1, timestamp = NOW()
        RETURNING count;
        """

        guard let row = try await sql.raw(SQLQueryString(stringInterpolation: query)).first(decoding: AttemptRow.self) else {
            throw FluentError.internalServerError("Impossible de récupérer le compteur")
        }
        return row.count
    }


    // MARK: - delete

    func delete(_ mail: String) async throws {
        try await M.query(on: db)
            .filter( \.$mail == mail)
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
