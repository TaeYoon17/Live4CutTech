//
//  FrameSelectionViewController.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/14/24.
//

import UIKit
import Combine
import Photos

@MainActor
protocol FrameSelectonViewControllerDelegate: AnyObject, Coordinator {
    func pushPhotoSelectionViewController(frameType: FrameType)
    func showAlert(for status: AlbumAuthorization)
}

final class FrameSelectionViewController: UIViewController {
    weak var coordinator: FrameSelectonViewControllerDelegate?
    
    // MARK: - Properties
    private let contentView = FrameSelectionView()
    
    @Dependency private var checkPhotoAuthUseCase: CheckPhotoAuthUseCase
    @Dependency private var requestPhotoAuthUseCase: RequestPhotoAuthUseCase
    
    private var cancellable: Set<AnyCancellable> = []
    
    // MARK: - Life Cycle
    override func loadView() {
        self.view = contentView
    }
    
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
            case .frameSelected(let frameType):
                frameStackViewTapped(frameType: frameType)
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
            default: coordinator?.showAlert(for: newStatus)
            }
        case .showSettingsAlert:
            coordinator?.showAlert(for: currentStatus)
        case .showErrorAlert: coordinator?.showAlert(for: currentStatus)
        }
    }
    
    
    private func goToSelectPhotos(frameType: FrameType) {
        coordinator?.pushPhotoSelectionViewController(frameType: frameType)
    }
}
