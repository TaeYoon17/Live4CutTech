//
//  VideoMakerService.swift
//  LiveFourCut
//
//  Created by Greem on 9/7/25.
//

import Foundation
import CoreGraphics
import AVFoundation

protocol VideMakerProtocol: Sendable {
    func transpose(_ matrix: inout [[CGImage]])
    ///    func reduce(images: [CGImage], spacing:CGFloat) throws -> CGImage
    /// [[frameType 별 이미지 배열]] -> Frame 계수
    func run(groupImage: inout [[CGImage]], outputURL: URL) throws -> AsyncThrowingStream<Double, Error>
}
enum VideoMakerError: Error {
    case faileToCreatePixelBuffer
    case memoryPeak
    case emptyImage
    case noneMatchFrameMode
}

extension VideMakerProtocol {
    func transpose(_ matrix: inout [[CGImage]]) {
        let rows = matrix.count
        let cols = matrix[0].count
        
        // 새로운 배열을 미리 할당하되, 필요한 크기만큼만
        var transposed: [[CGImage]] = []
        transposed.reserveCapacity(cols)
        
        for j in 0..<cols {
            var newRow: [CGImage] = []
            newRow.reserveCapacity(rows)
            
            for i in 0..<rows {
                newRow.append(matrix[i][j])
            }
            transposed.append(newRow)
        }
        
        matrix = transposed
    }
}

final class VideoMaker: VideMakerProtocol {
    private let memoryWarningService: MemoryWarningServiceProtocol
    private let frameService: FrameServiceProtocol
    
    init(
        memoryWarningService: MemoryWarningServiceProtocol,
        frameService: FrameServiceProtocol
    ) {
        self.frameService = frameService
        self.memoryWarningService = memoryWarningService
    }
    
    func run(groupImage: inout [[CGImage]], outputURL: URL) throws -> AsyncThrowingStream<Double, Error> {
        self.transpose(&groupImage)
        groupImage.reverse()
        guard let firsTimeImage = groupImage.first,
              let reduceImage = try? self.frameService.reduce(images: firsTimeImage) else {
            throw VideoMakerError.emptyImage
        }
        guard firsTimeImage.count == frameService.frameType.frameCount else {
            throw VideoMakerError.noneMatchFrameMode
        }
        
        let (writer, writerInput, adaptor) = try makeAVService(
            width: reduceImage.width,
            height: reduceImage.height,
            outputURL: outputURL
        )
        
        
        let copiedGroupImage = groupImage
        return AsyncThrowingStream { conti in
            
            let maxFrameCount: Int = groupImage.count
            
            Task { @Sendable in
                var frameCount: Int = 0
                var groupImage = copiedGroupImage
                let fps = 24
                writer.startWriting()
                writer.startSession(atSourceTime: .zero)
                while groupImage.isEmpty == false {
                    while await memoryWarningService.isMemoryWarning { }
                    try autoreleasepool { // CVPixelBuffer가 쌓이지 않도록
                        while !writerInput.isReadyForMoreMediaData { }
                        var pixelBuffer: CVPixelBuffer?
                        let singleFrameImages: [CGImage] = groupImage.removeLast()
                        guard let reduceImage = try? frameService.reduce(images: singleFrameImages) else {
                            assertionFailure("왜 없음?")
                            return
                        }
                        
                        reduceImage.getCVPixelBuffer(pixelBuffer: &pixelBuffer)
                        guard var pixelBuffer else {
                            throw VideoMakerError.faileToCreatePixelBuffer
                        }
                        
                        let frameTime: CMTime = CMTimeMake(value: Int64(frameCount), timescale: Int32(fps))
                        CVPixelBufferLockBaseAddress(pixelBuffer, [])
                        reduceImage.drawCVPixelBuffer(&pixelBuffer)
                        adaptor.append(pixelBuffer, withPresentationTime: frameTime)
                        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                        conti.yield(Double(frameCount) / Double(maxFrameCount))
                        frameCount += 1
                    }
                }
                writerInput.markAsFinished() // 샘플 추가가 완료되었음을 나타내기 위해 입력을 완료로 표시합니다.
                writer.finishWriting {
                    conti.finish()
                 }
            }
        }
    }
    
    
    private func makeAVService(
        width: Int,
        height: Int,
        outputURL: URL
    ) throws -> (
        AVAssetWriter,
        AVAssetWriterInput,
        AVAssetWriterInputPixelBufferAdaptor
    ) {
        let videoSize = CGSize(width: width, height: height)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.hevc,
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
        return (writer, writerInput, adaptor)
    }
}
extension AVAssetWriter: @unchecked @retroactive Sendable { }
extension AVAssetWriterInput: @unchecked @retroactive Sendable { }
extension AVAssetWriterInputPixelBufferAdaptor: @unchecked @retroactive Sendable { }
