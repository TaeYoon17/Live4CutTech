//
//  ThumbnailExecutor.swift
//  LiveFourCut
//
//  Created by Developer on 6/19/24.
//

import Foundation
import Combine
import Photos
import UIKit


protocol ThumbnailExecutorProtocol {
    var itemsSubject: PassthroughSubject<[ImageContainer], Never> { get }
    var progressSubject: PassthroughSubject<Float, Never>  { get }
    func setFetchResult(result: PHFetchResult<PHAsset>) async
    func run() async
}

final class ThumbnailExecutor: ThumbnailExecutorProtocol {
    let itemsSubject: PassthroughSubject<[ImageContainer], Never> = .init()
    let progressSubject: PassthroughSubject<Float, Never> = .init()
    
    private var result: PHFetchResult<PHAsset>!
    private let imageManager: PHCachingImageManager = .init()
    
    private var counter: Int = -1 {
        didSet {
            guard counter == 0 else { return }
            itemsSubject.send(fetchItems)
            fetchItems.removeAll()
            fetchAssets.removeAll()
        }
    }
    
    private var fetchItems: [ImageContainer] = []
    
    private var fetchAssets: [PHAsset] = [] {
        didSet {
            guard counter == fetchAssets.count else { return }
            Task {
                let resultCount = self.fetchAssets.count
                for asset in fetchAssets {
                    fetchImage(
                        phAsset: asset,
                        size: .init(width: 3 * 120, height: 3 * 120 * 1.77),
                        contentMode: .aspectFill) { image in
                        let count = self.fetchItems.count
                            self.fetchItems.append(
                                ImageContainer(
                                    id: asset.localIdentifier,
                                    image: image,
                                    idx: count
                                )
                            )
                        self.counter -= 1
                        self.progressSubject.send(min(1,(Float(resultCount - self.counter) / Float(resultCount))))
                    }
                }
            }
        }
    }
    
    func setFetchResult(result: PHFetchResult<PHAsset>) async {
        self.result = result
    }
    
    func run() async {
        counter = result.count
        fetchItems.removeAll()
        self.progressSubject.send(0)
    
        result.enumerateObjects(options: .concurrent) {  asset, _, _ in
            self.fetchAssets.append(asset)
        }
    }
    
    private func fetchImage(
        phAsset: PHAsset,
        size: CGSize,
        contentMode: PHImageContentMode,
        completion: @escaping (UIImage) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true // iCloud의 이미지도 가져올 수 있음
        options.deliveryMode = .highQualityFormat
        imageManager.requestImage(
            for: phAsset,
            targetSize: size,
            contentMode: contentMode,
            options: options,
            resultHandler: { image, _ in
                guard let image else { return }
                completion(image)
            }
        )
    }
}

