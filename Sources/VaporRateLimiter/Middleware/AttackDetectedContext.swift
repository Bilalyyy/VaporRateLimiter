//
//  AttackDetectedContext.swift
//  VaporRateLimiter
//
//  Created by Codex on 04/07/2026.
//

import Vapor

public struct AttackDetectedContext: Sendable {
    public enum Kind: String, Sendable {
        case login
        case signUp
    }

    public let kind: Kind
    public let ip: String
    public let key: String
    public let keyName: String
    public let keyForLogs: String
    public let count: Int
    public let threshold: Int
    public let penalty: TimeInterval
    public let baseTimeFrame: TimeInterval

    public init(
        kind: Kind,
        ip: String,
        key: String,
        keyName: String,
        keyForLogs: String? = nil,
        count: Int,
        threshold: Int,
        penalty: TimeInterval,
        baseTimeFrame: TimeInterval
    ) {
        self.kind = kind
        self.ip = ip
        self.key = key
        self.keyName = keyName
        self.keyForLogs = keyForLogs ?? KeyLogStrategy.redacted.logValue(for: key)
        self.count = count
        self.threshold = threshold
        self.penalty = penalty
        self.baseTimeFrame = baseTimeFrame
    }
}

public typealias OnAttackDetected = @Sendable (_ request: Request, _ context: AttackDetectedContext) async throws -> Void

func notifyAttackDetected(
    _ onAttackDetected: OnAttackDetected?,
    request: Request,
    context: AttackDetectedContext
) async {
    guard let onAttackDetected else {
        return
    }

    do {
        try await onAttackDetected(request, context)
    } catch {
        request.logger.error("onAttackDetected failed: \(error.localizedDescription)")
    }
}
