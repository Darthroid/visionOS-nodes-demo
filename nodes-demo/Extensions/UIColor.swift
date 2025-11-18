//
//  UIColor.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 17.11.2025.
//

import UIKit

// Extension for random colors
extension UIColor {
    static func randomPastel() -> UIColor {
        let colors: [UIColor] = [
            .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemTeal, .systemPink
        ]
        return colors.randomElement() ?? .systemBlue
    }
}
