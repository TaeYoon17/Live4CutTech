//
//  RequestPhotoAuthUseCase.swift
//  LiveFourCut
//
//  Created by Greem on 9/3/25.
//

import Foundation

protocol RequestPhotoAuthUseCase {
    func execute() async -> AlbumAuthorization
}

struct DefaultRequestPhotoAuthUseCase: RequestPhotoAuthUseCase {
    
    private let photoAuthrepository: PhotoAuthorizationRepository
    
    init(photoAuthrepository: PhotoAuthorizationRepository) {
        self.photoAuthrepository = photoAuthrepository
    }
    
    func execute() async -> AlbumAuthorization {
        await photoAuthrepository.requestAuthorization()
    }
}
