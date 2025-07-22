//
//  File.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 22/07/2025.
//

import Vapor

func sessionConfiguration(_ app: Application) {
    app.sessions.use(.fluent)
    app.sessions.configuration.cookieName = "RateLimiter-test-session"

    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())

}
