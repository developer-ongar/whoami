//
//  File.swift
//

import Foundation

public extension DiscordClient {
    static let noop: Self = .init(
        isActive: false,
        isConnected: false,
        status: { .never },
        setActive: { _ in },
        setActivity: { _ in }
    )
}
