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
    
    static func createVideo(
        from images: [UIImage],
        outputURL: URL,
        fps: Int32 = 24,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        print(images.count)
        guard !images.isEmpty else {
            completion(
                false,
                NSError(
                    domain: "com.example.VideoCreator",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No images to create video"]
                )
            )
            return
        }
        
        // 비디오 설정
        let videoSize = CGSize(width: images.last!.cgImage!.width, height: images.last!.cgImage!.height)
        let writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
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
            kCVPixelBufferHeightKey as String: videoSize.height
        ]
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        var frameCount: Int64 = 0
        let frameDuration = CMTimeMake(value: 1, timescale: fps)
        
        for image in images {
            autoreleasepool {
                while !writerInput.isReadyForMoreMediaData { }
                
                guard let pixelBuffer = self.pixelBuffer(from: image, size: videoSize) else {
                    completion(false, NSError(
                        domain: "com.example.VideoCreator",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"]
                    ))
                    return
                }
                
                let frameTime = CMTimeMake(value: frameCount, timescale: fps)
                adaptor.append(pixelBuffer, withPresentationTime: frameTime)
                frameCount += 1
            }
        }
        
        writerInput.markAsFinished()
        writer.finishWriting {
            completion(writer.status == .completed, writer.error)
        }
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
    private static func pixelBuffer(data:CFData,size:CGSize,bytesPerRow:Int) -> CVPixelBuffer?{
        let options: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue as Any,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue as Any
        ]
        let cfImgData = data as CFData
        let dataFromImageDataProvider = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, cfImgData)
        let x = CFDataGetMutableBytePtr(dataFromImageDataProvider)!
        var pixelBuffer: CVPixelBuffer?
        //bytes per raw를 알아야한다.
        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, x, bytesPerRow , nil, nil, options as CFDictionary, &pixelBuffer)
        
        return pixelBuffer
    }
}
extension VideoCreator{
    func createVideo(
        from images: inout [CGImage],
        completion: @escaping (Bool, Error?) -> Void
    ) {
        
        let writer = try! AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let videoSize = CGSize(width: images.last!.width, height: images.last!.height)
        self.videoSize = videoSize
//        let videoSize = CGSize(width: self.videoSize.width, height: self.videoSize.height)
        
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
        for image in images {
            autoreleasepool {
                while !writerInput.isReadyForMoreMediaData { }
                var pixelBuffer: CVPixelBuffer?
                image.getCVPixelBuffer(pixelBuffer: &pixelBuffer)
                guard let pixelBuffer else {
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
                pixelBuffer.autoRelease { [weak pixelBuffer] in
                    guard var pixelBuffer else { return }
                    image.drawCVPixelBuffer(&pixelBuffer)
                    adaptor.append(pixelBuffer, withPresentationTime: frameTime)
                }
                frameCount += 1
            }
        }
        writerInput.markAsFinished()
        writer.finishWriting {
            completion(writer.status == .completed, writer.error)
        }
    }
}
extension CGImage{
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
