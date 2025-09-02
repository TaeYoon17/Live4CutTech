//
//  ExtractService.swift
//  LiveFourCut
//
//  Created by Greem on 7/3/24.
//

import Foundation
import AVFoundation
import CoreImage
import Accelerate

final class ExtractService {
    var avAssetContainers: [AVAssetContainer] = []
    var minDuration: Double = 0.47
    var frameCounts: Int { avAssetContainers.count }
    private let fps: Double = 24
    func extractFrameImages() async throws -> [[CGImage]] {
        guard !avAssetContainers.isEmpty else { throw ExtractError.emptyContainer }
        
        let imageDatas: [[CGImage]] = try await withThrowingTaskGroup(of: (Int,[CGImage]).self) { taskGroup in
            for (offset,v) in avAssetContainers.enumerated() {
                taskGroup.addTask {[self, minDuration,fps] in
                    let asset = AVAsset(url: URL(string: v.originalAssetURL)!)
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.requestedTimeToleranceBefore = .init(seconds: Double(1 / (fps * 2)), preferredTimescale: 600)
                    generator.requestedTimeToleranceAfter = .init(seconds: Double(1 / (fps * 2)), preferredTimescale: 600)
                    var imageDatas:[CGImage] = []
                    var lastImage: CGImage!
                    let time = CMTime(seconds: 0, preferredTimescale: 600)
                    let imgContain = try await generator.image(at: time)
                    let downImage = self.downsampleVImage(image: imgContain.image)
                    imageDatas.append(downImage)
                    lastImage = downImage
                    for idx in (1..<Int(minDuration * fps)){
                        let time = CMTime(seconds: Double(idx) / 24, preferredTimescale: 600)
                        let imgContain = try? await generator.image(at: time)
                        if let imgContain {
                            let downImage = self.downsampleVImage(image: imgContain.image)
                            imageDatas.append(downImage)
                            lastImage = downImage
                        }
                        else{ imageDatas.append(lastImage) }
                    }
                    return (offset,imageDatas)
                }
            }
            var imageContainers: [[CGImage]] = Array(repeating:[], count: frameCounts)
            for try await imageDatas in taskGroup{ imageContainers[imageDatas.0] = imageDatas.1 }
            return imageContainers
        }
        return imageDatas
    }
}
extension ExtractService {
    func downSample(image: CGImage) -> CGImage {
        
        let ciImage = CIImage(cgImage: image)
        let targetWidth : CGFloat = 360
        let scale = targetWidth / ciImage.extent.width
        let targetHeight = ciImage.extent.height * scale
        let scaleSize = CGSize(width: targetWidth, height: targetHeight)
        let transformedCIImage = ciImage.transformed(by: .init(scaleX: scale, y: scale), highQualityDownsample: true)
        let context = CIContext()
        let afterDownsamplingImage = context.createCGImage(transformedCIImage, from: .init(origin: .zero, size: scaleSize))!
        
        return afterDownsamplingImage
    }
}
extension ExtractService {
    func downsampleVImage(
        image: CGImage,
        targetSize: CGSize = .init(width: 480, height: 480 * 1.77)
    ) -> CGImage {
        guard let format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
            renderingIntent: .defaultIntent
        ) else {
            return image
        }
        
        do {
            var sourceBuffer = try vImage_Buffer(cgImage: image, format: format)
            var destinationBuffer = vImage_Buffer()
            
            defer {
                free(destinationBuffer.data)
                free(sourceBuffer.data)
            }
            
            // 이미지 크기 조절 알고리즘
            let scaleX = targetSize.width / CGFloat(image.width)
            let scaleY = targetSize.height / CGFloat(image.height)
            let scale = min(scaleX, scaleY)
            let destWidth = Int(CGFloat(image.width) * scale)
            let destHeight = Int(CGFloat(image.height) * scale)
            
            let bytesPerPixel = 4 // rgba를 대응하기 1바이트당 하나씩
            destinationBuffer.width = UInt(destWidth)
            destinationBuffer.height = UInt(destHeight)
            destinationBuffer.rowBytes = destWidth * bytesPerPixel // 한 열의 bytes
            destinationBuffer.data = malloc(destHeight * destinationBuffer.rowBytes) // 데이터 할당한다.
            
            // openCV에서 scaling을 해주는 것과 비슷한 메서드
            vImageScale_ARGB8888(&sourceBuffer, &destinationBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
            
            let destCGImage = try destinationBuffer.createCGImage(format: format)
            print("Prev Downsampling image data size ", image.width * image.height * 4 / 1024)
            print("Prev image size: \(image.width)X\(image.height)")
            print("----------------------------------------------------------")
            print("After Downsampling image data size ", destCGImage.width * destCGImage.height * 4 / 1024)
            print("After image size: \(destCGImage.width)X\(destCGImage.height)")
            return destCGImage
        } catch {
            return image
        }
    }
}
