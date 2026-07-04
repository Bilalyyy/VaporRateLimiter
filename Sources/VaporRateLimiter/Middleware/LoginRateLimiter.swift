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
    private let keyToRegister: String
    private let onAttackDetected: OnAttackDetected?

    public init(
        threshold: Int = 5,
        baseTimeFrame: TimeInterval = 60,
        keyToRegister: String = "mail",
        onAttackDetected: OnAttackDetected? = nil
    ) {
        self.threshold = threshold
        self.baseTimeFrame = baseTimeFrame
        self.keyToRegister = keyToRegister
        self.onAttackDetected = onAttackDetected
    }

    public func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
        let userIP = fetchRawIP(request)
        let keyId = try request.content.get(String.self, at: keyToRegister)
        let currentTime = Date()

        guard request.application.environment == .development else {
            return try await next.respond(to: request)
        }

        // TODO: update incrementAndReturnCount() to incrementAndReturnConnexionAttemptDto()
        let count = try await request.connexionAttempsSvc.incrementAndReturnCount(ip: userIP, keyId: keyId)

        request.logger.warning("- \(currentTime) user: \(keyId); ip : \(userIP) try to login for \(count) time(s)")

        guard let lastAttempt = try await request.connexionAttempsSvc.findBy(ip: userIP,
                                                                             or: keyId) else {
            throw Abort(.notFound, reason: "no attempt found")
        }

        guard lastAttempt.count >= threshold && isPenaltyActive(for: lastAttempt.toDto(), baseTimeFrame: baseTimeFrame, threshold: threshold) else {
            return try await next.respond(to: request)
        }
        let penality = penaltyCalculator(lastAttempt.count, baseTimeFrame: baseTimeFrame, threshold: threshold)

        request.logger.warning("⚠️ user: \(keyId) locked for \(penaltyCalculator(penality)) seconds after \(count) failed attempts")
        await notifyAttackDetected(
            onAttackDetected ?? request.application.vaporRateLimiter.onAttackDetected,
            request: request,
            context: AttackDetectedContext(
                kind: .login,
                ip: userIP,
                key: keyId,
                keyName: keyToRegister,
                count: lastAttempt.count,
                threshold: threshold,
                penalty: penality,
                baseTimeFrame: baseTimeFrame
            )
        )

        throw Abort(.tooManyRequests, reason: "Too many attempts. Try again after \(penaltyCalculator(penality)) seconds.")
    }

}
