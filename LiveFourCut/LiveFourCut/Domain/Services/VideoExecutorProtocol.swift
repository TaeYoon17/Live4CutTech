//
//  VideoExecutorProtocol.swift
//  LiveFourCut
//
//  Created by Greem on 9/12/25.
//

import Foundation
import Photos

protocol VideoExecutorProtocol: AnyObject, Sendable {
    /// 결과 반환
    var executeStream: AsyncThrowingStream<VideoExecutorState, Error> { get async }
    
    /// PHAsset 설정
    func setFetchResult(result: PHFetchResult<PHAsset>) async
    
    /// 재생
    func run() async
}
