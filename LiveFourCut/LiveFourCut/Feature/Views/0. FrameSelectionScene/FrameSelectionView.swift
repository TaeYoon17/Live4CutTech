//
//  FrameSelectionView.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit
import Combine
import SnapKit

final class FrameSelectionView: UIView {
    let eventPublisher = PassthroughSubject<Event, Never>()
    
    enum Event {
        case frameSelected(FrameType)
    }
    
    private let frameLabel: UILabel = {
        var label = UILabel()
        label.text = "이미지 선택"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.text = "라이브로 찍은 이미지를 골라주세요!"
        label.font = .systemFont(ofSize: 20,weight: .regular)
        return label
    }()
    
    private lazy var outerFrameView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.cornerRadius = 12
        view.backgroundColor = .white
        view.isUserInteractionEnabled = true
        view.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return view
    }()
    
    private lazy var infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 20
        stackView.addArrangedSubview(infoImageView)
        stackView.addArrangedSubview(infoLabel)
        return stackView
    }()
    
    private var infoImageView: UIImageView = {
        var imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = .empty
        return imageView
    }()
    
    private var infoLabel: UILabel = {
       let label = UILabel()
        label.text = "라이브 이미지 4장을\n업로드 해주세요!"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        let fourFrameTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(frameStackViewTapped(_:))
        )
        
        outerFrameView.addGestureRecognizer(fourFrameTapGesture)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        [frameLabel, descLabel, outerFrameView].forEach { self.addSubview($0) }
        outerFrameView.addSubview(infoStackView)
    }
    private func setupConstraints() {
        frameLabel.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(38)
            $0.centerX.equalToSuperview()
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(frameLabel.snp.bottom).offset(11)
            make.centerX.equalToSuperview()
        }
        outerFrameView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(50)
            make.centerY.equalTo(self.snp.centerY).offset(55)
            make.height.equalTo(outerFrameView.snp.width).multipliedBy(1.77)
        }
        infoStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @objc private func frameStackViewTapped(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else {
            assertionFailure("UITapGestureRecognizer view cannot be found...")
            return
        }
        view.animateView { [weak self] in
            guard let self else { return }
            eventPublisher.send(.frameSelected(.basic2x2))
        }
    }
    
}
