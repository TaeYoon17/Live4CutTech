//
//  SharingViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/19/24.
//

import UIKit
import AVFoundation

class SharingViewController: BaseVC {
    
    // MARK: - Properties
    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "영상변환 완료!!"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    let descLabel: UILabel = {
        let label = UILabel()
        label.text = "라이브 이미지가 영상으로 변환되었습니다.\n지금 영상을 확인하고 소중한 추억을 함께 나눠보세요!  :)"
        label.font = .systemFont(ofSize: 18,weight: .regular)
        return label
    }()
    let videoFrameView = UIView()
    let bottomFrameView = UIView()
    let navigationBackButton = NavigationBackButton()
    
    var videoURL: URL?
    let shareBtn = ShareBtn()
    private var playerLayer: AVPlayerLayer?
    private var queuePlayer = AVQueuePlayer()
    private var looper:AVPlayerLooper?
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.setupConstraints()
        self.setupPlayer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerLayer?.frame = view.bounds
        self.playerLayer?.frame = self.videoFrameView.bounds
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
    // MARK: - Setup
    override func configureLayout() {
        super.configureLayout()
        [titleLabel,descLabel,videoFrameView,bottomFrameView].forEach { view in
            self.view.addSubview(view)
        }
        bottomFrameView.addSubview(shareBtn)
    }
    override func configureConstraints() {
        super.configureConstraints()
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.centerX.equalToSuperview()
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(11)
            make.centerX.equalToSuperview()
        }
        videoFrameView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(18)
            make.horizontalEdges.equalToSuperview().inset(50)
            make.height.equalTo(videoFrameView.snp.width).multipliedBy(1.77)
        }
        bottomFrameView.snp.makeConstraints { make in
            make.top.equalTo(videoFrameView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        shareBtn.snp.makeConstraints { make in
            make.height.equalTo(50)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.centerY.equalToSuperview()
        }
    }
    override func configureNavigation() {
        super.configureNavigation()
        self.view.addSubview(navigationBackButton)
        navigationBackButton.snp.makeConstraints { make in
            make.leading.equalTo(self.view).inset(16.5)
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(4)
        }
        navigationBackButton.action = {[weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    override func configureView() {
        super.configureView()
        self.shareBtn.addAction(.init(handler: {[weak self] action in
            guard let self else {return}
            guard let url = videoURL else { return }
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activityViewController, animated: true)
        }), for: .touchUpInside)
    }
    private func setupConstraints(){ }
    
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
        self.videoFrameView.backgroundColor = .white
        self.videoFrameView.layer.masksToBounds = true
        self.videoFrameView.layer.addSublayer(playerLayer)
        self.queuePlayer.play()
    }
    
    // MARK: - Functions
    
    @objc private func share(_ sender: UIBarButtonItem) {
        guard let url = videoURL else {
            return
        }
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
    }
    
    // MARK: - Deinitializer
    
    deinit {
        queuePlayer.pause()
        self.looper = nil
        self.playerLayer = nil
    }
    
    
}
extension SharingViewController {
    final class ShareBtn: UIButton{
        var action:(()->())?
        init(){
            super.init(frame: .zero)
            var config = UIButton.Configuration.filled()
            config.baseBackgroundColor = .black
            config.baseForegroundColor = .white
            config.attributedTitle = .init(
                "공유하기",
                attributes: .init([.font: UIFont.systemFont(ofSize: 17, weight: .semibold)])
            )
            config.image = UIImage(systemName: "square.and.arrow.up")
            config.imagePadding = 8
            self.configuration = config
            self.addTarget(self, action: #selector(Self.shareButtonTapped(sender:)), for: .touchUpInside)
        }
        required init?(coder: NSCoder) {
            fatalError("Don't use storyboard")
        }
        @objc func shareButtonTapped(sender: UIButton){
            action?()
        }
    }
}
