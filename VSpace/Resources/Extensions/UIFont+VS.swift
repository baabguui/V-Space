//
//  UIFont+VS.swift
//  VSpace
//

import UIKit

extension UIFont {
    static func pretendard(_ weight: Weight, size: CGFloat) -> UIFont {
        let name: String
        switch weight {
        case .semibold: name = "Pretendard-SemiBold"
        default:        name = "Pretendard-Regular"
        }
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    static let vsTitle   = pretendard(.semibold, size: 20)  // Title   23 / SemiBold
    static let vsInput   = pretendard(.regular,  size: 18)  // Input   20 / Regular
    static let vsBody    = pretendard(.semibold, size: 16)  // Body    17 / SemiBold
    static let vsCaption = pretendard(.semibold, size: 14)  // Caption 16 / SemiBold
    static let vsSmall   = pretendard(.regular,  size: 12)  // Small   12 / Regular
}
