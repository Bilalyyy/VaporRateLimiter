//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//

import Foundation

import Fluent

public struct CreateSignUpAttempt: Migration {

    public init() { }

    public func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(VRLSignUpAttempt.schema)
            .id()
            .field("ip", .string, .required)
            .field("key_to_register", .string, .required)
            .field("count", .int, .required)
            .field("timestamp", .datetime, .required)
            .unique(on: "ip")
            .create()
    }

    public func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(VRLSignUpAttempt.schema).delete()
    }
}
