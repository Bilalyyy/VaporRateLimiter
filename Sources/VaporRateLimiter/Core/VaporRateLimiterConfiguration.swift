//
//  VaporRateLimiterConfiguration.swift
//  VaporRateLimiter
//
//  Created by Codex on 04/07/2026.
//

import Vapor

public struct VaporRateLimiterConfiguration {
    public var onAttackDetected: OnAttackDetected?

    public init(onAttackDetected: OnAttackDetected? = nil) {
        self.onAttackDetected = onAttackDetected
    }
}

extension Application {
    private struct VaporRateLimiterConfigurationKey: StorageKey {
        typealias Value = VaporRateLimiterConfiguration
    }

    public var vaporRateLimiter: VaporRateLimiterConfiguration {
        get {
            storage[VaporRateLimiterConfigurationKey.self] ?? .init()
        }
        set {
            storage[VaporRateLimiterConfigurationKey.self] = newValue
        }
    }
}
