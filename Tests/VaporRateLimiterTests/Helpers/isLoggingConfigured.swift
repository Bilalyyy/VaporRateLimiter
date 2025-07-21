//
//  isLoggingConfigured.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 21/07/2025.
//


import Vapor

let isLoggingConfigured: Bool = {
    LoggingSystem.bootstrap { label in
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = .debug
        return handler
    }
    return true
}()
