//
//  File.swift
//  Mirage
//
//  Created by Bilal Larose on 16/07/2025.
//

import Vapor

struct UserSvc {

    private let userRepo: UserRepository

    init(userRepo: UserRepository) {
        self.userRepo = userRepo
    }

    // MARK: -Read

    func findBy(mail: String) async throws -> User {
        guard let user = try await userRepo.findBy(mail: mail) else {
            throw Abort(.notFound, reason: "user \(mail) not found")
        }
        return user
    }

}


// MARK: - Utilities

extension UserSvc {

    func verifyPassword(_ password: String, for user: User) async throws -> Bool {
        try user.verify(password: password)
    }
}


extension Request {
    var userSvc: UserSvc {
        .init(userRepo: .init(db: self.db))
    }
}
