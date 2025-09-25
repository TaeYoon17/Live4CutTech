//
//  Coordinator.swift
//  LiveFourCut
//
//  Created by Greem on 9/16/25.
//

import UIKit

@MainActor
protocol Coordinator: AnyObject {
    var delegate: CoordinatorDelegate? { get set }
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
    func finish()
    func popViewController()
    func dismissViewController()
}

@MainActor extension Coordinator {
    func finish() {
        childCoordinators.removeAll()
        delegate?.didFinish(childCoordinator: self)
    }
    
    func popViewController() {
        navigationController.popViewController(animated: true)
    }
    
    func dismissViewController() {
        navigationController.dismiss(animated: true)
    }
}

extension Coordinator {
    func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators = childCoordinators.filter { $0 !== coordinator }
    }
}

@MainActor
protocol CoordinatorDelegate: AnyObject {
    func didFinish(childCoordinator: Coordinator)
}
// 가져야할 코디네이터
// 1. 프레임을 선택하고 그 프레임 이미지를 선택하는 코디네이터
// 2. 외부에서 선택한 프레임과 이미지들을 기반으로 미리보기 씬을 보여주고 합성 작업을 진행, 완료하는 코디네이터





