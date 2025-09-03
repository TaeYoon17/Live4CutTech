//
//  VideoFetchEvent.swift
//  LiveFourCut
//
//  Created by Greem on 9/3/25.
//

import Foundation

enum VideoFetchEvent {
    case progress(Float)
    case completed(([AVAssetContainer], Float))
}
