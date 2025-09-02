//
//  FrameSelectionViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/14/24.
//

import UIKit
import SnapKit
import Photos
import PhotosUI



final class FrameSelectionViewController: UIViewController {
    // MARK: - Properties
    /// 프레임 선택 title
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
    
    private var nowPhotoAccessStatus: PHAuthorizationStatus!
    
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
        self.setupPhotoKit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.nowPhotoAccessStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: - Setup
    
    private func setupUI(){
        [frameLabel, descLabel, outerFrameView].forEach { self.view.addSubview($0) }
        outerFrameView.addSubview(infoStackView)
    }
    
    private func setupPhotoKit() {
        self.nowPhotoAccessStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch self.nowPhotoAccessStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                self?.nowPhotoAccessStatus = status
            }
        default: break
        }
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
    /// 프레임이 선택되었을 시 동작 함수
    @objc private func frameStackViewTapped(_ sender: UITapGestureRecognizer) {
        guard let nowPhotoAccessStatus = self.nowPhotoAccessStatus else {return}
        switch nowPhotoAccessStatus {
        case .authorized: self.goToSelectPhotos(sender)
        case .denied:
            let alertController = UIAlertController(title: "앨범 접근을 허용해주세요!", message: "[사진 > 전체 접근]을 허용해주세요", preferredStyle: .alert)
            alertController.addAction(.init(title: "확인", style: .default,handler: { [weak self] action in
                guard self != nil else { return }
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }))
            alertController.addAction(.init(title: "취소", style: .cancel))
            self.present(alertController, animated: true)
        case .limited: self.goToSelectPhotos(sender)
        case .restricted, .notDetermined:
            let alertController = UIAlertController(title: "현재 사용할 수 없습니다", message: "앨범 접근을 할 수 없어요\n 빠르게 수정해드리겠습니다!!", preferredStyle: .alert)
            alertController.addAction(.init(title: "확인", style: .cancel))
            self.present(alertController, animated: true)
        @unknown default: break
        }
        
    }
    
    private func goToSelectPhotos(_ sender: UITapGestureRecognizer) {
        var frameCount = 0
        frameCount = 4
        sender.view?.animateView {[weak self] in
            let photoSelectionViewController = PhotoSelectionViewController()
            photoSelectionViewController.frameCount = frameCount
            self?.navigationController?.pushViewController(
                photoSelectionViewController,
                animated: true)
        }
    }
}


