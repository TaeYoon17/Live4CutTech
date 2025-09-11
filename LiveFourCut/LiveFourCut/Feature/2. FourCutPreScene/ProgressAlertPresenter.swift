//
//  ProgressAlertPresenter.swift
//  LiveFourCut
//
//  Created by Greem on 9/10/25.
//

import UIKit
import Combine

@MainActor
final class ProgressAlertPresenter {
    let cancelPublisher = PassthroughSubject<Void, Never>()
    private weak var viewController: UIViewController!
    private var progressView: UIProgressView = UIProgressView(progressViewStyle: .bar)
    private var progressAlert: UIAlertController!
    
    init(viewController: UIViewController!) {
        self.viewController = viewController
    }
    
    
    @MainActor
    func progressStart() {
        self.progressAlert = UIAlertController(title: "영상 제작 중...", message: "이미지 분할 중", preferredStyle: .alert)
        self.progressAlert.addAction(UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
            guard let self else { return }
            cancelPublisher.send(())
            self.progressWaitStop()
        })
        self.viewController.present(
            self.progressAlert,
            animated: true,
            completion: {
            let margin: CGFloat = 8.0 // 마진
            let rect = CGRect(x: margin, y: 72.0, width: self.progressAlert.view.frame.width - margin * 2.0 , height: 2.0) // 크기
            self.progressView = UIProgressView(frame: rect) // 프로그레스 생성
            self.progressView.progress = 0 // 초기 프로그레스 값
            self.progressView.tintColor = UIColor.tintColor // 프로그레스 색상
            self.progressAlert.view.addSubview(self.progressView) // alert에 추가 실시
        })
    }
    
    @MainActor
    func setProgress(_ progress: Double) {
        self.progressAlert.message = "이미지 합성 \(Int(progress * 100))%"
        self.progressView.progress = Float(progress)
    }
    
    @MainActor
    func progressWaitStop() {
        // [메인 큐에서 비동기 방식 실행 : UI 동작 실시]
        if self.progressAlert != nil {
            self.progressAlert.dismiss(animated: false, completion: nil) // 팝업창 지우기 실시
            self.progressAlert = nil // 초기값 지정
        }
    }
}
