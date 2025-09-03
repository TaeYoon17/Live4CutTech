//
//  ThumbnailSelectorView.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import UIKit
import Combine

final class ThumbnailSelectorView: UIStackView {
    
    private var imageContainers: [ImageContainer] = []
    private lazy var imageViews: [ThumnailItem] = (0..<4).map { _ in ThumnailItem() }
    
    private weak var thumbnailSelector: ThumbnailSelectorProtocol!
    private var cancellable = Set<AnyCancellable>()
    
    init(thumbnailSelector: ThumbnailSelectorProtocol) {
        self.thumbnailSelector = thumbnailSelector
        super.init(frame: .zero)
        
        configureLayout()
        configureConstraints()
        configureView()
    }
    
    required init(coder: NSCoder) {
        fatalError("Don't use storyboard")
    }
    
    
    private func configureLayout() {
        imageViews.forEach { item in
            self.addArrangedSubview(item)
        }
    }
    
    private func configureConstraints() {
        self.distribution = .fillEqually
        self.alignment = .fill
        self.axis = .horizontal
        self.spacing = 10
        imageViews.forEach { item in
            item.clipsToBounds = true
            item.snp.makeConstraints { make in
                make.height.equalTo(item.snp.width).multipliedBy(1.3333)
            }
        }
    }
    
    private func configureView() {
        imageViews.forEach { $0.thumbnailSelector = thumbnailSelector }
        thumbnailSelector.selectedImageIndexes.sink { [weak self] selectedList in
            guard let self else { return }
            imageViews.enumerated().forEach { ele in
                ele.element.setSelect(selectedList[ele.offset])
            }
        }.store(in: &cancellable)
    }
    
    
    func reset() {
        imageViews.forEach { item in
            item.imageContainer = nil
            item.setSelect(false)
        }
    }
    
    func setImageContainers(imageContainers: [ImageContainer]) {
        self.imageContainers = imageContainers
        guard imageContainers.count == 4 else { return }
        imageViews.enumerated().forEach {
            $0.element.imageContainer = imageContainers[$0.offset]
        }
    }
}

extension ThumbnailSelectorView {
    final class ThumnailItem: UIView {
        weak var thumbnailSelector: ThumbnailSelectorProtocol!
        var imageContainer: ImageContainer! {
            didSet {
                guard let imageContainer else {
                    self.imageView.image = nil
                    return
                }
                imageView.image = imageContainer.image
            }
        }
        
        private let imageView = UIImageView()
        private var maskLayer:CALayer?
        private let label = UILabel()
        private var labelText: String = ""
        var isSelected: Bool = false
        
        init() {
            super.init(frame: .zero)
            imageView.contentMode = .scaleAspectFit
            self.layer.cornerRadius = 10
            self.contentMode = .scaleAspectFill // 이미지가 상하or좌우에 꽉 차도록 설정
            self.clipsToBounds = true // 벗어나는 범위는 자름
            [imageView,label].forEach({addSubview($0)})
            imageView.snp.makeConstraints({$0.edges.equalToSuperview()})
            label.snp.makeConstraints({$0.center.equalToSuperview()})
            label.font = .systemFont(ofSize: 18, weight: .heavy)
            label.textColor = .white
            self.isUserInteractionEnabled = true
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(Self.itemTapped(sender:))))
        }
        required init?(coder: NSCoder) {
            fatalError("Don't use storyboard")
        }
        func appendMask() {
            guard self.maskLayer == nil else {return}
            self.label.isHidden = false
            self.label.text = self.labelText
            let layer = CALayer()
            layer.backgroundColor = UIColor.white.withAlphaComponent(0.333).cgColor
            layer.frame = self.bounds
            layer.cornerRadius = 10
            self.layer.addSublayer(layer)
            self.maskLayer = layer
        }
        func removeMask() {
            self.label.isHidden = true
            self.maskLayer?.removeFromSuperlayer()
            self.maskLayer = nil
        }
        @objc func itemTapped(sender: UITapGestureRecognizer) {
            if isSelected {
                thumbnailSelector.removeSelectImage(containerID: imageContainer.id)
                self.isSelected = false
            } else {
                let frameIdx = thumbnailSelector.appendSelectImage(container: imageContainer)
                self.labelText = "\(frameIdx + 1)"
                self.label.text = self.labelText
                self.isSelected = true
            }
        }
        
        func setSelect(_ select:Bool) {
            let selectAction = select ? appendMask : removeMask
            selectAction()
            self.isSelected = select
        }
    }
}
