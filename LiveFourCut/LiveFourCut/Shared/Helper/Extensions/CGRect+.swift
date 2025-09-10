//
//  CGRect+.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import CoreGraphics

extension CGRect {
    static func cropFromCenter(width:CGFloat,height:CGFloat,ratio targetRatio:CGFloat = 1) -> Self{
        let currentRatio = width / height
        var yOffset:CGFloat = 0
        var xOffset:CGFloat = 0
        var cropHeight:CGFloat = height
        var cropWidth:CGFloat = width
        if currentRatio > targetRatio{
            cropWidth = height * targetRatio
            xOffset = (width - cropWidth) * 0.5
            
        }else{
            cropHeight = width / targetRatio
            yOffset = (height - cropHeight) * 0.5
        }
        let cropSize = CGRect(x: xOffset, y: yOffset, width: cropWidth, height: cropHeight)
        return cropSize
    }
}
