//
//  File.swift
//  Mirage
//
//  Created by Bilal Larose on 17/07/2025.
//

import Fluent

struct CreateConnexionAttempt: Migration {
    func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(ConnexionAttempt.schema)
            .id()
            .field("ip", .string, .required)
            .field("mail", .string, .required)
            .field("count", .int, .required)
            .field("timestamp", .datetime, .required)
            .unique(on: "ip")
            .unique(on: "mail")
            .create()
    }
    
    func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema(ConnexionAttempt.schema).delete()
    }

}
