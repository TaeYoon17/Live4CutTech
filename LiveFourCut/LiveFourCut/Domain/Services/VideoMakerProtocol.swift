//
//  VideoMakerProtocol.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation
import CoreGraphics

protocol VideoMakerProtocol: Sendable {
    func transpose(_ matrix: inout [[CGImage]])
    
    /// [[frameType 별 이미지 배열]] -> Frame 계수
    /// outputURL: 담겨질 URL 값
    /// return => Progress Type 종료시 .finish()
    func run(groupImage: inout [[CGImage]], outputURL: URL) throws -> AsyncThrowingStream<Double, Error>
}

extension VideoMakerProtocol {
    func transpose(_ matrix: inout [[CGImage]]) {
        let rows = matrix.count
        let cols = matrix[0].count
        
        // 새로운 배열을 미리 할당하되, 필요한 크기만큼만
        var transposed: [[CGImage]] = []
        transposed.reserveCapacity(cols)
        
        for j in 0..<cols {
            var newRow: [CGImage] = []
            newRow.reserveCapacity(rows)
            
            for i in 0..<rows {
                newRow.append(matrix[i][j])
            }
            transposed.append(newRow)
        }
        
        matrix = transposed
    }
}
