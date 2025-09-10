//
//  PhotoAuthorizationRepository.swift
//  LiveFourCut
//
//  Created by Greem on 9/3/25.
//

import Foundation
import Photos

protocol PhotoAuthorizationRepository {
    func checkCurrentStatus() -> AlbumAuthorization
    func requestAuthorization() async -> AlbumAuthorization
}

struct DefaultPhotoAuthorizationRepository: PhotoAuthorizationRepository {
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
