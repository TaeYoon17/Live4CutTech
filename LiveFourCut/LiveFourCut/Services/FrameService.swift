//
//  FrameService.swift
//  LiveFourCut
//
//  Created by Greem on 7/3/24.
//

import Foundation
import UIKit
enum FrameError: Error{
    case flipFailed
    case renderFailed
}
enum FrameType{
    case basic2x2
}
protocol FrameServiceProtocol{
    var frameType:FrameType { get }
    var frameTargetSize: CGSize { get }
    var frameCornerRadius: CGFloat { get }
    
//    func reduce(images:[CGImage],spacing:CGFloat) throws -> CGImage
    func reduce(images:inout [CGImage],spacing:CGFloat) throws -> CGImage
}
final class FrameGenerator:FrameServiceProtocol{
    var frameType:FrameType = .basic2x2
    var frameTargetSize: CGSize = .init(width: 300, height: 300 * 1.77)
    var frameCornerRadius: CGFloat = 0
    
    func groupReduce(groupImageURL groupImage: [[URL]],spacing: CGFloat) async throws -> [CGImage]{
        let frameCount = groupImage.first!.count
        let groupCount = groupImage.count
        var images:[CGImage] = []
        for offset in 0..<frameCount {
            var singleFrameImagesURL = (0..<groupCount).map{ groupImage[$0][offset] }
            var singleFrameImages = singleFrameImagesURL.map {
                self.loadCGImageFromFile(at: $0)!
            }
            let reduceImage = try! self.reduce(images: &singleFrameImages, spacing: 4)
            singleFrameImages = []
            try await Task.sleep(nanoseconds: 100)
            images.append(reduceImage)
        }
        return images
        
    }
    func loadCGImageFromFile(at url: URL) -> CGImage? {
        // 파일에서 이미지 데이터를 읽어오기 위한 CGImageSource 생성
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            print("Failed to create image source.")
            return nil
        }

        // 첫 번째 이미지에서 CGImage 가져오기 (여러 페이지가 있을 경우 첫 번째 페이지)
        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to create CGImage.")
            return nil
        }
        
        return cgImage
    }
    func groupReduce(groupImage: [[CGImage]],spacing: CGFloat) async throws -> [CGImage]{
        let frameCount = groupImage.first!.count
        let groupCount = groupImage.count
        var images:[CGImage] = []
        for offset in 0..<frameCount {
            var singleFrameImages = (0..<groupCount).map{ groupImage[$0][offset] }
            let reduceImage = try! self.reduce(images: &singleFrameImages, spacing: 4)
            singleFrameImages = []
            try await Task.sleep(nanoseconds: 100)
            images.append(reduceImage)
        }
//        let images:[CGImage] = try await withThrowingTaskGroup(of: (Int,CGImage).self) { taskGroup in
//            for offset in 0..<frameCount {
//                var singleFrameImages = (0..<groupCount).map{ groupImage[$0][offset] }
//                taskGroup.addTask {
//                    let reduceImage = try! self.reduce(images: singleFrameImages, spacing: 4)
//                    singleFrameImages = []
//                    return (offset,reduceImage)
//                }
//            }
//            var imgs:[CGImage?] = Array(repeating: nil,count: frameCount)
//            for try await v in taskGroup{
//                imgs[v.0] = v.1
//            }
//            return imgs.compactMap({$0})
//        }
        return images
        
    }
}
extension FrameGenerator{
    func reduce(images:inout [CGImage],spacing:CGFloat) throws -> CGImage{
        let frameTargetSize = frameTargetSize
        let flipCropImages:[CGImage] = images.map{
            let flippedImg = try! $0.flipImageHorizontal()!
            let (height,width) = (CGFloat(flippedImg.height),CGFloat(flippedImg.width))
            let centerCropSize = CGRect.cropFromCenter(width: width, height: height,ratio: frameTargetSize.ratio)
            return flippedImg.cropping(to: centerCropSize)!
        }
        images = []
        let nW = 0.5 * frameTargetSize.width - 1.5 * spacing
        let nH = 0.5 * frameTargetSize.height - 1.5 * spacing
        let ltRect = CGRect.init(x: spacing, y: spacing, width: nW, height: nH)
        let rtRect = CGRect.init(x: nW + 2 * spacing, y: spacing, width: nW, height: nH)
        let ldRect = CGRect.init(x: spacing, y: nH + 2 * spacing, width: nW, height: nH)
        let rdRect = CGRect.init(x: nW + 2 * spacing, y: nH + 2 * spacing, width: nW, height: nH)
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1
        rendererFormat.opaque = true
        rendererFormat.preferredRange = .standard
        let render = UIGraphicsImageRenderer(size: frameTargetSize,format: rendererFormat)
        let imageData = render.image { context in
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.beginPath()
            let roundedPath2 = CGPath.init(roundedRect: .init(origin: .zero, size: frameTargetSize),
                                           cornerWidth: frameCornerRadius, cornerHeight: frameCornerRadius, transform: nil)
            context.cgContext.addPath(roundedPath2)
            context.cgContext.closePath()
            context.cgContext.fillPath()
            zip(flipCropImages,[ltRect,rtRect,ldRect,rdRect]).forEach { image,rect in
                context.cgContext.draw(image, in: rect, byTiling: false)
            }
        }
        guard let image = imageData.cgImage else { throw FrameError.renderFailed}
        return image
    }
}
fileprivate extension CGImage{
    func flipImageHorizontal() throws -> CGImage? {
        let width = self.width
        let height = self.height
        guard let context = CGContext.createBy(cgImage: self) else { throw FrameError.flipFailed }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(self, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        guard let flippedCGImage = context.makeImage() else { return nil }
        return flippedCGImage
    }
}
extension CGContext{
    static func createBy(cgImage:CGImage)->CGContext?{
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        let bitmapInfo = cgImage.bitmapInfo
        return CGContext(data: nil,
                         width: width,
                         height: height,
                         bitsPerComponent: bitsPerComponent,
                         bytesPerRow: bytesPerRow,
                         space: colorSpace!,
                         bitmapInfo: bitmapInfo.rawValue)
    }
}
extension CGSize{
    var ratio:CGFloat{ self.width / self.height }
}
