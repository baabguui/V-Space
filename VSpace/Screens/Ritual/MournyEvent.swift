//
//  MournyEvent.swift
//  VSpace
//

import UIKit

struct MournyEvent {

    enum Direction {
        case front
        case back
        case horizontal(fromLeft: Bool)
    }

    let name: String
    let arriveName: String
    let direction: Direction

    static func random() -> MournyEvent {
        let pool: [(String, Direction)] = [
            ("frontMournyA",      .front),
            ("frontMournyB",      .front),
            ("frontMournyC",      .front),
            ("backMournyA",       .back),
            ("backMournyB",       .back),
            ("backMournyC",       .back),
            ("horizontalMournyA", .horizontal(fromLeft: Bool.random())),
            ("horizontalMournyB", .horizontal(fromLeft: Bool.random())),
        ]
        let (name, direction) = pool.randomElement()!
        return MournyEvent(name: name, arriveName: name + "-arrive", direction: direction)
    }
}

struct MournySpawn {
    let event: MournyEvent
    let scale: CGFloat
}
