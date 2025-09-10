//
//  PhotoSelectionView.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit
import Combine

enum PhotoSelectionEvent {
    case navigationBack
    case selectDone
    case openPicker
}

final class PhotoSelectionView: UIView {
    let eventPublisher = PassthroughSubject<PhotoSelectionEvent, Never>()
    
    private weak var thumbnailSelector: ThumbnailSelectorProtocol!
    //MARK: -- View 저장 프로퍼티
    private lazy var thumbnailFrameView = ThumbnailFourFrameView(thumbnailSelector: thumbnailSelector)
    private lazy var thumbnailSelectorView = ThumbnailSelectorView(thumbnailSelector: thumbnailSelector)
    private lazy var selectDoneBtn = DoneBtn(title: "\(thumbnailSelector.frameType.frameCount)컷 영상 미리보기")
    private let progress = UIProgressView(progressViewStyle: .bar)
    private let reSelectPhotoBtn = ReSelectPhotoBtn()
    private let navigationBackButton = NavigationBackButton()
    
    private let titleLabel: UILabel = {
        var label = UILabel()
        label.text = "이미지 선택"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    private let descLabel: UILabel = {
        let label = UILabel()
        label.text = "라이브로 찍은 이미지를 골라주세요!"
        label.font = .systemFont(ofSize: 18,weight: .regular)
        return label
    }()
    private let bottomView: UIView = .init()
    
    init(thumbnailSelector: ThumbnailSelectorProtocol) {
        self.thumbnailSelector = thumbnailSelector
        super.init(frame: .zero)
        configureLayout()
        configureConstraints()
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Methods
    @MainActor
    func updateImageContainers(imageContainers: [ImageContainer]) {
        self.thumbnailSelectorView.setImageContainers(imageContainers: imageContainers)
    }
    
    @MainActor
    func updateFetchProgress(_ progressNumber: Float) {
        UIView.animate(withDuration: 0.2) {
            if !self.progress.isHidden && progressNumber == 1 {
                self.progress.isHidden = true
            } else if self.progress.isHidden && progressNumber != 1 {
                self.progress.isHidden = false
            }
            self.progress.progress = progressNumber
        }
    }
    
    @MainActor
    func updateSelectionCompletionState(_ isPrintSelectionCompleted: Bool) {
        selectDoneBtn.isHidden = !isPrintSelectionCompleted
        thumbnailSelectorView.isHidden = isPrintSelectionCompleted
        reSelectPhotoBtn.isHidden = !isPrintSelectionCompleted
    }
    
    @MainActor
    func resetToImageProcessingState() {
        selectDoneBtn.isHidden = true
        reSelectPhotoBtn.isHidden = true
        progress.isHidden = false
        thumbnailSelectorView.isHidden = false
        thumbnailSelectorView.reset()
        thumbnailFrameView.reset()
    }
}
extension PhotoSelectionView {

    private func configureLayout() {
        self.addSubview(navigationBackButton)
        [titleLabel, descLabel, thumbnailFrameView, bottomView].forEach { self.addSubview($0) }
        [thumbnailSelectorView, selectDoneBtn, progress, reSelectPhotoBtn].forEach {
            bottomView.addSubview($0)
        }
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
        thumbnailFrameView.snp.makeConstraints {
            $0.top.equalTo(descLabel.snp.bottom).offset(18)
            $0.horizontalEdges.equalToSuperview().inset(50)
            $0.height.equalTo(thumbnailFrameView.snp.width).multipliedBy(1.77)
        }
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(thumbnailFrameView.snp.bottom)
            make.bottom.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(safeAreaLayoutGuide)
        }
        thumbnailSelectorView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(24)
        }
        selectDoneBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(50)
            make.horizontalEdges.equalToSuperview().inset(24)
        }
        progress.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(2)
            make.horizontalEdges.equalToSuperview().inset(24)
        }
        reSelectPhotoBtn.snp.makeConstraints { make in
            make.top.equalTo(selectDoneBtn.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        navigationBackButton.snp.makeConstraints { make in
            make.leading.equalTo(self).inset(16.5)
            make.top.equalTo(self.safeAreaLayoutGuide).offset(4)
        }
    }
    
    private func configureView() {
        self.backgroundColor = .systemBackground
        progress.backgroundColor = .lightGray
        progress.tintColor = .black
        progress.isHidden = true
        self.navigationBackButton.action = { [weak self] in
            guard let self else { return }
            eventPublisher.send(.navigationBack)
        }
        self.selectDoneBtn.action = { [weak self] in
            guard let self else { return }
            eventPublisher.send(.selectDone)
        }
        self.reSelectPhotoBtn.action = { [weak self] in
            guard let self else { return }
            eventPublisher.send(.openPicker)
        }
    }
}