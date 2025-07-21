//
//  ConnexionAtemps.swift
//  Mirage
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor
import Fluent

final class ConnexionAttempt: Model, @unchecked Sendable {
    static let schema = "connexion_attempts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "ip")
    var ip: String

    @Field(key: "mail")
    var mail: String

    @Field(key: "count")
    var count: Int

    @Timestamp(key: "timestamp",on: .update)
    var timestamp: Date?

    init() { }

    init(id: UUID? = nil, ip: String, mail: String, count: Int, timestamp: Date? = nil) {
        self.id = id
        self.ip = ip
        self.mail = mail
        self.count = count
        self.timestamp = timestamp
    }
}

//MARK: - function

extension ConnexionAttempt {
    func toDto() -> ConnexionAttemptDto {
        return .init(id: id, count: count, timestamp: timestamp ?? .now)
    }
}
