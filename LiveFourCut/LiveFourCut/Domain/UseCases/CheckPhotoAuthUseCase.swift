//
//  CheckPhotoAuthUseCase.swift
//  LiveFourCut
//
//  Created by Greem on 9/3/25.
//

import Foundation

protocol CheckPhotoAuthUseCase {
    func execute() -> AlbumAuthorization
}

struct DefaultCheckPhotoAuthUseCase: CheckPhotoAuthUseCase {
    private let photoAuthrepository: PhotoAuthorizationRepository
    
    init(photoAuthrepository: PhotoAuthorizationRepository) {
        self.photoAuthrepository = photoAuthrepository
    }
    
    func execute() -> AlbumAuthorization {
        self.photoAuthrepository.checkCurrentStatus()
    }
}
