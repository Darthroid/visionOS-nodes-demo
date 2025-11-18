//
//  Untitled.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

extension SIMD3 where Scalar == Float {
    /// The variable to lock the y-axis value to 0.
    var grounded: SIMD3<Scalar> {
        return .init(x: x, y: 0, z: z)
    }
}
