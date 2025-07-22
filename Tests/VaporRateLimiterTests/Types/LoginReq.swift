//
//  LoginReq.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 22/07/2025.
//

import Vapor

struct LoginReq: Content {
    let mail: String
    let password: String
}
