//
//  FrameType.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import Foundation

enum FrameType {
    case basic2x2
    
    var frameCount: Int {
        switch self {
        case .basic2x2: return 4
        }
    }
}
