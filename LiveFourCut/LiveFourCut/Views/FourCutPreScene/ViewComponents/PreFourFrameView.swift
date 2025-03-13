//
//  PreFourFrameView.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import UIKit
import Combine

extension FourCutPreViewController{
    final class PreFourFrameView: UIStackView{
        var containers:[AVAssetContainer]! {
            didSet{
                guard let containers, containers.count == 4 else { return }
                for (offset,container) in containers.enumerated(){
                    imageViews[offset].container = container
                }
            }
        }
        var minDuration:Float!{
            didSet{
                guard let minDuration else { return }
                imageViews.forEach({ $0.minDuration = minDuration })
            }
        }
        private var imageViews:[PreCardView] = (0..<4).map{_ in PreCardView()}
        let frameSpacing: CGFloat = 4
        private lazy var upperStack = {
            let subViews = [imageViews[0],imageViews[1]]
            let stView = UIStackView(arrangedSubviews: subViews)
            stView.axis = .horizontal
            stView.alignment = .fill
            stView.distribution = .fillEqually
            stView.spacing = frameSpacing
            return stView
        }()
        
        private lazy var lowerStack = {
            let subViews = [imageViews[2],imageViews[3]]
            let stView = UIStackView(arrangedSubviews: subViews)
            stView.axis = .horizontal
            stView.distribution = .fillEqually
            stView.alignment = .fill
            stView.spacing = frameSpacing
            return stView
        }()
        var cancellable = Set<AnyCancellable>()
        
        init(){
            super.init(frame: .zero)
            [upperStack,lowerStack].forEach{ addArrangedSubview($0) }
            self.axis = .vertical
            self.alignment = .fill
            self.distribution = .fill
            self.spacing = frameSpacing
            self.backgroundColor = .black
            self.isLayoutMarginsRelativeArrangement = true
            self.layoutMargins = UIEdgeInsets(
                top: frameSpacing,
                left: frameSpacing,
                bottom: frameSpacing,
                right: frameSpacing)
            self.tag = 0
        }
        required init(coder: NSCoder) {
            fatalError("Don't use storyboard")
        }
        func play(){ self.imageViews.forEach({ $0.play() }) }
    }
}

