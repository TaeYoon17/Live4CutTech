//
//  DIContainer.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import Foundation
import Swinject

@MainActor
extension Container {
    public static let shared: Container = {
        let container = Container()
        coreRegister(container: container)
        serviceRegister(container: container)
        domainRegister(container: container)
        featureRegister(container: container)
        return container
    }()
    
    private static func coreRegister(container: Container) {
        container.register(MemoryWarningProtocol.self) { container in
            MemoryWarningActor()
        }.inObjectScope(.container)
    }
    
    private static func serviceRegister(container: Container) {
        container.register(VideoFrameExtractorProtocol.self) {
            _ in VideoFrameExtractor()
        }.inObjectScope(.transient)
        container.register(VideoExecutorProtocol.self) { resolver in
            VideoExecutor()
        }.inObjectScope(.transient)
        
        container.register(ThumbnailExecutorProtocol.self) { resolver in
            ThumbnailExecutor()
        }.inObjectScope(.transient)
        
        container.register(PhotoAuthorizationRepository.self) { resolver in
            DefaultPhotoAuthorizationRepository()
        }.inObjectScope(.container)
        
        container.register(VideoMakerFactoryProtocol.self) { resolver in
            DefaultVideoMakerFactory(resolver: resolver)
        }
    }
    
    private static func domainRegister(container: Container) {
        container.register(RequestPhotoAuthUseCase.self) { resolver in
            DefaultRequestPhotoAuthUseCase(
                photoAuthrepository: resolver.resolve(PhotoAuthorizationRepository.self)!
            )
        }.inObjectScope(.transient)
        
        container.register(CheckPhotoAuthUseCase.self) { resolver in
            DefaultCheckPhotoAuthUseCase(
                photoAuthrepository: resolver.resolve(PhotoAuthorizationRepository.self)!
            )
        }.inObjectScope(.transient)
    }
    
    private static func featureRegister(container: Container) {
        
    }
}
extension Container {
    private static func frameGenerateorRegister(container: Container) {
        container.register(FrameGeneratorProtocol.self, name: FrameType.basic2x2.name) { resolver in
            Frame2x2Generator(width: 480, spacing: 4)
        }
    }
}


