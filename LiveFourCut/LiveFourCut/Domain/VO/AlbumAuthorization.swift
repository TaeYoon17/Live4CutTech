//
//  AlbumAuthorization.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import Foundation
import UIKit

enum AlbumAuthorization {
    case enabled
    case userDenied
    case limitedAccess
    case notDetermined
    case restricted
    case unknown
}

// MARK: - AlbumAuthorization Extension
extension AlbumAuthorization {
    /// 권한 상태에 따른 액션 타입
    enum ActionType {
        case proceed           // 진행 가능
        case requestPermission // 권한 요청 필요
        case showSettingsAlert // 설정 화면으로 이동 필요
        case showErrorAlert    // 에러 알림 필요
    }
    
    /// 권한 상태에 따른 액션 타입을 반환
    var actionType: ActionType {
        switch self {
        case .enabled:
            return .proceed
        case .notDetermined:
            return .requestPermission
        case .userDenied, .limitedAccess:
            return .showSettingsAlert
        case .restricted, .unknown:
            return .showErrorAlert
        }
    }
    
    /// 알림창 정보를 반환
    var alertInfo: (title: String, message: String)? {
        switch self {
        case .enabled: return nil
        case .userDenied, .limitedAccess:
            return (
                title: "앨범 접근을 허용해주세요!",
                message: "[사진 > 전체 접근]을 허용해주세요"
            )
        case .restricted, .unknown:
            return (
                title: "현재 사용할 수 없습니다",
                message: "앨범 접근을 할 수 없어요\n 빠르게 수정해드리겠습니다!!"
            )
        case .notDetermined:
            return nil
        }
    }
}
