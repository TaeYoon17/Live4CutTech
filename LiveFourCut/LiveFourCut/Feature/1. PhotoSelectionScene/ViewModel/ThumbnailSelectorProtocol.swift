//
//  ThumbnailSelectorProtocol.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation
import UIKit
import Combine
import PhotosUI

protocol ThumbnailSelectorProtocol: AnyObject {
    var selectImageContainerSubject: CurrentValueSubject<[ImageContainer?],Never> { get }
    var selectedImageIndexes: AnyPublisher<[Bool], Never> { get }
    var frameType: FrameType { get }
    func appendSelectImage(container: ImageContainer) -> Int
    func removeSelectImage(idx: Int)
    func removeSelectImage(containerID: ImageContainer.ID)
    func resetSelectImage()
}

extension ThumbnailSelectorProtocol {
    @discardableResult
    func appendSelectImage(container: ImageContainer) -> Int {
        var currentSubjectValue = self.selectImageContainerSubject.value
        // 현재 비어있는 것 중 가장 맨 앞의 Index를 찾음
        let firstIdx = currentSubjectValue.firstIndex(where: { $0 == nil } ).map { Int($0) }!
        currentSubjectValue[firstIdx] = container
        selectImageContainerSubject.send(currentSubjectValue)
        return firstIdx
    }
    
    func removeSelectImage(idx: Int) {
        var currentSubjectValue = self.selectImageContainerSubject.value
        let firstIdx = currentSubjectValue.firstIndex(where: {$0?.idx == idx}).map { Int($0) }!
        currentSubjectValue[firstIdx] = nil
        selectImageContainerSubject.send(currentSubjectValue)
    }
    
    func removeSelectImage(containerID: ImageContainer.ID) {
        var currentSubjectValue = self.selectImageContainerSubject.value
        let firstIdx = currentSubjectValue.firstIndex(where: {$0?.id == containerID}).map { Int($0) }!
        currentSubjectValue[firstIdx] = nil
        selectImageContainerSubject.send(currentSubjectValue)
    }
    
    func resetSelectImage() {
        selectImageContainerSubject.send((0..<frameType.frameCount).map { _ in nil })
    }
}
