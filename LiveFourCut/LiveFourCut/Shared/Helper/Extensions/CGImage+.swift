//
//  CGImage+.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit

extension CGImage {
    func makeRoundedCorner(radius:CGFloat = 0) -> CGImage? {
        var cgImage = self
        let width = cgImage.width
        let height = cgImage.height
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        
        let bitmapInfo = cgImage.bitmapInfo
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace!,
                                      bitmapInfo: bitmapInfo.rawValue) else { return nil }
        context.setFillColor(UIColor.clear.cgColor)
        context.setAlpha(1)
        context.fill([.init(x: 0, y: 0, width: width, height: height)])
        context.beginPath()
        let roundedPath2 = CGPath.init(roundedRect: .init(x: 0, y: 0, width: width, height: height), cornerWidth: radius , cornerHeight: radius, transform: nil)
        context.addPath(roundedPath2)
        context.closePath()
        context.clip()
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        guard let roundedCGImage = context.makeImage() else { return nil }
        return roundedCGImage
    }
}
