//
//  VideoExecutor.swift
//  LiveFourCut
//
//  Created by Greem on 6/20/24.
//

import Foundation
import Combine
import Photos
import UIKit

enum VideoExecutorErrors: Error, Sendable {
    case failedSavedTempDirectory
    case fetchFailed
    
}
actor VideoExecutor {
    let videosSubject: PassthroughSubject<[AVAssetContainer],Never> = .init()
    let progressSubject:PassthroughSubject<Float,Never> = .init()
    private(set) var minDuration:Float = 1000
    private let videoManager: PHCachingImageManager = .init()
    private var result: PHFetchResult<PHAsset>!
    
    private var counter: Int = -1 {
        didSet{
            guard counter == 0 else { return }
            counter = -1
            Task {
                try await self.exportConvertedAssetContainers()
            }
        }
    }
    
    private var fetchItems:[AVAssetContainer] = []
    private var fetchAssets: [PHAssetResource] = [] {
        didSet {
            guard counter == fetchAssets.count else {return}
            let resultCount = fetchAssets.count
            
                for (idx,file) in fetchAssets.enumerated() {
                    let fileStrings = file.originalFilename.split(separator: ".").map{ String($0) }
                    let fileName = "\(fileStrings[0])\(idx).\(fileStrings[1])"
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                    if FileManager.default.fileExists(atPath:fileURL.path) {
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                    let option = PHAssetResourceRequestOptions()
                    option.isNetworkAccessAllowed = true
                    
                    Task{
                        try await PHAssetResourceManager.default().writeData(for: file, toFile: fileURL, options: option)
                        let urlAsset = AVURLAsset(url: fileURL)
                        let value:Float = (try? await Float(urlAsset.load(.duration).value)) ?? 1 // 여기 에러 처리 필요함
                        let timeScale: Float = (try? await Float(urlAsset.load(.duration).timescale)) ?? 1 // 여기 에러 처리 필요함
                        let secondsLength = value / timeScale
                        self.minDuration = min(secondsLength,self.minDuration)
                        let cnt = self.fetchItems.count
                        self.fetchItems.append(AVAssetContainer(id: file.assetLocalIdentifier,
                                                            idx: cnt, minDuration: 1000,
                                                            originalAssetURL: fileURL.absoluteString))
                    
                        self.counter -= 1
                        self.progressSubject.send(min(1, Float(resultCount - self.counter) / Float(2 * resultCount)))
                }
            }
        }
    }
    
    func setFetchResult(result: PHFetchResult<PHAsset>) async {
        self.result = result
    }
    func run() async {
        counter = result.count
        fetchItems.removeAll()
        self.minDuration = 1000
        self.progressSubject.send(0)
        
        result.enumerateObjects(options:.concurrent) { asset, idx, _ in
            let files = PHAssetResource.assetResources(for: asset).filter({$0.originalFilename.contains(".MOV")})
            guard let file = files.first else { return }
            self.fetchAssets.append(file)
        }
    }
    private func exportConvertedAssetContainers() async throws {
        var newAVssetContainers:[AVAssetContainer] = []
        let resultCount = fetchItems.count
        for (idx,item) in fetchItems.enumerated() {
            newAVssetContainers.append(AVAssetContainer(id: item.id, idx: item.idx, minDuration: self.minDuration, originalAssetURL: item.originalAssetURL))
            self.progressSubject.send(min(1,Float(idx) / Float(resultCount * 2) + 0.5))
        }
        self.fetchItems.removeAll()
        self.fetchAssets.removeAll()
        self.videosSubject.send(newAVssetContainers)
    }
    
}

extension VideoExecutor {
    nonisolated fileprivate func moveAssetDirToTempDir(urlAsset: inout AVURLAsset) async throws -> URL{
        let lastComponent = urlAsset.url.lastPathComponent
        let tempFileURL = FileManager().temporaryDirectory.appendingPathComponent(lastComponent)
        if FileManager.default.fileExists(atPath: tempFileURL.path()) {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        
        guard let exportSession = AVAssetExportSession(asset: urlAsset,
                                                       presetName: AVAssetExportPresetHighestQuality) else {
            throw VideoExecutorErrors.failedSavedTempDirectory
        }
        
        exportSession.outputURL = tempFileURL
        exportSession.outputFileType = .mov  // MP4 형식으로 저장
        if #available(iOS 18.0, *) {
            do {
                try await exportSession.export(to: tempFileURL, as: .mov)
            } catch {
                throw VideoExecutorErrors.failedSavedTempDirectory
            }
        } else {
            await exportSession.export()
            switch exportSession.status {
            case .cancelled,.completed: break
            case .unknown, .waiting, .exporting, .failed: throw VideoExecutorErrors.failedSavedTempDirectory
            @unknown default: throw VideoExecutorErrors.failedSavedTempDirectory
            }
        }
        return tempFileURL
    }
}

extension FileManager{
    func tempFileExist(fileName:String) async throws-> Bool{
        let newFileURL = self.temporaryDirectory.appendingPathComponent(fileName)
        return self.fileExists(atPath: newFileURL.absoluteString)
    }
}
