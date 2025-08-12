//
//  AttempsDto.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor

struct AttemptDto: Content {
    let id: UUID?
    let count: Int
    let timestamp: Date
}
