//
//  FrameType.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import Foundation

enum FrameType {
    case basic2x2
    
    var name: String {
        switch self {
        case .basic2x2: return "basic2x2"
        }
    }
    
    var mergeRatio: CGFloat {
        switch self {
        case .basic2x2: return 1.77
        }
    }
    
    var frameCount: Int {
        switch self {
        case .basic2x2: return 4
        }
    }
}
