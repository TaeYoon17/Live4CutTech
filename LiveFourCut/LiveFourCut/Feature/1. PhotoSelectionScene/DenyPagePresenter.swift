//
//  DenyPagePresenter.swift
//  LiveFourCut
//
//  Created by Greem on 9/3/25.
//

import UIKit
import Photos

@MainActor struct DenyPagePresenter {
    private weak var viewController: UIViewController!
    private let frameType: FrameType
    
    init(
        viewController: UIViewController,
        frameType: FrameType
    ) {
        self.frameType = frameType
        self.viewController = viewController
    }
    
    func denyPagingOrder(backAction: @escaping () -> Void, reselectAction: @escaping () -> Void) {
        let denyMessage = PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited ? "접근 가능한 사진들을 선택했는지 확인 부탁드려요\n 전체 접근으로 권한 변경하는 것을 추천드려요" : nil
        
        let alertController = UIAlertController(
            title: "\(frameType.frameCount)장을 선택해주세요",
            message: denyMessage,
            preferredStyle: .alert
        )
        
        alertController.addAction(
            .init(
                title: "돌아가기",
                style: .cancel,
                handler: { _ in
                    backAction()
                })
        )
        
        alertController.addAction(
            .init(
                title: "다시 선택하기",
                style: .default,
                handler: { _ in
                    reselectAction()
                })
        )
        
        if(PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited) {
            alertController.addAction(.init(title: "전체 접근으로 권한 변경", style: .default,handler: { _ in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }))
        }
        viewController.present(alertController, animated: true)
    }
}
