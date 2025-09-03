//
//  FrameSelectionViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/14/24.
//

import UIKit
import Combine
import Photos

final class FrameSelectionViewController: UIViewController {
    // MARK: - Properties
    private let contentView: FrameSelectionView = .init()
    private var cancellable: Set<AnyCancellable> = []
    private lazy var alertPresenter = FrameSelectionAlertPresenter(viewController: self)
    
    
    private let checkPhotoAuthUseCase: CheckPhotoAuthUseCase = DefaultCheckPhotoAuthUseCase(
        photoAuthrepository: DefaultPhotoAuthorizationRepository()
    )
    private let requestPhotoAuthUseCase: RequestPhotoAuthUseCase = DefaultRequestPhotoAuthUseCase(
        photoAuthrepository: DefaultPhotoAuthorizationRepository()
    )
    
    override func loadView() {
        self.view = contentView
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.title = "프레임 선택"
        bindAction()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: -- View Bind Action
    func bindAction() {
        contentView.eventPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
            guard let self else { return }
            switch event {
            case .frameSelected(let frameType): frameStackViewTapped(frameType: frameType)
            }
        }.store(in: &cancellable)
    }
    
    // MARK: - Functions
    /// 프레임이 선택되었을 시 동작 함수
    private func frameStackViewTapped(frameType: FrameType) {
        Task { await handlePhotoAuthorization(frameType: frameType) }
    }
    
    /// 사진 권한을 처리하는 메서드
    private func handlePhotoAuthorization(frameType: FrameType) async {
        let currentStatus = checkPhotoAuthUseCase.execute()
        switch currentStatus.actionType {
        case .proceed:
            await MainActor.run { [weak self] in
                guard let self else { return }
                goToSelectPhotos(frameType: frameType)
            }
        case .requestPermission:
            let newStatus = await requestPhotoAuthUseCase.execute()
            switch newStatus.actionType {
            case .proceed:
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    goToSelectPhotos(frameType: frameType)
                }
            default: await showAlert(for: newStatus)
            }
        case .showSettingsAlert: await showAlert(for: currentStatus)
        case .showErrorAlert: await showAlert(for: currentStatus)
        }
    }
    
    /// 권한 상태에 따른 알림창을 표시하는 메서드
    private func showAlert(for status: AlbumAuthorization) async {
        guard let alertInfo = status.alertInfo else { return }
        switch status.actionType {
        case .showSettingsAlert:
            self.alertPresenter.presentSettingsAlert(
                title: alertInfo.title,
                message: alertInfo.message
            ) {
                guard let appSettings = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(appSettings)
            }
        case .showErrorAlert:
            self.alertPresenter.presentErrorAlert(
                title: alertInfo.title,
                message: alertInfo.message
            )
        default: return
        }
    }
    
    private func goToSelectPhotos(frameType: FrameType) {
        let photoSelectionViewController = PhotoSelectionViewController(
            viewModel: PhotoSelectionViewModel(frameType: frameType)
        )
        navigationController?.pushViewController(
            photoSelectionViewController,
            animated: true)
    }
}


