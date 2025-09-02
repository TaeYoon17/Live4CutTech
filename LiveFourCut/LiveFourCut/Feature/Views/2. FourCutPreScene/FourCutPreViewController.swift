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
    let extractService = ExtractService()
    let frameService = FrameGenerator()
    //MARK: -- View 저장 프로퍼티
    private let contentView = FourCutPreView()
    
    var minDuration: Float = 0 {
        didSet {
            print("minDuration: \(minDuration)")
            contentView.preFourFrameView.minDuration = minDuration
            extractService.minDuration = Double(minDuration)
        }
    }
    
    var avAssetContainers: [AVAssetContainer]! {
        didSet {
            contentView.preFourFrameView.containers = avAssetContainers
            extractService.avAssetContainers = avAssetContainers
        }
    }
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.contentView.preFourFrameView.play()
        })
        
    }
    
    
    private func bindAction() {
        contentView.eventPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                guard let self else { return }
                switch event {
                case .navigationBack: navigationController?.popViewController(animated: true)
                case .shareStart: make()
                }
            }
            .store(in: &cancellables)
    }
    
    private func make() {
        self.view.isUserInteractionEnabled = false
        Task{ [weak self] in
            guard let self else { return }
            let interactionEnabled = {
                Task{ @MainActor in self.view.isUserInteractionEnabled = true }
            }
            self.extractService.minDuration = Double(self.minDuration)
            do {
                let prevTime = CFAbsoluteTimeGetCurrent()
                var frameImages = try await self.extractService.extractFrameImages()
                let nowTime = CFAbsoluteTimeGetCurrent()
                print("Extract time: ",(nowTime - prevTime) * 1000)
                var imgDatas:[CGImage] = try await self.frameService.groupReduce(groupImage: frameImages, spacing: 4)
                print("추출은 된다. \(frameImages.first?.count)")
                print("감소는 된다. \(imgDatas.count)")
                let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("LiveFourCut.mp4")
                if FileManager.default.fileExists(atPath: outputURL.path()){
                    try? FileManager.default.removeItem(at: outputURL)
                }
                frameImages = []
                try? await Task.sleep(for: .milliseconds(100))
                
                let videoCreator = VideoCreator(
                    videoSize: self.frameService.frameTargetSize,
                    outputURL: outputURL
                )
                
                videoCreator.createVideo(from: &imgDatas) { success, error in
                    if success {
                        DispatchQueue.main.async {
                            let sharingViewController = SharingViewController()
                            sharingViewController.videoURL = outputURL
                            self.navigationController?.isNavigationBarHidden = true
                            self.navigationController?.pushViewController(sharingViewController, animated: true)
                            _ = interactionEnabled()
                        }
                    } else {
                        _ = interactionEnabled()
                    }
                }
            }catch{
                _ = interactionEnabled()
            }
        }
    }
    
}
