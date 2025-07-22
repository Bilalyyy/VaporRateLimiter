//
//  File.swift
//  Mirage
//
//  Created by Bilal Larose on 17/07/2025.
//

import Fluent
import Vapor

struct AuthSvc: AuthProtocol {
    
    private let db: any Database
    private let userSvc: UserSvc
    
    init(db: any Database, userSvc: UserSvc) {
        self.db = db
        self.userSvc = userSvc
    }
    
    func canLogin(from req: LoginReq) async throws -> User {
        //1. Find user
        guard let user = try? await userSvc.findBy(mail: req.mail) else {
            throw AuthError.authFailled
        }
        //2. Verify password
        guard try await userSvc.verifyPassword(req.password, for: user) else {
            throw AuthError.authFailled
        }
        //3. Return user
        return user
    }
    
    func login(auth: Request.Authentication, user: User) {
        auth.login(user)
    }

}

extension AuthSvc {
    enum AuthError: Error {
        case authFailled
    }
}

extension Request {
    var authSvc: AuthSvc {
        .init(db: self.db, userSvc: UserSvc(userRepo: .init(db: self.db)))
    }
}
