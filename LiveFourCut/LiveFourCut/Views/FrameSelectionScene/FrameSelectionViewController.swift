//
//  FrameSelectionViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/14/24.
//

import UIKit
import SnapKit

class FrameSelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 프레임 선택 title
    let frameLabel: UILabel = {
        var label = UILabel()
        
        label.text = "이미지 선택"
        label.font = .systemFont(ofSize: 30, weight: .bold)
        
        return label
    }()
    let descLabel: UILabel = {
        let label = UILabel()
        label.text = "라이브로 찍은 이미지를 골라주세요!"
        label.font = .systemFont(ofSize: 20,weight: .regular)
        return label
    }()
    
    lazy var outerFrameView:UIView = {
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
        stackView.addArrangedSubview(infoImageVIew)
        stackView.addArrangedSubview(infoLabel)
        return stackView
    }()
    
    private var infoImageVIew: UIImageView = {
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
    
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.title = "프레임 선택"
        
        let fourFrameTapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(frameStackViewTapped(_:))
        )
        
        outerFrameView.addGestureRecognizer(fourFrameTapGesture)
        self.setupUI()
        self.setupConstraints()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Setup
    
    private func setupUI(){
        [frameLabel, descLabel, outerFrameView].forEach { self.view.addSubview($0) }
        outerFrameView.addSubview(infoStackView)
    }
    
    private func setupConstraints() {
        frameLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(38)
            $0.centerX.equalToSuperview()
        }
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(frameLabel.snp.bottom).offset(11)
            make.centerX.equalToSuperview()
        }
        outerFrameView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(50)
            make.centerY.equalTo(self.view.snp.centerY).offset(55)
            make.height.equalTo(outerFrameView.snp.width).multipliedBy(1.77)
        }
        infoStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    // MARK: - Functions
    
    /// 프레임에 추가할 새로운 Frame 생성하는 함수
    
    
    /// 버튼 클릭 시 줄어드는 동작 함수
    /// Button으로 덮지 않고 animation 효과를 반영
    private func animateView(_ view: UIView, completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = CGAffineTransform.identity
            } completion: { _ in
                completion()
            }
        })
    }
    
    /// 프레임이 선택되었을 시 동작 함수
    @objc private func frameStackViewTapped(_ sender: UITapGestureRecognizer) {
        var frameCount = 0
        frameCount = 4
        animateView(sender.view!) {
            print("4 Frame Stack View Tapped")
            let photoSelectionViewController = PhotoSelectionViewController()
            photoSelectionViewController.frameCount = frameCount
            self.navigationController?.pushViewController(
                photoSelectionViewController,
                animated: true)
        }
    }
}

