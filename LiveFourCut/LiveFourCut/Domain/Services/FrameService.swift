//
//  FrameService.swift
//  LiveFourCut
//
//  Created by Greem on 7/3/24.
//

import Foundation
import UIKit
import Combine
import AVFoundation

enum FrameServiceError: Error {
    case noneMatchFrameMode
    case failDefaultAlignment
    case renderFailed
}

/// 기본 프레임 설정...
protocol FrameServiceProtocol {
    var frameType: FrameType { get }
    var frameTargetSize: CGSize { get }
    func reduce(images: [CGImage]) throws -> CGImage
}

struct Frame2x2Generator: FrameServiceProtocol {
    var frameType: FrameType
    let frameTargetSize: CGSize
    let spacing: CGFloat
    
    init(
        width: CGFloat,
        spacing: CGFloat = 4
    ) {
        self.frameType = .basic2x2
        self.frameTargetSize = CGSize(width: width, height: width * self.frameType.aspectRatio)
        self.spacing = spacing
    }
    
    func reduce(images: [CGImage]) throws -> CGImage {
        let flipCropImages = try images.map {
            guard let flippedImg = try $0.flipImageHorizontal() else {
                throw FrameServiceError.failDefaultAlignment
            }
            let (height,width) = (CGFloat(flippedImg.height), CGFloat(flippedImg.width))
            let centerCropSize = CGRect.cropFromCenter(width: width, height: height, ratio: frameTargetSize.ratio)
            return flippedImg.cropping(to: centerCropSize)!
        }
        
        let nW = 0.5 * frameTargetSize.width - 1.5 * spacing
        let nH = 0.5 * frameTargetSize.height - 1.5 * spacing
        let ltRect = CGRect.init(x: spacing, y: spacing, width: nW, height: nH)
        let rtRect = CGRect.init(x: nW + 2 * spacing, y: spacing, width: nW, height: nH)
        let ldRect = CGRect.init(x: spacing, y: nH + 2 * spacing, width: nW, height: nH)
        let rdRect = CGRect.init(x: nW + 2 * spacing, y: nH + 2 * spacing, width: nW, height: nH)
        
        let render = UIGraphicsImageRenderer(size: frameTargetSize)
        
        let imageData: UIImage = render.image { context in
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.fillPath()
            zip(flipCropImages, [ltRect, rtRect, ldRect, rdRect])
                .forEach { image, rect in
                    context.cgContext.draw(
                        image,
                        in: rect,
                        byTiling: false
                    )
                }
        }
        
        guard let image = imageData.cgImage else {
            throw FrameServiceError.renderFailed
        }
        
        return image
    }
}

fileprivate extension CGImage {
    func flipImageHorizontal() throws -> CGImage? {
        let width = self.width
        let height = self.height
        guard let context = CGContext.createBy(cgImage: self) else {
            throw FrameError.flipFailed
        }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(self, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        guard let flippedCGImage = context.makeImage() else { return nil }
        return flippedCGImage
    }
}

fileprivate extension CGContext {
    static func createBy(cgImage: CGImage) -> CGContext? {
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        let bitmapInfo = cgImage.bitmapInfo
        
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace!,
            bitmapInfo: bitmapInfo.rawValue
        )
    }
}




fileprivate extension CGSize {
    var ratio: CGFloat { width / height }
}




