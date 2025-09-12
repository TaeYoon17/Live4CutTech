//
//  ShareBtn.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit

final class ShareBtn: UIButton {
    var action:(()->())?
    
    init() {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .black
        config.baseForegroundColor = .white
        config.attributedTitle = .init(
            "공유하기",
            attributes: .init([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ])
        )
        config.image = UIImage(systemName: "square.and.arrow.up")
        config.imagePadding = 8
        self.configuration = config
        self.addTarget(
            self,
            action: #selector(Self.shareButtonTapped(sender:)),
            for: .touchUpInside
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("Don't use storyboard")
    }
    
    @objc func shareButtonTapped(sender: UIButton) {
        action?()
    }
}

