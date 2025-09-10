//
//  FrameSelectionAlertPresenter.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import UIKit

@MainActor
struct FrameSelectionAlertPresenter {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    @MainActor func presentSettingsAlert(title: String, message: String, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in onConfirm() })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        viewController?.present(alert, animated: true)
    }
    
    @MainActor func presentErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel))
        viewController?.present(alert, animated: true)
    }
}
