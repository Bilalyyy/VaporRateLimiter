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
    private let skipInDevelopment: Bool
    private let keyToRegister: String
    private let keyLogStrategy: KeyLogStrategy
    private let onAttackDetected: OnAttackDetected?

    public init(
        threshold: Int = 2,
        baseTimeFrame: TimeInterval = 240,
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
        let userIP = fetchIPBucket(request)
        let keyValue = try request.content.get(String.self, at: keyToRegister)
        let currentTime = Date()
    
        if skipInDevelopment && request.application.environment == .development {
            return try await next.respond(to: request)
        }

        let count = try await request.signUpAttempsSvc.incrementAndReturnCount(ip: userIP, mail: keyValue)
        let keyForLogs = keyLogStrategy.logValue(for: keyValue)

        request.logger.warning("- \(currentTime) \(keyToRegister): \(keyForLogs); ip : \(userIP) try to sign up for \(count) time(s)")

        guard let lastAttempt = try await request.signUpAttempsSvc.findBy(ip: userIP) else {
            throw Abort(.notFound, reason: "no attempt found")
        }

        guard lastAttempt.count >= threshold && isPenaltyActive(for: lastAttempt.toDto(), baseTimeFrame: baseTimeFrame, threshold: threshold) else {
            return try await next.respond(to: request)
        }

        let penality = penaltyCalculator(lastAttempt.count, baseTimeFrame: baseTimeFrame, threshold: threshold)

        request.logger.warning("⚠️ \(keyToRegister): \(keyForLogs) - ip: \(userIP) locked for \(penaltyCalculator(penality)) seconds after \(count) sign up attempts")
        await notifyAttackDetected(
            onAttackDetected ?? request.application.vaporRateLimiter.onAttackDetected,
            request: request,
            context: AttackDetectedContext(
                kind: .signUp,
                ip: userIP,
                key: keyValue,
                keyName: self.keyToRegister,
                keyForLogs: keyForLogs,
                count: lastAttempt.count,
                threshold: threshold,
                penalty: penality,
                baseTimeFrame: baseTimeFrame
            )
        )

        throw Abort(.tooManyRequests, reason: "Too many sign up. Try again after \(penaltyCalculator(penality)) seconds.")
    }

}

func penaltyCalculator(_ nbrAttempts: Int, baseTimeFrame: TimeInterval = 60, threshold: Int) -> TimeInterval {
    guard nbrAttempts >= threshold else {
        return 0
    }
    // Hard cap: 5 years in seconds (approx 365 days/year)
    let maxPenalty: TimeInterval = 5 * 365 * 24 * 3600

    let palier = (nbrAttempts - threshold) / threshold
    let exponent = max(0, palier + 1)

    let penality = baseTimeFrame * pow(2.0, Double(exponent - 1))

    if penality <= maxPenalty {
        return penality
    }

    let jittered = maxPenalty * Double.random(in: 1.0...1.7)
    return jittered
}

func penaltyCalculator(_ penality: TimeInterval) -> String {
    let maxPenalty: TimeInterval = 5 * 365 * 24 * 3600 // 5 years in seconds

    if penality <= maxPenalty {
        return String(penality)
    } else {
        return "more than \(maxPenalty)"
    }
}

func isPenaltyActive(for lastAttempt: AttemptDto, baseTimeFrame: TimeInterval, now: Date = Date(), threshold: Int) -> Bool {
    let penalty = penaltyCalculator(lastAttempt.count, baseTimeFrame: baseTimeFrame, threshold: threshold)
    // 'true' if the penalty is still active (waiting period not elapsed)
    return lastAttempt.count >= threshold && now.timeIntervalSince(lastAttempt.timestamp) < penalty
}
