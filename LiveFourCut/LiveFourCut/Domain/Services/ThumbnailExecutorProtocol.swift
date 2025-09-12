//
//  ThumbnailExecutorProtocol.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation
import Combine
import Photos

protocol ThumbnailExecutorProtocol {
    var itemsSubject: PassthroughSubject<[ImageContainer], Never> { get }
    var progressSubject: PassthroughSubject<Float, Never>  { get }
    func setFetchResult(result: PHFetchResult<PHAsset>)
    func run()
}
