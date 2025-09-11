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
    private let viewModel: PhotoSelectionViewModel
    private lazy var contentView = PhotoSelectionView(thumbnailSelector: viewModel)
    private lazy var denyPagePresenter: DenyPagePresenter = DenyPagePresenter(
        viewController: self,
        frameType: viewModel.frameType
    )
    
    private var launchedView: Bool = false
    private var cancellable = Set<AnyCancellable>()
    
    init(viewModel: PhotoSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Don't use story Board!!")
    }
    
    override func loadView() { self.view = contentView }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        if !launchedView {
            launchedView.toggle()
            viewModel.openPhotoPicker()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindEvents()
        bindState()
        bindPhotoPickerEvents()
    }
    
    // MARK: -- View Bind Action
    private func bindEvents() {
        contentView.eventPublisher.sink { [weak self] event in
            guard let self else { return }
            switch event {
            case .navigationBack: navigationController?.popViewController(animated: true)
            case .selectDone:
                presentLoadingAlert(message: "라이브 포토 영상으로 변환 중...", cancelAction: {})
                viewModel.executeVideoFetch()
            case .openPicker: viewModel.openPhotoPicker()
            }
        }.store(in: &cancellable)
    }
    
    // MARK: -- View Bind State
    private func bindState() {
        viewModel.pickedImageContainerSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] containers in
                guard let self else { return }
                contentView.updateImageContainers(imageContainers: containers)
            }.store(in: &cancellable)
        
        viewModel.$pickedImageFetchProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] progressNumber in
                guard let self else {return}
                contentView.updateFetchProgress(progressNumber)
            }.store(in: &cancellable)
        
        viewModel.isPrintSelectionCompleted
            .receive(on: RunLoop.main)
            .sink { [weak self] isPrintSelectionCompleted in
                guard let self else { return }
                contentView.updateSelectionCompletionState(isPrintSelectionCompleted)
            }.store(in: &cancellable)
        
        viewModel.$videoLoadingProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                guard let self else { return }
                loadingProgressView?.progress = progress
            }.store(in: &cancellable)
        
        viewModel.videoAssetContinersSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] (container, minDuration) in
                guard let self else { return }
                dismissLoadingAlert { [weak self] in
                    guard let self else { return }
                    let vc = FourCutPreViewController(
                        minDuration: Double(minDuration),
                        frameType: viewModel.frameType,
                        extractService: ExtractService(),
                        videoMaker: VideoMaker(
                            memoryWarningService: MemoryWarningActor(),
                            frameService: Frame2x2Generator(width: 480, spacing: 8)
                        ), // 여기 값 전달이 좀 아쉽다...
                        avAssetContainers: container
                    )
                    navigationController?.pushViewController(vc, animated: true)
                }
            }.store(in: &cancellable)
    }
    
    private func bindPhotoPickerEvents() {
        viewModel.pickerEventSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] pickerAction in
                guard let self else { return }
                switch pickerAction {
                case .openPhotoPicker(let config):
                    let phVC = PHPickerViewController(configuration: config)
                    phVC.isModalInPresentation = true
                    phVC.delegate = self
                    self.present(phVC , animated: true)
                case .dismissOnly:
                    dismiss(animated: true)
                case .popViewController:
                    self.dismiss(animated: true) { [weak self] in
                        guard let self else { return }
                        self.navigationController?.popViewController(animated: true)
                    }
                case .processImages:
                    self.viewModel.resetSelectImage()
                    contentView.resetToImageProcessingState()
                    dismiss(animated: true)
                case .showDenyPage:
                    self.dismiss(animated: true) { [weak self] in
                        guard let self else { return }
                        denyPagePresenter.denyPagingOrder { [weak self] in
                            guard let self else { return }
                            navigationController?.popViewController(animated: true)
                        } reselectAction: { [weak self] in
                            guard let self else { return }
                            viewModel.openPhotoPicker()
                        }
                    }
                }
            }.store(in: &cancellable)
    }
}

extension PhotoSelectionViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        viewModel.handlePickerResults(results: results)
    }
}
