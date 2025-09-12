//
//  PhotoSelectionViewModel.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import Foundation
import UIKit
import Combine
import PhotosUI

@MainActor
final class PhotoSelectionViewModel: @preconcurrency ThumbnailSelectorProtocol {
    // MARK: - Published Properties
    @Published private(set) var pickedImageFetchProgress: Float = 0 // 이미지 피커에서 이미지만 가져올 때 로딩
    @Published private(set) var videoLoadingProgress: Float = 0 // 동영상 위치에서 실제 영상 데이터를 가져올 때 로딩

    // MARK: - Subjects
    let selectImageContainerSubject: CurrentValueSubject<[ImageContainer?],Never>
    var selectedImageIndexes: AnyPublisher<[Bool], Never> {
        let frameCount = frameType.frameCount
        return selectImageContainerSubject.map { containerList in
            return (0..<frameCount).map {
                containerList.map(\.?.idx).contains($0)
            }
        }.eraseToAnyPublisher()
    }
    
    // 유저가 출력할 이미지들의 순서 선택을 완료했는지
    var isPrintSelectionCompleted: AnyPublisher<Bool, Never> {
        selectImageContainerSubject.map{ !$0.contains(where: {$0 == nil} ) }.eraseToAnyPublisher()
    }
    let pickedImageContainerSubject: CurrentValueSubject<[ImageContainer], Never>
    let pickerEventSubject = PassthroughSubject<PhotoPickerEvent, Never>()
    let videoAssetContinersSubject = PassthroughSubject<([AVAssetContainer], Float), Never>()
    
     // MARK: - Properties
    let frameType: FrameType
    
    @Dependency private var thumbnailExecutor: ThumbnailExecutorProtocol
    @Dependency private var videoExecutor: VideoExecutorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(frameType: FrameType) {
        self.frameType = frameType
        selectImageContainerSubject = .init((0..<frameType.frameCount).map { _ in nil })
        pickedImageContainerSubject = .init([])
        bindExecutors()
    }
    
    // MARK: - Public Methods
    func openPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .livePhotos
        config.selectionLimit = frameType.frameCount
        config.selection = .ordered
        
        let containerList = selectImageContainerSubject.value
        config.preselectedAssetIdentifiers = containerList.compactMap { $0?.id }
        self.pickerEventSubject.send(.openPhotoPicker(config))
    }
    
    func handlePickerResults(results: [PHPickerResult]) {
        let identifiers = results.map(\.assetIdentifier).compactMap { $0 }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        let action = determinePickerAction(for: identifiers, assets: assets)
        self.pickerEventSubject.send(action)
        if case .processImages = action {
            self.thumbnailExecutor.setFetchResult(result: assets)
            self.thumbnailExecutor.run()
            Task { [weak videoExecutor] in
                guard let videoExecutor else {
                    return
                }
                await videoExecutor.setFetchResult(result: assets)
            }
        }
    }
    
    func executeVideoFetch() {
        Task { [weak videoExecutor] in
            guard let videoExecutor else {
                return
            }
            await videoExecutor.run()
        }
    }
}


fileprivate extension PhotoSelectionViewModel {
    private func bindExecutors() {
        thumbnailExecutor.itemsSubject.sink { [weak self] contianer in
            guard let self else { return }
            pickedImageContainerSubject.send(contianer)
        }
        .store(in: &cancellables)
        
        thumbnailExecutor.progressSubject.sink { [weak self] progress in
            guard let self else { return }
            self.pickedImageFetchProgress = progress
        }.store(in: &cancellables)
        
        Task { [weak videoExecutor] in
            guard let videoExecutor else { return }
            for try await executor in await videoExecutor.executeStream {
                switch executor {
                case .finished(let dto):
                    let images = self.selectImageContainerSubject.value.compactMap { $0 }
                    var result: [AVAssetContainer] = []
                    let videos = dto.items
                    for image in images {
                    if let video = videos.first(where: { $0.id == image.id }) {
                            result.append(video)
                        }
                    }
                    videoAssetContinersSubject.send((result, dto.minDuration))
                case .running(let progress):
                    self.pickedImageFetchProgress = progress
                }
            }
        }
        
    }
    
    private func determinePickerAction(for identifiers: [String], assets: PHFetchResult<PHAsset>) -> PhotoPickerEvent {
        let containerList = selectImageContainerSubject.value
        if Set(identifiers) == Set(containerList.compactMap({ $0 }).map(\.id)) && identifiers.count == frameType.frameCount {
            return .dismissOnly
        }
        
        if assets.count == 0 && PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized {
            return .popViewController
        } else if assets.count == frameType.frameCount {
            return .processImages
        } else {
            return .showDenyPage
        }
    }
    
}
