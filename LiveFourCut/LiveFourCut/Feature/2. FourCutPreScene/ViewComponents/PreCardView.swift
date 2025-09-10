//
//  PreCardView.swift
//  LiveFourCut
//
//  Created by Greem on 6/21/24.
//

import Foundation
import UIKit
import AVFoundation
import Combine
extension FrameType {
    var aspectRatio: CGFloat {
        switch self {
        case .basic2x2: 1.58
        }
    }
}
final class PreCardView: UIView {
    var minDuration: Float = Constants.defaultMinDurationSeconds {
        didSet {
            let timeRange = CMTimeRange(
                start: .zero, // 0초부터
                duration: CMTime( // 이 minDuration 까지
                    seconds: Float64(minDuration),
                    preferredTimescale: CMTimeScale(Constants.preferredTimescale)
                )
            )
            print("바뀐 minDuration: \(minDuration),  timeRange: \(timeRange)")
            if let item, self.looper == nil {
                self.looper = AVPlayerLooper(
                    player: queuePlayer,
                    templateItem: item,
                    timeRange: timeRange
                )
            }
        }
    }
    
    var container: AVAssetContainer? {
        didSet {
            guard let container,
                  let url = URL(string:container.originalAssetURL) else {
                item = nil
                return
            }
            item = AVPlayerItem(asset: AVAsset(url: url))
        }
    }
    
    private var item: AVPlayerItem? {
        didSet {
            guard let item else {
                self.queuePlayer.pause()
                self.queuePlayer.replaceCurrentItem(with: nil)
                self.looper = nil // looper도 해제
                return
            }
            
            if minDuration != Constants.defaultMinDurationSeconds && looper == nil {
                Task {
                    let timeRange = CMTimeRange(
                        start: .zero,
                        duration: CMTime(
                            seconds: Float64(minDuration),
                            preferredTimescale: 10
                        )
                    )
                    self.looper = AVPlayerLooper(
                        player: queuePlayer,
                        templateItem: item,
                        timeRange: timeRange
                    )
                }
            }
        }
    }
    
    private var playerLayer: AVPlayerLayer!
    private var queuePlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    
    init() {
        super.init(frame: .zero)
        let playerLayer = AVPlayerLayer(player: self.queuePlayer)
        playerLayer.videoGravity = .resizeAspectFill
        self.queuePlayer.isMuted = true
        self.playerLayer = playerLayer
        self.layer.addSublayer(playerLayer)
        setupConstraints()
        setupView()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("Don't use storyboard")
    }
    
    deinit {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.playerLayer?.frame = self.bounds
    }
    
    private func setupConstraints() {
        self.snp.makeConstraints { make in
            make.height.equalTo(snp.width).multipliedBy(1.58)
        }
    }
    
    private func setupView() {
        self.backgroundColor = .white
        self.contentMode = .scaleAspectFill // 이미지가 상하or좌우에 꽉 차도록 설정
        self.clipsToBounds = true // 벗어나는 범위는 자름
    }
    
    func play() {
        queuePlayer.play()
    }
}
