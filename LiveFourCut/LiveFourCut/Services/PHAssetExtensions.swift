//
//  PHAssetExtensions.swift
//  LiveFourCut
//
//  Created by Greem on 6/19/24.
//

import Foundation
import Photos
import UIKit
extension PHAsset{
    
    func convertToUIImage(size:CGSize? = nil) async throws -> UIImage {
        // reqeustContentEditingInput 코드를 비동기로 변환
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else { return }
            requestContentEditingInput(with: nil) { input, info in
                // PHContentEditingInput 타입에서 이미지 URL을 가져옴
                guard let input, let imageURL = input.fullSizeImageURL else {return}
                let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
                // CGImageResource로 이미지를 가져옴
                let imageSource: CGImageSource = CGImageSourceCreateWithURL(
                    imageURL as CFURL,
                    imageSourceOption
                )!
                let image:UIImage = self.coreDownSample(resource: imageSource, size: size)
                continuation.resume(returning: image)
            }
        }
    }
    
    private func coreDownSample(resource:CGImageSource,size:CGSize? = nil) -> UIImage{
        
        let scale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds
        let maxPixel = if let size{
             max(size.width, size.height) * scale
        }else{
            max(screenSize.width,screenSize.height) * scale
        }
        let downSampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        return if let downSampledImage = CGImageSourceCreateThumbnailAtIndex(resource, 0, downSampleOptions) {
            UIImage(cgImage: downSampledImage)
        }else{
            UIImage(resource: .hanroro1)
        }
    }
}
extension UIImage{
    private func coreDownSample(size:CGSize? = nil) -> UIImage{
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        let data = self.pngData() as! CFData
        let imageSource: CGImageSource = CGImageSourceCreateWithData(data, imageSourceOption)!
        
        let scale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds
        let maxPixel = if let size {
             max(size.width, size.height) * scale
        } else {
            max(screenSize.width,screenSize.height) * scale
        }
        let downSampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        return if let downSampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downSampleOptions){
            UIImage(cgImage: downSampledImage)
        }else{
            UIImage(resource: .hanroro1)
        }
    }
}
