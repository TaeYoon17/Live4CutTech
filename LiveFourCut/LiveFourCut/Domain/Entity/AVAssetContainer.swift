//
//  AVAssetContainer.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import Foundation

struct AVAssetContainer: Identifiable, Equatable {
    var id: String // 여기 UUID로 바꿀 순 없나?
    let idx: Int
    let minDuration: Float
    let originalAssetURL: String
}
