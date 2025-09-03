//
//  PhotoPickerEvent.swift
//  LiveFourCut
//
//  Created by Greem on 9/3/25.
//

import Foundation
import PhotosUI

enum PhotoPickerEvent {
    case openPhotoPicker(PHPickerConfiguration)
    case dismissOnly
    case processImages
    case showDenyPage
    case popViewController
}
