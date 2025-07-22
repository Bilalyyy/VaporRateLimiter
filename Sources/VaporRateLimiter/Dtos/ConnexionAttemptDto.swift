//
//  ConnexionAttempsDto.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor

struct ConnexionAttemptDto: Content {
    let id: UUID?
    let count: Int
    let timestamp: Date
}
