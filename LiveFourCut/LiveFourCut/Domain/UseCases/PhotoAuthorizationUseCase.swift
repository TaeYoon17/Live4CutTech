//
//  PhotoAuthorizationUseCase.swift
//  LiveFourCut
//
//  Created by Greem on 9/2/25.
//

import Foundation
import Photos

/// 사진 권한 관련 UseCase

protocol PhotoAuthorizationUseCase {
    /// 현재 권한 상태를 확인합니다
    func checkCurrentStatus() -> AlbumAuthorization
    
    /// 권한을 요청하고 결과를 반환합니다
    func requestAuthorization() async -> AlbumAuthorization
}

struct DefaultPhotoAuthorizationUseCase: PhotoAuthorizationUseCase {
    
    func checkCurrentStatus() -> AlbumAuthorization {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status.toAlbumAuthorization()
    }
    
    func requestAuthorization() async -> AlbumAuthorization {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status.toAlbumAuthorization()
    }
}

// MARK: - PHAuthorizationStatus Extension
private extension PHAuthorizationStatus {
    func toAlbumAuthorization() -> AlbumAuthorization {
        switch self {
        case .authorized:
            return .enabled
        case .denied:
            return .userDenied
        case .limited:
            return .limitedAccess
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .unknown
        }
    }
}
