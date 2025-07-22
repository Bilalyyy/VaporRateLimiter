//
//  File.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 16/07/2025.
//

import VaporRateLimiter

typealias UserRepository = FluentRepository<User>

extension UserRepository {

    // MARK: - Read

    func findBy(mail: String) async throws -> User? {
        try await M.query(on: db)
            .filter(\.$mail, .equal, mail)
            .first()
    }
}
