//
//  CGImage+.swift
//  LiveFourCut
//
//  Created by Greem on 9/8/25.
//

import Foundation
import UIKit
import AVFoundation

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
