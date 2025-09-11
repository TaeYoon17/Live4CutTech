//
//  PHAssetExtensions.swift
//  LiveFourCut
//
//  Created by Greem on 6/19/24.
//

import Foundation
import Photos
import UIKit

extension UIImage {
    @MainActor func coreDownSample(size: CGSize? = nil) -> UIImage {
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let pngData = self.pngData() else {
            return .init()
        }
        let data = pngData as CFData
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
