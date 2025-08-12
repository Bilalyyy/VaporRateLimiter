//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//

import Vapor
import Fluent

public final class VRLSignUpAttempt: Model, @unchecked Sendable {
    public static let schema = "sign_up_attempts"

    @ID(key: .id)
    public var id: UUID?

    @Field(key: "ip")
    public var ip: String

    @Field(key: "count")
    public var count: Int

    @Timestamp(key: "timestamp",on: .update)
    public var timestamp: Date?

    public init() { }

    public init(id: UUID? = nil, ip: String, count: Int, timestamp: Date? = nil) {
        self.id = id
        self.ip = ip
        self.count = count
        self.timestamp = timestamp
    }
}

extension VRLSignUpAttempt {
    func toDto() -> AttemptDto {
        return .init(id: id, count: count, timestamp: timestamp ?? .now)
    }

    static func createAnAttempt(count: Int) -> Self {
        .init(ip: "127.0.0.0/24", count: count)
    }
}
