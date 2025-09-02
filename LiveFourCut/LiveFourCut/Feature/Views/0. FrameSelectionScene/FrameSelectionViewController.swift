//
//  FrameSelectionViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/14/24.
//

import UIKit
import Combine
import Photos
import PhotosUI

final class FrameSelectionViewController: UIViewController {
    // MARK: - Properties
    private let contentView: FrameSelectionView = .init()
    private var nowPhotoAccessStatus: PHAuthorizationStatus!
    private var cancellable: Set<AnyCancellable> = []
    
    override func loadView() {
        self.view = contentView
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.title = "프레임 선택"
        self.setupPhotoKit()
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.nowPhotoAccessStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: -- View Bind Action
    func bindAction() {
        contentView.eventPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
            guard let self else { return }
            switch event {
            case .frameSelected(let frameType):
                frameStackViewTapped(frameType: frameType)
            }
        }.store(in: &cancellable)
    }
    
    // MARK: - Setup
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
    
    // MARK: - Functions
    /// 프레임에 추가할 새로운 Frame 생성하는 함수
    /// 프레임이 선택되었을 시 동작 함수
    private func frameStackViewTapped(frameType: FrameType) {
        guard let nowPhotoAccessStatus = self.nowPhotoAccessStatus else { return }
        switch nowPhotoAccessStatus {
        case .authorized: self.goToSelectPhotos()
        case .denied:
            let alertController = UIAlertController(
                title: "앨범 접근을 허용해주세요!",
                message: "[사진 > 전체 접근]을 허용해주세요",
                preferredStyle: .alert
            )
            alertController.addAction(.init(title: "확인", style: .default,handler: { [weak self] action in
                guard self != nil else { return }
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }))
            alertController.addAction(.init(title: "취소", style: .cancel))
            self.present(alertController, animated: true)
        case .limited:
            let alertController = UIAlertController(
                title: "앨범 접근을 허용해주세요!",
                message: "[사진 > 전체 접근]을 허용해주세요",
                preferredStyle: .alert
            )
            alertController.addAction(.init(title: "확인", style: .default,handler: { [weak self] action in
                guard self != nil else { return }
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }))
            alertController.addAction(.init(title: "취소", style: .cancel))
            self.present(alertController, animated: true)
        case .restricted, .notDetermined:
            let alertController = UIAlertController(title: "현재 사용할 수 없습니다", message: "앨범 접근을 할 수 없어요\n 빠르게 수정해드리겠습니다!!", preferredStyle: .alert)
            alertController.addAction(.init(title: "확인", style: .cancel))
            self.present(alertController, animated: true)
        @unknown default: break
        }
        
    }
    
    private func goToSelectPhotos() {
        let frameCount = Constants.frameCount
        let photoSelectionViewController = PhotoSelectionViewController(frameCount: frameCount)
        navigationController?.pushViewController(
            photoSelectionViewController,
            animated: true)
    }
}


