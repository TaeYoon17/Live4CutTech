//
//  TempTestVC.swift
//  LiveFourCut
//
//  Created by Greem on 9/5/25.
//

import Foundation
import UIKit
import Combine
import Photos


/*
final class TempVC: UIViewController {
    let mockVideoExecutor = MockVideoExecutor()
    let extractService: ExtractService = .init()
//    let frameService: FrameGenerator = .init()
    
    var receivedAssets: [AVAssetContainer] = []
    let firstBtn = UIButton()
    let firstResultLabel = UILabel()
    let secondBtn = UIButton()
    let secondResultLabel = UILabel()
    let thridBtn = UIButton()
    let thridResultLabel = UILabel()
    let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        // 첫 번째 버튼 설정
        self.firstBtn.setTitle("첫번째", for: .normal)
        self.firstBtn.setTitleColor(.white, for: .normal)
        self.firstBtn.backgroundColor = .systemBlue
        self.firstBtn.layer.cornerRadius = 8
        
        // 두 번째 버튼 설정
        self.secondBtn.setTitle("두번째", for: .normal)
        self.secondBtn.setTitleColor(.white, for: .normal)
        self.secondBtn.backgroundColor = .systemGreen
        self.secondBtn.layer.cornerRadius = 8
        
        self.thridBtn.setTitle("세번째", for: .normal)
        self.thridBtn.setTitleColor(.white, for: .normal)
        self.thridBtn.backgroundColor = .systemRed
        self.thridBtn.layer.cornerRadius = 8
        
        // 라벨 설정
        self.firstResultLabel.text = "첫번째 결과"
        self.firstResultLabel.textAlignment = .center
        self.firstResultLabel.textColor = .label
        
        self.secondResultLabel.text = "두번째 결과"
        self.secondResultLabel.textAlignment = .center
        self.secondResultLabel.textColor = .label
        
        self.thridResultLabel.text = "세번째 결과"
        self.thridResultLabel.textAlignment = .center
        self.thridResultLabel.textColor = .label
        
        [firstBtn, firstResultLabel, secondBtn, secondResultLabel, thridBtn, thridResultLabel].forEach {
            self.stackView.addArrangedSubview($0)
        }
        
        // 버튼 높이 설정
        firstBtn.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        secondBtn.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        thridBtn.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        stackView.snp.makeConstraints { make in
            make.verticalEdges.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.distribution = .fillEqually
        Task {
            await gogogo()
        }
        firstBtn.addTarget(self, action: #selector(onFirstBtnTapped), for: .touchUpInside)
        secondBtn.addTarget(self, action: #selector(onSecondBtnTapped), for: .touchUpInside)
        thridBtn.addTarget(self, action: #selector(onThirdBtnTapped), for: .touchUpInside)
    }
    
    func gogogo() async {
        
        // 비동기적으로 결과를 받기 위한 expectation
        
        let cancellable = mockVideoExecutor.itemsSubject.sink {[weak self] assets in
            self?.receivedAssets = assets
        }
        
        await mockVideoExecutor.run()
        
        // 잠시 기다려서 비동기 작업이 완료되도록 함
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
        cancellable.cancel()
        extractService.setUp(
            minDuration: Double(
                mockVideoExecutor.minDuration
            ),
            avAssetContainers: receivedAssets
        )
    }
    
    func extractImages() async throws -> [[CGImage]] {
        var images = try await extractService.extractFrameImages()
        for i in 0..<images.count {
            let now = images[i]
            for j in 0..<20 {
                images[i] += now
            }
        }
        print("이미지 프레임 계수: \(images[0].count)")
        return images
    }
    
    @objc func onFirstBtnTapped() {
        firstResultLabel.text = "첫번째 버튼 실행 중..."
        Task {
            do {
                
                var images = try await extractImages()
                let startTime = CFAbsoluteTimeGetCurrent()
                let urls = try await self.frameService.groupReduceAndSaveToURL(
                    groupImage: &images,
                    spacing: 4,
                    workBatchCount: 2
                )
                let endTime = CFAbsoluteTimeGetCurrent()
                let tempDir = FileManager.default.temporaryDirectory
                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                    for file in contents where file.pathExtension == "jpeg" {
                        try FileManager.default.removeItem(at: file)
                    }
                } catch {
                    print("삭제 실패: \(error)")
                }
                let totalEnd = CFAbsoluteTimeGetCurrent()
                await MainActor.run {
                    firstResultLabel.text = "첫번째 완료: \(urls.count)개 URL 생성, \(endTime - startTime)초 \n 총 시간 \(totalEnd - startTime)초)"
                }
            } catch {
                await MainActor.run {
                    firstResultLabel.text = "첫번째 오류: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @objc func onSecondBtnTapped() {
        secondResultLabel.text = "두번째 버튼 실행 중..."
        Task {
            do {
                
                var images = try await extractImages()
                let startTime = CFAbsoluteTimeGetCurrent()
                let urls = try await self.frameService.groupReduceAndSaveToURL(
                    groupImage: &images,
                    spacing: 4,
                    workBatchCount: 1
                )
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let tempDir = FileManager.default.temporaryDirectory

                do {
                    let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                    for file in contents where file.pathExtension == "jpeg" {
                        try FileManager.default.removeItem(at: file)
                    }
                } catch {
                    print("삭제 실패: \(error)")
                }
                let totalEnd = CFAbsoluteTimeGetCurrent()
                await MainActor.run {
                    secondResultLabel.text = "두번째 완료: \(urls.count)개 URL 생성, \(endTime - startTime)초 \n 총 시간 \(totalEnd - startTime)초)"
                }
            } catch {
                await MainActor.run {
                    secondResultLabel.text = "두번째 오류: \(error.localizedDescription)"
                }
            }
        }
    }
    @objc func onThirdBtnTapped() {
        thridResultLabel.text = "세번째 버튼 실행 중..."
        Task {
            do {
                var images = try await extractImages()
                let startTime = CFAbsoluteTimeGetCurrent()
//                let cutsImages = try await frameService.groupReduce(groupImage: &images, spacing: 4)
                let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("LiveFourCut.mov")
                print(outputURL)
                if FileManager.default.fileExists(atPath: outputURL.path()){
                    try? FileManager.default.removeItem(at: outputURL)
                }
                
                
                try await frameService.makeAndVideo(
                    groupImage: &images,
                    spacing: 4,
                    outputURL: outputURL
                )
                await MainActor.run {
                    let sharingViewController = SharingViewController()
                    sharingViewController.videoURL = outputURL
                    self.navigationController?.isNavigationBarHidden = true
                    self.navigationController?.pushViewController(sharingViewController, animated: true)
                }
//                try? await Task.sleep(for: .milliseconds(100))
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let totalEnd = CFAbsoluteTimeGetCurrent()
                await MainActor.run {
                    thridResultLabel.text = "세번째 완료: 개 URL 생성, \(endTime - startTime)초 \n 총 시간 \(totalEnd - startTime)초)"
                }
            } catch {
                await MainActor.run {
                    thridResultLabel.text = "세번째 오류: \(error.localizedDescription)"
                }
            }
        }
    }
}
*/


