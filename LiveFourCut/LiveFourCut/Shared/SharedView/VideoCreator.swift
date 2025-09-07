//
//  VideoCreator.swift
//  LiveFourCut
//
//  Created by Greem on 6/21/24.
//

import Foundation
import UIKit
import AVFoundation

class VideoCreator {
    let fps:Int32 = 24
    var videoSize: CGSize
    var outputURL:URL
    
    init(videoSize: CGSize,outputURL: URL) {
        self.videoSize = videoSize
        self.outputURL = outputURL
    }
    
    private static func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as Any,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(
            image.cgImage!,
            in: CGRect(origin: .zero, size: size)
        )
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }
    private static func pixelBuffer(_ image: CGImage, size: CGSize) -> CVPixelBuffer? {
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as Any,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return pixelBuffer
    }

    private static func pixelBuffer(data: CFData, size: CGSize, bytesPerRow: Int) -> CVPixelBuffer? {
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as Any,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any
        ]
        let cfImgData = data as CFData
        let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, cfImgData)
        let x = CFDataGetMutableBytePtr(dataFromImageDataProvider)!
        var pixelBuffer: CVPixelBuffer?
        //bytes per raw를 알아야한다.
        _ = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, x, bytesPerRow , nil, nil, options as CFDictionary, &pixelBuffer)
        
        return pixelBuffer
    }
}
extension VideoCreator {
    func createVideo(from images: inout [CGImage]) async throws {
        guard let imageLast = images.last else {
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let videoSize = CGSize(width: imageLast.width, height: imageLast.height)
        self.videoSize = videoSize
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height
        ]
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        try await withCheckedThrowingContinuation { [weak self, fps] continuation in
            guard let self else { return }
            do {
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                var frameCount: Int64 = 0
                images.reverse()
                while images.isEmpty == false {
                    let image = images.removeLast()
                    try autoreleasepool { // CVPixelBuffer가 쌓이지 않도록
                        while !writerInput.isReadyForMoreMediaData { }
                        var pixelBuffer: CVPixelBuffer?
                        image.getCVPixelBuffer(pixelBuffer: &pixelBuffer)
                        guard var pixelBuffer else {
                            throw NSError(
                                domain: "com.example.VideoCreator",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"]
                            )
                        }
                        let frameTime = CMTimeMake(value: frameCount, timescale: fps)
                        CVPixelBufferLockBaseAddress(pixelBuffer, [])
                        image.drawCVPixelBuffer(&pixelBuffer)
                        adaptor.append(pixelBuffer, withPresentationTime: frameTime)
                        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                        frameCount += 1
                    }
                }
                
                writerInput.markAsFinished() // 샘플 추가가 완료되었음을 나타내기 위해 입력을 완료로 표시합니다.
                writer.finishWriting { // AVAssetWriter가 쓰기를 완료함
                    continuation.resume()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    func createVideo(
        from images: inout [CGImage],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        
        let writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let videoSize = CGSize(width: images.last!.width, height: images.last!.height)
        self.videoSize = videoSize
        
        print("[VideoSize] \(videoSize)")
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        writerInput.expectsMediaDataInRealTime = false
        writer.add(writerInput)
        
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        
        var frameCount: Int64 = 0
        images.reverse()
        while images.isEmpty == false {
            let image = images.removeLast()
            autoreleasepool { // CVPixelBuffer가 쌓이지 않도록
                while !writerInput.isReadyForMoreMediaData { }
                var pixelBuffer: CVPixelBuffer?
                image.getCVPixelBuffer(pixelBuffer: &pixelBuffer)
                guard var inputPixelBuffer = pixelBuffer else {
                    completion(
                        false,
                        NSError(
                            domain: "com.example.VideoCreator",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"]
                        )
                    )
                    return
                }
                let frameTime = CMTimeMake(value: frameCount, timescale: fps)
                CVPixelBufferLockBaseAddress(inputPixelBuffer, [])
                image.drawCVPixelBuffer(&inputPixelBuffer)
                adaptor.append(inputPixelBuffer, withPresentationTime: frameTime)
                CVPixelBufferUnlockBaseAddress(inputPixelBuffer, [])
                pixelBuffer = nil
                frameCount += 1
            }
        }
        
        writerInput.markAsFinished() // 샘플 추가가 완료되었음을 나타내기 위해 입력을 완료로 표시합니다.
        writer.finishWriting { // AVAssetWriter가 쓰기를 완료함
            completion(writer.status == .completed, writer.error)
        }
    }
}

extension CGImage {
    func getCVPixelBuffer(pixelBuffer: inout CVPixelBuffer?) {
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as Any,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            self.width,
            self.height,
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let _ = pixelBuffer else {
            return
        }
    }
    func drawCVPixelBuffer(_ buffer: inout CVPixelBuffer) {
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: self.width,
            height: self.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        context?.draw(self, in: CGRect(origin: .zero, size: .init(width: CGFloat(width), height: CGFloat(height))))
    }
}

extension CVPixelBuffer {
    func autoRelease(action: @escaping () -> ()) {
        CVPixelBufferLockBaseAddress(self, [])
        action()
        CVPixelBufferUnlockBaseAddress(self, [])
    }
}
