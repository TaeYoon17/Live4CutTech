//
//  SharingView.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit
import Combine

final class SharingView: UIView {
    enum Event {
        case navigationBack
        case shareStart
    }
    let eventSubject = PassthroughSubject<Event, Never>()
    // MARK: - Properties
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "영상변환 완료!!"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.text = "라이브 이미지가 영상으로 변환되었습니다.\n지금 영상을 확인하고 소중한 추억을 함께 나눠보세요!  :)"
        label.font = .systemFont(ofSize: 18,weight: .regular)
        return label
    }()
    
    let videoFrameView = UIView()
    private let bottomFrameView = UIView()
    private let navigationBackButton = NavigationBackButton()
    private let shareBtn = ShareBtn()
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .systemBackground
        configureLayout()
        configureConstraints()
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureLayout() {
        self.addSubview(navigationBackButton)
        [titleLabel, descLabel, videoFrameView, bottomFrameView].forEach { view in
            self.addSubview(view)
        }
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
        videoFrameView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(18)
            make.horizontalEdges.equalToSuperview().inset(50)
            make.height.equalTo(videoFrameView.snp.width).multipliedBy(1.77)
        }
        bottomFrameView.snp.makeConstraints { make in
            make.top.equalTo(videoFrameView.snp.bottom)
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
        navigationBackButton.action = {[weak self] in
            guard let self else { return }
            eventSubject.send(.navigationBack)
        }
        
        self.shareBtn.addAction(.init(handler: { [weak self] action in
            guard let self else { return }
            eventSubject.send(.shareStart)
        }), for: .touchUpInside)
    }
}
