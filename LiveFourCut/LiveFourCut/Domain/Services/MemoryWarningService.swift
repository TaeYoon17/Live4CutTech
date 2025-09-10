//
//  MemoryWarningService.swift
//  LiveFourCut
//
//  Created by Greem on 9/7/25.
//

import Foundation
import Combine
import UIKit


// 간단한 메모리 피크 감지
protocol MemoryWarningServiceProtocol {
    var isMemoryWarning: Bool { get async }
}

actor MemoryWarningActor: MemoryWarningServiceProtocol {
    var isMemoryWarning: Bool = false
    
    @MainActor
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    init() {
        setUp()
    }
    
    @MainActor func setUp() {
        NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }
                // Actor의 상태를 변경하기 위해 Task를 사용
                Task {
                    await self.setMemoryWarning(true)
                }
                
                // 1초 후 상태를 되돌리기 위해 Task를 사용
                Task {
                    try await Task.sleep(for: .seconds(1))
                    await self.setMemoryWarning(false)
                }
            }
            .store(in: &cancellables)
    }
    
    // Actor의 상태를 안전하게 변경하기 위한 메서드
    private func setMemoryWarning(_ value: Bool) {
        self.isMemoryWarning = value
    }
}
