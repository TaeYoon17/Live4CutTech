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

final actor MemoryWarningActor: MemoryWarningProtocol {
    var isMemoryWarning: Bool = false
    
    init(releaseSeconds: Double = 1.0) {
        Task {
            for await _ in NotificationCenter.default.notifications(named: UIApplication.didReceiveMemoryWarningNotification)  {
                await self.setMemoryWarning(true)
                try await Task.sleep(for: .seconds(releaseSeconds))
                await self.setMemoryWarning(false)
            }
        }
    }
    
    private func setMemoryWarning(_ value: Bool) {
        self.isMemoryWarning = value
    }
}



        
