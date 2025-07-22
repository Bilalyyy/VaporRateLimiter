//
//  NewAttempt.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 18/07/2025.
//

import Vapor

struct NewAttempt: Content {
    let ip: String
    let mail: String
}

extension NewAttempt {
    func toModel() -> ConnexionAttempt {
        .init(ip: ip, mail: mail, count: 1)
    }
}
