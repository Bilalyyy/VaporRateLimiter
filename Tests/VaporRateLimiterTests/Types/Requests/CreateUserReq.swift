//
//  CreateUserReq.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 22/07/2025.
//

import Vapor


struct CreateUserReq: Content {
    let name: String
    let mail: String
    let password: String

    init(name: String, mail: String, password: String) {
        self.name = name
        self.mail = mail
        self.password = password
    }

    func toModel() throws -> User {
        let hash = try Bcrypt.hash(password)

        return User(name: name, mail: mail, passwordHash: hash)
    }
}
