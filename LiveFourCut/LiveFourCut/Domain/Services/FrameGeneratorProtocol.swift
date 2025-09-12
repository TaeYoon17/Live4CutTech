//
//  FrameService.swift
//  LiveFourCut
//
//  Created by Greem on 7/3/24.
//

import Foundation
import CoreImage

/// 기본 프레임 설정...
protocol FrameGeneratorProtocol: Sendable {
    var frameType: FrameType { get }
    var frameTargetSize: CGSize { get }
    func reduce(images: [CGImage]) throws -> CGImage
}
