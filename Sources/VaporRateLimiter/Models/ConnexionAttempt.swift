//
//  ConnexionAtemps.swift
//  Mirage
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor
import Fluent

public final class ConnexionAttempt: Model, @unchecked Sendable {
    public static let schema = "connexion_attempts"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "ip")
    public var ip: String

    @Field(key: "mail")
    public var mail: String

    @Field(key: "count")
    public var count: Int

    @Timestamp(key: "timestamp",on: .update)
    public var timestamp: Date?

    public init() { }

    public init(id: UUID? = nil, ip: String, mail: String, count: Int, timestamp: Date? = nil) {
        self.id = id
        self.ip = ip
        self.mail = mail
        self.count = count
        self.timestamp = timestamp
    }
}

extension ConnexionAttempt {
    func toDto() -> ConnexionAttemptDto {
        return .init(id: id, count: count, timestamp: timestamp ?? .now)
    }

    static func createAnAttempt(count: Int) -> Self {
        .init(ip: "127.0.0.1",
        mail: "foo@bar.com",
        count: count)
    }
}
