//
//  withApp.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 21/07/2025.
//


import Testing
import Vapor

func withApp(_ body: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    try #require(isLoggingConfigured == true)
    try await body(app)
    try await app.asyncShutdown()
}
