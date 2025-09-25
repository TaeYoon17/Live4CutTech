//
//  FramePhotoSelectorCoordinator.swift
//  LiveFourCut
//
//  Created by Greem on 9/25/25.
//

import UIKit
import PhotosUI
// 어떤 프레임 선택하고 사진을 고르는 피쳐의 코디네이터
final class FramePhotoSelectorCoordinator: Coordinator {
    weak var delegate: CoordinatorDelegate?
    
    var childCoordinators: [Coordinator]
    var navigationController: UINavigationController
    
    @Dependency private var videoMakerFactory: VideoMakerFactoryProtocol
    private var alertPresenter: FrameSelectionAlertPresenter?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        self.childCoordinators = []
    }
    
    func start() {
        configureMainController()
    }
    
    func configureMainController() {
        let frameSelectionViewController = FrameSelectionViewController()
        frameSelectionViewController.coordinator = self
        self.alertPresenter = FrameSelectionAlertPresenter(viewController: frameSelectionViewController)
        navigationController
            .pushViewController(
                frameSelectionViewController,
                animated: true
            )
    }

}
extension FramePhotoSelectorCoordinator: FrameSelectonViewControllerDelegate {
    
    func pushPhotoSelectionViewController(frameType: FrameType) {
        let photoSelectionViewModel = PhotoSelectionViewModel(frameType: frameType)
        let photoSelectionViewController = PhotoSelectionViewController(viewModel: photoSelectionViewModel)
        photoSelectionViewController.coordinator = self
        navigationController.pushViewController(
            photoSelectionViewController,
            animated: true
        )
    }
    
    
    /// 권한 상태에 따른 알림창을 표시하는 메서드
    func showAlert(for status: AlbumAuthorization) {
        guard let alertInfo = status.alertInfo else { return }
        switch status.actionType {
        case .showSettingsAlert:
            self.alertPresenter?.presentSettingsAlert(
                title: alertInfo.title,
                message: alertInfo.message
            ) {
                guard let appSettings = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(appSettings)
            }
        case .showErrorAlert:
            self.alertPresenter?.presentErrorAlert(
                title: alertInfo.title,
                message: alertInfo.message
            )
        default: return
        }
    }
}

extension FramePhotoSelectorCoordinator: PhotoSelectonViewControllerDelegate {
    
    func pushPreViewController(
        minDuration: Double,
        frameType: FrameType,
        avAssetContainer: [AVAssetContainer]
    ) {
        let frameGenerator = switch frameType {
            case .basic2x2: Frame2x2Generator(width: 480, spacing: 8)
        }
        
        let videoMaker: VideoMakerProtocol = videoMakerFactory.makeVideoMaker(frameGenerator: frameGenerator)
        let coordinator = MediaCompositionCoordinator(
            navigationController: self.navigationController,
            minDuration: minDuration,
            frameType: frameType,
            videoMaker: videoMaker,
            avAssetContainer: avAssetContainer
        )
        coordinator.delegate = self
        self.addChildCoordinator(coordinator)
        coordinator.start()
    }
    
    func popPhotoSelectionViewController() {
        self.popViewController()
    }
    
    func showPhotoPicker(config: PHPickerConfiguration) {
        let phVC = PHPickerViewController(configuration: config)
        phVC.isModalInPresentation = true
        phVC.delegate = self
        self.navigationController.present(phVC, animated: true)
    }
}

extension FramePhotoSelectorCoordinator: CoordinatorDelegate {
    func didFinish(childCoordinator: Coordinator) {
        self.removeChildCoordinator(childCoordinator)
    }
}

extension FramePhotoSelectorCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
       viewModel.handlePickerResults(results: results)
    }
}
