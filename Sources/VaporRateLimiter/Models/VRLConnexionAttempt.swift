//
//  ConnexionAtemps.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor
import Fluent

public final class VRLConnexionAttempt: Model, @unchecked Sendable {
    public static let schema = "connexion_attempts"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "ip")
    public var ip: String

    @Field(key: "key_id")
    public var keyId: String

    @Field(key: "count")
    public var count: Int

    @Timestamp(key: "timestamp",on: .update)
    public var timestamp: Date?

    public init() { }

    public init(id: UUID? = nil, ip: String, keyId: String, count: Int, timestamp: Date? = nil) {
        self.id = id
        self.ip = ip
        self.keyId = keyId
        self.count = count
        self.timestamp = timestamp
    }
}

extension VRLConnexionAttempt {
    func toDto() -> ConnexionAttemptDto {
        return .init(id: id, count: count, timestamp: timestamp ?? .now)
    }

    static func createAnAttempt(count: Int) -> Self {
        .init(ip: "127.0.0.1",
        keyId: "foo@bar.com",
        count: count)
    }
}
