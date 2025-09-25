//
//  SceneDelegate.swift
//  LiveFourCut
//
//  Created by 윤동주 on 6/14/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var framePhotoSelectorCoordinator: FramePhotoSelectorCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)

        let navigationController = UINavigationController()
        
        let framePhotoSelectorCoordinator = FramePhotoSelectorCoordinator(navigationController: navigationController)
        framePhotoSelectorCoordinator.start()
        self.framePhotoSelectorCoordinator = framePhotoSelectorCoordinator

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}

