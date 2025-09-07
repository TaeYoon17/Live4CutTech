//
//  FourCutPreviewController.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import UIKit
import Combine
import CoreMedia

final class FourCutPreViewController: BaseVC {
    // MARK: -- Service 연결
    let extractService: ExtractService
    let videoMaker: VideMakerProtocol
    
    //MARK: -- View 저장 프로퍼티
    private lazy var contentView = FourCutPreView()
    private lazy var progressAlertPresenter = ProgressAlertPresenter(viewController: self)
    
    @Published private var minDuration: Double
    @Published private var avAssetContainers: [AVAssetContainer]
    @Published private var frameType: FrameType
    private var cancellables = Set<AnyCancellable>()
    private var makingVideoTask: Task<Void, Never>?
    init(
        minDuration: Double,
        frameType: FrameType,
        extractService: ExtractService,
        videoMaker: VideMakerProtocol,
        avAssetContainers: [AVAssetContainer]
    ) {
        self.extractService = extractService
        self.videoMaker = videoMaker
        self.minDuration = minDuration
        self.avAssetContainers = avAssetContainers
        self.frameType = frameType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        bindState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {
            try await Task.sleep(for: .seconds(0.1))
            await MainActor.run { [weak self] in
                guard let self else { return }
                contentView.playPreView()
            }
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    
    private func bindAction() {
        progressAlertPresenter.cancelPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }
                makingVideoTask?.cancel()
                self.view.isUserInteractionEnabled = true
            }.store(in: &cancellables)
        
        contentView.eventPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .navigationBack: navigationController?.popViewController(animated: true)
                case .shareStart:
                    makingVideo { [weak self] in
                        guard let self else { return }
                        self.view.isUserInteractionEnabled = false
                        progressAlertPresenter.progressStart()
                    } progress: { [weak self] progress in
                        guard let self else { return }
                        progressAlertPresenter.setProgress(progress)
                    } completion: { [weak self] outputURL in
                        guard let self else { return }
                        self.view.isUserInteractionEnabled = true
                        progressAlertPresenter.progressWaitStop()
                        let sharingViewController = SharingViewController()
                        sharingViewController.videoURL = outputURL
                        self.navigationController?.isNavigationBarHidden = true
                        self.navigationController?.pushViewController(sharingViewController, animated: true)
                    } failed: { [weak self] error in
                        guard let self else { return }
                        self.view.isUserInteractionEnabled = true
                        progressAlertPresenter.progressWaitStop()
                        let alertController = UIAlertController(title: "합성에 실패했습니다.", message: "다시 시도해주세요.", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alertController, animated: true)
                    }
                }
            }.store(in: &cancellables)
    }
    
    private func bindState() {
        let assetInfoPublisher = $minDuration
            .combineLatest($avAssetContainers)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            }
        
        assetInfoPublisher.receive(on: RunLoop.main).sink { [weak self] (minDuration, avAssetContainers) in
            guard let self else { return }
            self.contentView.setUpPreView(minDuration: minDuration, avAssetContainers: avAssetContainers)
        }.store(in: &cancellables)
        assetInfoPublisher.sink { [weak self] (minDuration, avAssetContainers) in
            guard let self else { return }
            self.extractService.setUp(minDuration: minDuration, avAssetContainers: avAssetContainers)
        }.store(in: &cancellables)
    }
    
    private func makingVideo(
        onStart: @MainActor @escaping () -> Void,
        progress: @MainActor @escaping (Double) -> Void,
        completion: @MainActor @escaping (URL) -> Void,
        failed: @MainActor @escaping (Error) -> Void
    ) {
        onStart()
        makingVideoTask?.cancel()
        makingVideoTask = Task {
            do {
                var frameImages: [[CGImage]] = try await self.extractService.extractFrameImages() // [4 * frameCount]
                
                if Task.isCancelled {
                    return
                }
                let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("LiveFourCut.mp4")
                if FileManager.default.fileExists(atPath: outputURL.path()){
                    try? FileManager.default.removeItem(at: outputURL)
                }
                try await Task.sleep(for: .milliseconds(10))
                
                for try await progressCount in try videoMaker.run(groupImage: &frameImages, outputURL: outputURL) {
                    if Task.isCancelled {
                        return
                    }
                    progress(progressCount)
                }
                if Task.isCancelled {
                    return
                }
                completion(outputURL)
            } catch {
                failed(error)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("메모리 터진다...")
    }
}

fileprivate final class ProgressAlertPresenter {
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
        self.viewController.present(self.progressAlert, animated: true, completion: {
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
