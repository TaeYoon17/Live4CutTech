//
//  MemoryWarningService.swift
//  LiveFourCut
//
//  Created by Greem on 9/7/25.
//

import Foundation
import Combine
import UIKit

// 간단한 메모리 피크 감지 - Core에 두는게 좋을 듯...
protocol MemoryWarningProtocol: Sendable {
    var isMemoryWarning: Bool { get async }
}

actor MemoryWarningActor: MemoryWarningProtocol {
    var isMemoryWarning: Bool = false
    
    @MainActor
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    init(releaseSeconds: Double = 1.0) {
        setUp()
    }
    
    @MainActor func setUp(releaseSeconds: Double = 1.0) {
        NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                
                Task {
                    await self.setMemoryWarning(true)
                }
                
                // 1초 후 상태를 되돌리기 위해 Task를 사용
                Task {
                    try await Task.sleep(for: .seconds(releaseSeconds))
                    await self.setMemoryWarning(false)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setMemoryWarning(_ value: Bool) {
        self.isMemoryWarning = value
    }
}
