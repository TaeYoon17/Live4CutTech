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
actor ThumbnailExecutor{ // Actor는 상속이 가능하다
    let thumbnailsSubject: PassthroughSubject<[ImageContainer],Never> = .init()
    let progressSubject:PassthroughSubject<Float,Never> = .init()
    private var result: PHFetchResult<PHAsset>!
    private let imageManager: PHCachingImageManager = .init()
    private var counter: Int = -1{
        didSet{
            guard counter == 0 else {return}
            thumbnailsSubject.send(fetchItems)
            fetchItems.removeAll()
            fetchAssets.removeAll()
        }
    }
    private var fetchItems:[ImageContainer] = []
    private var fetchAssets:[PHAsset] = []{
        didSet{
            guard counter == fetchAssets.count else { return }
            Task {
                let resultCount = self.fetchAssets.count
                for asset in fetchAssets {
                    fetchImage(phAsset: asset,
                               size: .init(width: 3 * 120, height: 3 * 120 * 1.77),
                               contentMode: .aspectFill) { image in
                        let count = self.fetchItems.count
                        self.fetchItems.append(ImageContainer(id: asset.localIdentifier, image: image, idx: count))
                        self.counter -= 1
                        self.progressSubject.send(min(1,(Float(resultCount - self.counter) / Float(resultCount))))
                    }
                }
            }
        }
    }
    
    func setFetchResult(result: PHFetchResult<PHAsset>) async{
        self.result = result
    }
    func run() async{
        counter = result.count
        fetchItems.removeAll()
        let resultCount = result.count
        self.progressSubject.send(0)
    
        result.enumerateObjects(options: .concurrent) {  asset, _, _ in
            self.fetchAssets.append(asset)
//            Task{
//                do{
//                
////                    let image = try await asset.convertToUIImage(size: .init(width: 120, height: 120 * 1.3333))
////                    let count = self.fetchItems.count
////                    self.fetchItems.append(ImageContainer(id: asset.localIdentifier, image: image, idx: count))
////                    self.counter -= 1
////                    self.progressSubject.send(min(1,(Float(resultCount - self.counter) / Float(resultCount))))
//                }catch{
//                    fatalError("무슨 문제야")
//                }
//            }
        }
    }
    private func fetchImage(
        phAsset: PHAsset,
        size: CGSize,
        contentMode: PHImageContentMode,
        completion: @escaping (UIImage) -> Void
    ) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true // iCloud
        options.deliveryMode = .highQualityFormat
        
        imageManager.requestImage(for: phAsset,targetSize: size,contentMode: contentMode, options: options,
            resultHandler: { image, _ in
                guard let image else { return }
                completion(image)
            }
        )
    }
}


