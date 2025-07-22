//
//  File.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor

protocol AuthProtocol {
    func canLogin(from: LoginReq) async throws -> User
}
