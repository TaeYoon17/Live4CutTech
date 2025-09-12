//
//  VideoMakerError.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation

enum VideoMakerError: Error {
    case faileToCreatePixelBuffer
    case memoryPeak
    case emptyImage
    case noneMatchFrameMode
}
