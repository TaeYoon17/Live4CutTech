//
//  PhotoSelectionViewController.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import Foundation
import UIKit
import Combine
import Photos
import PhotosUI

final class PhotoSelectionViewController: LoadingVC {
    //MARK: -- View 저장 프로퍼티
    private lazy var contentView = PhotoSelectionView(viewModel: viewModel)
    private let viewModel: ThumbnailSelectorVM
    
    private let frameCount: Int
    
    private var isPagingEnabled = false // 다음 페이지로 넘어갈 수 있게 하는 토글러
    
    private var launchedView: Bool = false
    
    private let thumbnailExecutor = ThumbnailExecutor()
    private let videoExecutor = VideoExecutor()
    
    private var cancellable = Set<AnyCancellable>()
    init(
        viewModel: ThumbnailSelectorVM,
        frameCount: Int = 0
    ) {
        self.viewModel = viewModel
        self.frameCount = frameCount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Don't use story Board!!")
    }
    
    override func loadView() {
        self.view = contentView
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        if !launchedView {
            launchedView.toggle()
            openPickerVC()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindAction()
        Task {
            await thumbnailExecutor.thumbnailsSubject
                .receive(on: RunLoop.main)
                .sink {[weak self] containers in
                    guard let self else { return }
                    contentView.thumbnailSelectorView.imageContainers = containers
                }.store(in: &cancellable)
            
            viewModel.pagingAvailable
                .receive(on: RunLoop.main)
                .sink { [weak self] pagingAvailable in
                    guard let self else { return }
                    contentView.selectDoneBtn.isHidden = !pagingAvailable
                    contentView.thumbnailSelectorView.isHidden = pagingAvailable
                    contentView.reSelectPhotoBtn.isHidden = !pagingAvailable
                    isPagingEnabled = pagingAvailable
                }.store(in: &cancellable)
            
            await thumbnailExecutor.progressSubject.receive(on: RunLoop.main)
                .sink { [weak self] progressNumber in
                    guard let self else {return}
                    UIView.animate(withDuration: 0.2) {
                        if !self.contentView.pregress.isHidden && progressNumber == 1 {
                            self.contentView.pregress.isHidden = true
                        }else if self.contentView.pregress.isHidden && progressNumber != 1 {
                            self.contentView.pregress.isHidden = false
                        }
                        self.contentView.pregress.progress = progressNumber
                    }
                }.store(in: &cancellable)
            
            await videoExecutor.progressSubject.receive(on: RunLoop.main)
                .sink { [weak self] progressNumber in
                    self?.loadingProgressView?.progress = progressNumber
                }.store(in: &cancellable)
            
            await videoExecutor.videosSubject.sink { [weak self] avassetContainers in
                let orderIdentifiers = self?.viewModel.selectImageContainerSubject.value.compactMap({$0}).map(\.id)
                guard let orderIdentifiers, orderIdentifiers.count == self?.frameCount else {
                    assertionFailure("계수가 일치하지 않음!!")
                    return
                }
                var avassetContainers = avassetContainers
                let orderAssetContainers: [AVAssetContainer] = orderIdentifiers.map { identifier in
                    let firstIdx = avassetContainers.firstIndex(where: {$0.id == identifier})
                    return avassetContainers.remove(at: firstIdx!)
                }
                Task { @MainActor in
                        let min = await self!.videoExecutor.minDuration
                        self?.dismissLoadingAlert {
                            let vc = FourCutPreViewController()
                            vc.avAssetContainers = orderAssetContainers
                            vc.minDuration = min
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }.store(in: &cancellable)
        }
    }
    
    // MARK: -- View Bind Action
    func bindAction() {
        contentView.eventPublisher.sink { [weak self] event in
            guard let self else { return }
            switch event {
            case .navigationBack:
                navigationController?.popViewController(animated: true)
            case .selectDone:
                presentLoadingAlert(message: "라이브 포토 영상으로 변환 중...", cancelAction: {})
                Task{
                    await self.videoExecutor.run()
                }
            case .openPicker: openPickerVC()
            }
        }.store(in: &cancellable)
    }
    
    func openPickerVC() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .livePhotos
        config.selectionLimit = 4
        config.selection = .ordered
        let containerList = viewModel.selectImageContainerSubject.value
        config.preselectedAssetIdentifiers = containerList.compactMap({$0}).map(\.id)
        let phVC = PHPickerViewController(configuration: config)
        phVC.isModalInPresentation = true
        phVC.delegate = self
        self.present(phVC , animated: true)
    }
    
    func denyPagingOrder() {
        
        let denyMessage = PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited ? "접근 가능한 사진들을 선택했는지 확인 부탁드려요\n 전체 접근으로 권한 변경하는 것을 추천드려요" : nil
        
        let alertController = UIAlertController(title: "4장을 선택해주세요", message: denyMessage, preferredStyle: .alert)
        
        alertController.addAction(.init(title: "돌아가기", style: .cancel, handler: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }))
        
        alertController.addAction(.init(title: "다시 선택하기", style: .default, handler: {[weak self] _ in
            self?.openPickerVC()
        }))
        
        if(PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited) {
            alertController.addAction(.init(title: "전체 접근으로 권한 변경", style: .default,handler: { _ in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings)
                }
            }))
        }
        self.present(alertController, animated: true)
    }
    
}
extension PhotoSelectionViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        let identifiers = results.map(\.assetIdentifier).compactMap{ $0 }
        let assets: PHFetchResult<PHAsset> = PHAsset.fetchAssets(
            withLocalIdentifiers: identifiers,
            options: nil
        )
        
        let containerList = viewModel.selectImageContainerSubject.value
        if Set(identifiers) == Set(containerList.compactMap({$0}).map(\.id)) && identifiers.count == Constants.frameCount {
            self.dismiss(animated: true)
            return
        }
        
        if identifiers.count == Constants.frameCount {
            self.contentView.selectDoneBtn.isHidden = true
            self.contentView.reSelectPhotoBtn.isHidden = true
            self.contentView.pregress.isHidden = false
            self.contentView.thumbnailSelectorView.isHidden = false
            self.contentView.thumbnailSelectorView.reset()
            self.contentView.thumbnailFrameView.reset()
            self.viewModel.resetSelectImage()
        }
        
        self.dismiss(animated: true) { [weak self] in
            if assets.count == 0 && PHPhotoLibrary.authorizationStatus(for: .readWrite) == .authorized {
                if !(self?.isPagingEnabled ?? false) {
                    self?.navigationController?.popViewController(animated: true)
                }
            } else if assets.count == Constants.frameCount {
                Task{
                    await self?.thumbnailExecutor.setFetchResult(result:assets)
                    await self?.videoExecutor.setFetchResult(result: assets)
                    await self?.thumbnailExecutor.run()
                }
            } else {
                self?.denyPagingOrder()
            }
        }
    }
}
