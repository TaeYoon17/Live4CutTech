//
//  ExtractService.swift
//  LiveFourCut
//
//  Created by Greem on 7/3/24.
//

import Foundation
import AVFoundation
import CoreImage
enum ExtractError: Error{
    case emptyContainer
}
class ExtractService{
    var avAssetContainers: [AVAssetContainer] = []
    var minDuration: Double = 0.47
    var frameCounts:Int{ avAssetContainers.count }
    private let fileManager = FileManager.default

    private let fps:Double = 24
    func extractFrameImages() async throws -> [[URL]] {
        guard !avAssetContainers.isEmpty else { throw ExtractError.emptyContainer }
        var totalImageURLs:[[URL]] = []
        for (offset,v) in avAssetContainers.enumerated(){
            let asset = AVAsset(url: URL(string: v.originalAssetURL)!)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .init(seconds: Double(1 / (fps * 2)), preferredTimescale: 600)
            generator.requestedTimeToleranceAfter = .init(seconds: Double(1 / (fps * 2)), preferredTimescale: 600)
//            var imageDatas:[CGImage] = []
            var lastImage: CGImage!
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            let imgContain = try await generator.image(at: time)
//            imageDatas.append(imgContain.image)
            var imageURLs:[URL] = []
            lastImage = imgContain.image
            let lastURL = saveFrameImage(lastImage, at: offset, for: 0)!
            imageURLs.append(lastURL)
            for idx in (1..<Int(minDuration * fps)){
                let time = CMTime(seconds: Double(idx) / 24, preferredTimescale: 600)
                let imgContain = try? await generator.image(at: time)
                if let imgContain{
//                    imageDatas.append(imgContain.image)
                    lastImage = imgContain.image
                    let url = saveFrameImage(imgContain.image, at: offset, for: idx)!
                    imageURLs.append(url)
                }
                else{
                    let url = saveFrameImage(lastImage, at: offset, for: idx)!
                    imageURLs.append(url)
                }
            }
            
            totalImageURLs.append(imageURLs)
//            imageDatas = []
        }
//        print("totalImageDatas \(totalImageDatas.count)")
        return totalImageURLs
    }
    
    
    /// 프레임 이미지를 디스크에 저장하는 경로
    private func tempDirectory(for assetIndex: Int) -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ExtractedFrames/Asset\(assetIndex)")
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private func saveFrameImage(_ image: CGImage, at index: Int, for assetIndex: Int) -> URL? {
        let url = tempDirectory(for: assetIndex).appendingPathComponent("frame_\(index).png")
        let cicontext = CIContext()
        let ciimage:CIImage = CIImage(cgImage: image)
        try? cicontext.writePNGRepresentation(of: ciimage, to: url, format: .RGBA8, colorSpace: ciimage.colorSpace!)
        return url
    }
    
    func extractPararell() async throws -> [[CGImage]] {
        return try await withThrowingTaskGroup(of: (Int,[CGImage]).self) { taskGroup in
            for (offset,v) in avAssetContainers.enumerated(){
                taskGroup.addTask {[minDuration,fps] in
                    let asset = AVAsset(url: URL(string: v.originalAssetURL)!)
                    let generator = AVAssetImageGenerator(asset: asset)
                    generator.appliesPreferredTrackTransform = true
                    generator.requestedTimeToleranceBefore = .init(seconds: Double(1 / (fps * 2)), preferredTimescale: 600)
                    generator.requestedTimeToleranceAfter = .init(seconds: Double(1 / (fps * 2)), preferredTimescale: 600)
                    var imageDatas:[CGImage] = []
                    var lastImage: CGImage!
                    let time = CMTime(seconds: 0, preferredTimescale: 600)
                    let imgContain = try await generator.image(at: time)
                    imageDatas.append(imgContain.image)
                    lastImage = imgContain.image
                    for idx in (1..<Int(minDuration * fps)){
                        let time = CMTime(seconds: Double(idx) / 24, preferredTimescale: 600)
                        let imgContain = try? await generator.image(at: time)
                        if let imgContain{
                            imageDatas.append(imgContain.image)
                            lastImage = imgContain.image
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
    }
}
