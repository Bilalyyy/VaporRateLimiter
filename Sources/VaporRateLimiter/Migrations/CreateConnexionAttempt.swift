//
//  File.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Fluent

public struct CreateConnexionAttempt: Migration {

    public init() { }

    public func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(ConnexionAttempt.schema)
            .id()
            .field("ip", .string, .required)
            .field("key_id", .string, .required)
            .field("count", .int, .required)
            .field("timestamp", .datetime, .required)
            .unique(on: "ip")
            .unique(on: "key_id")
            .create()
    }
    
    public func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(ConnexionAttempt.schema).delete()
    }
}
