//
//  ExtractService.swift
//  LiveFourCut
//
//  Created by Greem on 7/3/24.
//

import Foundation
import AVFoundation

protocol VideoFrameExtractorProtocol: AnyObject {
    func setUp(minDuration: Double, avAssetContainers: [AVAssetContainer]) async
    func extractFrameImages() async throws -> [[CGImage]]
}


