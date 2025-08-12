//
//  LoginRateLimiter 2.swift
//  VaporRateLimiter
//
//  Created by Bilal Larose on 12/08/2025.
//



import Vapor
import Fluent

public final class SignUpRateLimiter: AsyncMiddleware {
    private let threshold: Int
    private let baseTimeFrame: TimeInterval
    private let keyToRegister: String

    public init(threshold: Int = 2, baseTimeFrame: TimeInterval = 240, keyToRegister: String = "mail") {
        self.threshold = threshold
        self.baseTimeFrame = baseTimeFrame
        self.keyToRegister = keyToRegister
    }

    public func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
        let userIP = fetchIPBucket(request)
        let keyId = try request.content.get(String.self, at: keyToRegister)
        let currentTime = Date()

        guard request.application.environment != .development else {
            return try await next.respond(to: request)
        }

        // TODO: update incrementAndReturnCount() to incrementAndReturnConnexionAttemptDto()
        let count = try await request.connexionAttempsSvc.incrementAndReturnCount(ip: userIP, keyId: keyId)

        request.logger.warning("- \(currentTime) user: \(keyId); ip : \(userIP) try to sign in for \(count) time(s)")

        guard let lastAttempt = try await request.connexionAttempsSvc.findBy(ip: userIP,
                                                                             or: keyId) else {
            throw Abort(.notFound, reason: "no attempt found")
        }

        guard lastAttempt.count >= threshold && isPenaltyActive(for: lastAttempt.toDto(), baseTimeFrame: 60, threshold: threshold) else {
            return try await next.respond(to: request)
        }

        request.logger.warning("⚠️ user: \(keyId) - ip: \(userIP) locked for \(penaltyCalculator(lastAttempt.count, threshold: threshold)) seconds after \(count) sign in attempts")

        throw Abort(.tooManyRequests, reason: "Too many sign in. Try again after \(penaltyCalculator(count, threshold: threshold)) seconds.")
    }

}

func penaltyCalculator(_ nbrAttempts: Int, baseTimeFrame: TimeInterval = 60, threshold: Int) -> TimeInterval {
    guard nbrAttempts >= threshold else {
        return 0
    }

    let palier = (nbrAttempts - threshold) / threshold
    let exponent = max(0, palier + 1)

    let penality = baseTimeFrame * pow(2.0, Double(exponent - 1))

    return penality
}

func isPenaltyActive(for lastAttempt: ConnexionAttemptDto, baseTimeFrame: TimeInterval, now: Date = Date(), threshold: Int) -> Bool {
    let penalty = penaltyCalculator(lastAttempt.count, baseTimeFrame: baseTimeFrame, threshold: threshold)
    // 'true' if the penalty is still active (waiting period not elapsed)
    return lastAttempt.count >= threshold && now.timeIntervalSince(lastAttempt.timestamp) < penalty
}
