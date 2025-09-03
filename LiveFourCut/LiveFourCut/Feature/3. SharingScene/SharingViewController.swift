//
//  SharingViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/19/24.
//

import UIKit
import AVFoundation
import Combine

final class SharingViewController: BaseVC {
    private let contentView = SharingView()
    var videoURL: URL?
    private var playerLayer: AVPlayerLayer?
    private var queuePlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    
    private var cancellables = Set<AnyCancellable>()
    
    
    // MARK: - Deinitializer
    deinit {
        queuePlayer.pause()
        self.looper = nil
        self.playerLayer = nil
    }
    // MARK: - Life Cycle
    override func loadView() {
        self.view = contentView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupPlayer()
        bindAction()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerLayer?.frame = self.contentView.videoFrameView.bounds
        self.playerLayer?.videoGravity = .resizeAspectFill
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    private func bindAction() {
        contentView.eventSubject.receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .navigationBack:
                    self.navigationController?.popViewController(animated: true)
                case .shareStart: showShareActivity()
                }
            }.store(in: &cancellables)
    }
    
    private func showShareActivity() {
        guard let url = videoURL else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
    
    private func setupPlayer() {
        guard let videoURL else { return }
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        let playerItem = AVPlayerItem(url: videoURL)
        self.queuePlayer.replaceCurrentItem(with: playerItem)
        self.queuePlayer.isMuted = true
        self.queuePlayer.items()
        self.looper = AVPlayerLooper(player: queuePlayer,templateItem: playerItem)
        self.playerLayer = playerLayer
        self.playerLayer?.videoGravity = .resizeAspectFill
        self.contentView.videoFrameView.backgroundColor = .white
        self.contentView.videoFrameView.layer.masksToBounds = true
        self.contentView.videoFrameView.layer.addSublayer(playerLayer)
        self.queuePlayer.play()
    }

    
    
}
