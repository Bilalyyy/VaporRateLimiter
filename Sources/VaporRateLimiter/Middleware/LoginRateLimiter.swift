//
//  RateLimitMiddleware.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor
import Fluent

public final class LoginRateLimiter: AsyncMiddleware {
    private let threshold: Int
    private let baseTimeFrame: TimeInterval
    private let skipInDevelopment: Bool
    private let keyToRegister: String
    private let keyLogStrategy: KeyLogStrategy
    private let onAttackDetected: OnAttackDetected?

    public init(
        threshold: Int = 5,
        baseTimeFrame: TimeInterval = 60,
        skipInDevelopment: Bool = true,
        keyToRegister: String = "mail",
        keyLogStrategy: KeyLogStrategy = .redacted,
        onAttackDetected: OnAttackDetected? = nil
    ) {
        self.threshold = threshold
        self.baseTimeFrame = baseTimeFrame
        self.skipInDevelopment = skipInDevelopment
        self.keyToRegister = keyToRegister
        self.keyLogStrategy = keyLogStrategy
        self.onAttackDetected = onAttackDetected
    }

    public func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
        let userIP = fetchRawIP(request)
        let keyId = try request.content.get(String.self, at: keyToRegister)
        let currentTime = Date()

        if skipInDevelopment && request.application.environment == .development {
            return try await next.respond(to: request)
        }

        let lastAttempt = try await request.connexionAttempsSvc.incrementAndReturnAttempt(ip: userIP, keyId: keyId)
        let keyForLogs = keyLogStrategy.logValue(for: keyId)

        request.logger.warning("- \(currentTime) \(keyToRegister): \(keyForLogs); ip : \(userIP) try to login for \(lastAttempt.count) time(s)")

        guard lastAttempt.count >= threshold && isPenaltyActive(for: lastAttempt, baseTimeFrame: baseTimeFrame, threshold: threshold) else {
            return try await next.respond(to: request)
        }
        let penality = penaltyCalculator(lastAttempt.count, baseTimeFrame: baseTimeFrame, threshold: threshold)

        request.logger.warning("⚠️ \(keyToRegister): \(keyForLogs) locked for \(penaltyCalculator(penality)) seconds after \(lastAttempt.count) failed attempts")
        await notifyAttackDetected(
            onAttackDetected ?? request.application.vaporRateLimiter.onAttackDetected,
            request: request,
            context: AttackDetectedContext(
                kind: .login,
                ip: userIP,
                key: keyId,
                keyName: keyToRegister,
                keyForLogs: keyForLogs,
                count: lastAttempt.count,
                threshold: threshold,
                penalty: penality,
                baseTimeFrame: baseTimeFrame
            )
        )

        throw Abort(.tooManyRequests, reason: "Too many attempts. Try again after \(penaltyCalculator(penality)) seconds.")
    }

}
