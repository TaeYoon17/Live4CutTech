//
//  UIDevice+.swift
//  LiveFourCut
//
//  Created by Greem on 9/7/25.
//

import UIKit

// 1. 메모리 등급을 나타내는 Enum 정의
enum MemoryClass {
    case low    // 6GB 이하
    case medium // 6GB 이상
    case high   // 8GB 이상
}

// 2. UIDevice 확장을 통해 메모리 등급을 반환하는 프로퍼티 추가
extension UIDevice {
    /// 기기의 RAM을 기반으로 메모리 등급을 반환합니다.
    var memoryClass: MemoryClass {
        let totalRAM = ProcessInfo.processInfo.physicalMemory
        if totalRAM >= 8_000_000_000 {       // 8GB 이상 (80억 바이트)
            return .high
        } else if totalRAM >= 6_000_000_000 { // 6GB 이상 (60억 바이트)
            return .medium
        } else {                           // 6GB 미만
            return .low
        }
    }
}
