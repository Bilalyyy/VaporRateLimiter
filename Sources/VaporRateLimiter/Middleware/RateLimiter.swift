//
//  RateLimitMiddleware.swift
//  RateLimitMiddleware
//
//  Created by Bilal Larose on 17/07/2025.
//

import Vapor
import Fluent

public final class RateLimiter: AsyncMiddleware {
    private let threshold = 5

    public init() { }

    public func respond(to request: Vapor.Request, chainingTo next: any Vapor.AsyncResponder) async throws -> Vapor.Response {
        let userIP = fetchIPAdresse(request)
        let userMail = try request.content.get(String.self, at: "mail")
        let currentTime = Date()

        guard request.application.environment != .development else {
            return try await next.respond(to: request)
        }

        // TODO: update incrementAndReturnCount() to incrementAndReturnConnexionAttemptDto()
        let count = try await request.connexionAttempsSvc.incrementAndReturnCount(ip: userIP, mail: userMail)

        request.logger.warning("- \(currentTime) user: \(userMail); ip : \(userIP) try to login for \(count) time(s)")

        guard let lastAttempt = try await request.connexionAttempsSvc.findBy(ip: userIP,
                                                                             or: userMail) else {
            throw Abort(.notFound, reason: "no attempt found")
        }

        guard lastAttempt.count >= threshold && isPenaltyActive(for: lastAttempt.toDto()) else {
            return try await next.respond(to: request)
        }

        request.logger.warning("⚠️ user: \(userMail) locked for \(penaltyCalculator(lastAttempt.count)) seconds after \(count) failed attempts")

        throw Abort(.tooManyRequests, reason: "Too many attempts. Try again after \(penaltyCalculator(count)) seconds.")
    }


    func penaltyCalculator(_ nbrAttempts: Int, baseTimeFrame: TimeInterval = 60) -> TimeInterval {
        guard nbrAttempts >= 5 else {
            return 0
        }

        let threshold = 5
        let palier = (nbrAttempts - threshold) / threshold
        let exponent = max(0, palier + 1)

        let penality = baseTimeFrame * pow(2.0, Double(exponent - 1))

        return penality
    }

    func isPenaltyActive(for lastAttempt: ConnexionAttemptDto, now: Date = Date()) -> Bool {
        let penalty = penaltyCalculator(lastAttempt.count)
        // 'true' if the penalty is still active (waiting period not elapsed)
        return lastAttempt.count >= threshold && now.timeIntervalSince(lastAttempt.timestamp) < penalty
    }

}

func fetchIPAdresse(_ req: Request) -> String {
    if let forwardedFor = req.headers["X-Forwarded-For"].first {
        return forwardedFor.split(separator: ",").first?.trimmingCharacters(in: .whitespaces) ?? "unknown"
    }
    return req.remoteAddress?.ipAddress ?? "unknown"
}
