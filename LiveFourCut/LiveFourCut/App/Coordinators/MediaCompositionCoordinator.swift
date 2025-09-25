//
//  MediaCompositionCoordinator.swift
//  LiveFourCut
//
//  Created by Greem on 9/25/25.
//

import UIKit

// 프레임과 사진을 선택한 것을 미리 보여주고, 실제로 합성한 뒤, 합성 화면을 보여주는 코디네이터
final class MediaCompositionCoordinator: NSObject, Coordinator {
    weak var delegate: CoordinatorDelegate?
    
    var childCoordinators: [Coordinator]
    
    var navigationController: UINavigationController
    
    private let minDuration: Double
    private let frameType: FrameType
    private let videoMaker: VideoMakerProtocol
    private let avAssetContainer: [AVAssetContainer]
    
    init(
        navigationController: UINavigationController,
        minDuration: Double,
        frameType: FrameType,
        videoMaker: VideoMakerProtocol,
        avAssetContainer: [AVAssetContainer]
    ) {
        self.navigationController = navigationController
        self.childCoordinators = []
        self.minDuration = minDuration
        self.frameType = frameType
        self.videoMaker = videoMaker
        self.avAssetContainer = avAssetContainer
    }
    
    func start() {
        let fourCutPreViewController = FourCutPreViewController(
            minDuration: minDuration,
            frameType: frameType,
            videoMaker: videoMaker,
            avAssetContainers: avAssetContainer
        )
        fourCutPreViewController.coordinator = self
        
        navigationController.pushViewController(
            fourCutPreViewController,
            animated: true
        )
    }
}

extension MediaCompositionCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              didShow viewController: UIViewController,
                              animated: Bool) {
        guard let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from) else { return }
        // 스와이프 취소가 아닌 실제 pop이 되었는지 확인
        // 만약 이번에 사라진(pop 된) 뷰 컨트롤러가 CutsPreViewController라면
        if !navigationController.viewControllers.contains(fromVC),
           fromVC is FourCutPreViewController {
            self.finish()
        }
    }
}

// MARK: -- CutsPreViewControllerDelegate
extension MediaCompositionCoordinator: CutsPreViewControllerDelegate {
    
    func pushSharingViewController(frameType: FrameType, videoURL: URL) {
        let sharingViewController = SharingViewController(
            frameType: frameType,
            videoURL: videoURL
        )
        
        sharingViewController.coordinator = self
        navigationController.pushViewController(
            sharingViewController,
            animated: true
        )
    }
    
    func popCutsPreViewController() {
        self.navigationController.popViewController(animated: true)
    }
}


// MARK: -- SharingViewControllerDelegate
extension MediaCompositionCoordinator: SharingViewControllerDelegate {
    func popSharingViewController() {
        self.popViewController()
    }
    
    func showShareActivity(url: URL) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        self.navigationController.present(activityViewController, animated: true)
    }
}
