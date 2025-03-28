//
//  ViewExtensions.swift
//  LiveFourCut
//
//  Created by Greem on 3/28/25.
//

import UIKit

/// 버튼 클릭 시 줄어드는 동작 함수
/// Button으로 덮지 않고 animation 효과를 반영
extension UIView {
    func animateView(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = CGAffineTransform.identity
            } completion: { _ in
                completion()
            }
        })
    }
}
