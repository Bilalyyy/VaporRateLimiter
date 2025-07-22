//
//  File.swift
//  Mirage
//
//  Created by Bilal Larose on 16/07/2025.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(User.schema)
            .id()
            .field("name", .string, .required)
            .field("mail", .string, .required)
            .unique(on: "mail")
            .field("password_hash", .string, .required)
            .create()
    }

    func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}
