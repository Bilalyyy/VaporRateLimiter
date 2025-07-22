//
//  File.swift
//  Mirage
//
//  Created by Bilal Larose on 16/07/2025.
//

import Vapor
import Fluent

final class User: Model, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "mail")
    var mail: String

    @Field(key: "password_hash")
    var passwordHash: String


    init() { }

    init(id: UUID? = nil, name: String, mail: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.mail = mail
        self.passwordHash = passwordHash
    }

}


extension User: ModelAuthenticatable {

    static let usernameKey: KeyPath<User, Field<String>> = \User.$name
    static let passwordHashKey: KeyPath<User, Field<String>> = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: SessionAuthenticatable {
    var sessionID: UUID {
        self.id ?? UUID()
    }
}

