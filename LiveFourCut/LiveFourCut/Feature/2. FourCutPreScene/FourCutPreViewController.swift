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
                        let alertController = UIAlertController(
                            title: "합성에 실패했습니다.",
                            message: "다시 시도해주세요.",
                            preferredStyle: .alert
                        )
                        alertController.addAction(
                            UIAlertAction(title: "OK", style: .default)
                        )
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
        
        assetInfoPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] (minDuration, avAssetContainers) in
            guard let self else { return }
            self.contentView.setUpPreView(
                minDuration: minDuration,
                avAssetContainers: avAssetContainers
            )
        }.store(in: &cancellables)
        
        assetInfoPublisher.sink { [weak self] (minDuration, avAssetContainers) in
            guard let self else { return }
            self.extractService.setUp(
                minDuration: minDuration,
                avAssetContainers: avAssetContainers
            )
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
                if Task.isCancelled { return }
                
                let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("LiveFourCut.mp4")
                if FileManager.default.fileExists(atPath: outputURL.path()){
                    try? FileManager.default.removeItem(at: outputURL)
                }
                
                try await Task.sleep(for: .milliseconds(10))
                
                for try await progressCount in try videoMaker.run(groupImage: &frameImages, outputURL: outputURL) {
                    if Task.isCancelled { return }
                    progress(progressCount)
                }
                if Task.isCancelled { return }
                completion(outputURL)
            } catch {
                failed(error)
            }
        }
    }
}


