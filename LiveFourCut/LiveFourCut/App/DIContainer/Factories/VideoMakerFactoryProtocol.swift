//
//  VideoMakerFactoryProtocol.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation
import Swinject

protocol VideoMakerFactoryProtocol {
    func makeVideoMaker(frameGenerator: FrameGeneratorProtocol) -> VideoMakerProtocol
}

struct DefaultVideoMakerFactory: VideoMakerFactoryProtocol {
    let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }
    
    func makeVideoMaker(frameGenerator: FrameGeneratorProtocol) -> VideoMakerProtocol {
        let memoryWarning = resolver.resolve(MemoryWarningProtocol.self)!
        return VideoMaker(
            memoryWarningService: memoryWarning,
            frameGenerator: frameGenerator
        )
    }
}
