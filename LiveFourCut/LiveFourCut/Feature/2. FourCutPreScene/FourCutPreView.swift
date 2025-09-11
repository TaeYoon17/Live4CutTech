//
//  FourCutPreView.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit
import Combine

final class FourCutPreView: UIView {
    
    enum Event {
        case navigationBack
        case shareStart
    }
    
    let eventPublisher = PassthroughSubject<Event, Never>()
    
    private let preFourFrameView = Pre2x2FrameView()
    private let navigationBackButton = NavigationBackButton()
    
    private let bottomFrameView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "이미지 선택"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.text = "이미지 선택을 완료하였습니다!\n원하는 이미지가 맞는지 재확인해주세요 :)"
        label.font = .systemFont(ofSize: 18,weight: .regular)
        return label
    }()
    
    private let shareBtn = DoneBtn(title: "4컷 영상 추출하러가기")
    
    private let frameType: FrameType
    
    init(frameType: FrameType) {
        self.frameType = frameType
        super.init(frame: .zero)
        self.backgroundColor = .systemBackground
        configureLayout()
        configureConstraints()
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Don't use storyboard")
    }
    
    func setUpPreView(minDuration: Double, avAssetContainers: [AVAssetContainer]) {
        self.preFourFrameView.minDuration = minDuration
        self.preFourFrameView.containers = avAssetContainers
    }
    
    func playPreView() {
        self.preFourFrameView.play()
    }
}

fileprivate extension FourCutPreView {
    
    private func configureLayout() {
        self.addSubview(navigationBackButton)
        [titleLabel, descLabel, preFourFrameView, bottomFrameView].forEach { self.addSubview($0) }
        bottomFrameView.addSubview(shareBtn)
    }
    
    private func configureConstraints() {
       titleLabel.snp.makeConstraints { make in
           make.top.equalTo(safeAreaLayoutGuide).offset(8)
           make.centerX.equalToSuperview()
       }
       descLabel.snp.makeConstraints { make in
           make.top.equalTo(titleLabel.snp.bottom).offset(11)
           make.centerX.equalToSuperview()
       }
       preFourFrameView.snp.makeConstraints { make in
           make.top.equalTo(descLabel.snp.bottom).offset(12)
           make.horizontalEdges.equalToSuperview().inset(50)
           make.height.equalTo(preFourFrameView.snp.width).multipliedBy(frameType.mergeRatio)
       }
       bottomFrameView.snp.makeConstraints { make in
           make.top.equalTo(preFourFrameView.snp.bottom)
           make.leading.trailing.equalToSuperview()
           make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
       }
       shareBtn.snp.makeConstraints { make in
           make.height.equalTo(50)
           make.horizontalEdges.equalToSuperview().inset(24)
           make.centerY.equalToSuperview()
       }
        navigationBackButton.snp.makeConstraints { make in
            make.leading.equalTo(self).inset(16.5)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(4)
        }
   }
    
    private func configureView() {
        navigationBackButton.action = { [weak self] in
            guard let self else { return }
            eventPublisher.send(.navigationBack)
        }
        shareBtn.action = { [weak self] in
            guard let self else { return }
            eventPublisher.send(.shareStart)
        }
    }
}
