//
//  PhotoSelectionView.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit
import Combine

final class PhotoSelectionView: UIView {
    enum Event {
        case navigationBack
        case selectDone
        case openPicker
    }
    
    let eventPublisher = PassthroughSubject<Event, Never>()
    private weak var viewModel: ThumbnailSelectorVM!
    //MARK: -- View 저장 프로퍼티
    lazy var thumbnailFrameView = ThumbnailFourFrameView(viewModel: viewModel)
    lazy var thumbnailSelectorView = ThumbnailSelectorView(viewModel: viewModel)
    
    let selectDoneBtn = DoneBtn(title: "4컷 영상 미리보기")
    let pregress = UIProgressView(progressViewStyle: .bar)
    let reSelectPhotoBtn = ReSelectPhotoBtn()
    let navigationBackButton = NavigationBackButton()
    
    let titleLabel: UILabel = {
        var label = UILabel()
        label.text = "이미지 선택"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    
    let descLabel: UILabel = {
        let label = UILabel()
        label.text = "라이브로 찍은 이미지를 골라주세요!"
        label.font = .systemFont(ofSize: 18,weight: .regular)
        return label
    }()
    
    private let bottomView: UIView = .init()
    
    init(viewModel: ThumbnailSelectorVM!) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureLayout()
        configureConstraints()
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLayout() {
        self.addSubview(navigationBackButton)
        [titleLabel, descLabel, thumbnailFrameView, bottomView].forEach { self.addSubview($0) }
        [thumbnailSelectorView, selectDoneBtn, pregress, reSelectPhotoBtn].forEach {
            bottomView.addSubview($0)
        }
    }
    
    func configureConstraints() {
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
        pregress.snp.makeConstraints { make in
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
    
    func configureView() {
        self.backgroundColor = .systemBackground
        pregress.backgroundColor = .lightGray
        pregress.tintColor = .black
        pregress.isHidden = true
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
