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
enum VideoExecutorErrors: Error, Sendable{
    case failedSavedTempDirectory
    case fetchFailed
    
}
actor VideoExecutor{
    let videosSubject: PassthroughSubject<[AVAssetContainer],Never> = .init()
    let progressSubject:PassthroughSubject<Float,Never> = .init()
    private(set) var minDuration:Float = 1000
    private var result: PHFetchResult<PHAsset>!
    
    private var counter: Int = -1{
        didSet{
            guard counter == 0 else {return}
            counter = -1
            Task{
                try await self.exportConvertedAssetContainers()
            }
        }
    }
    private var fetchItems:[AVAssetContainer] = []
    func setFetchResult(result: PHFetchResult<PHAsset>) async{
        self.result = result
    }
    func run() async{
        counter = result.count
        fetchItems.removeAll()
        self.minDuration = 1000
        let resultCount = result.count
        self.progressSubject.send(0)
        result.enumerateObjects(options:.concurrent) { asset, val, idx in
            _ = asset.localIdentifier.replacingOccurrences(of: "/", with: "_")
            Task{
                do{
                    var urlAsset:AVURLAsset = try await asset.convertToAVURLAsset()
                    let value:Float = (try? await Float(urlAsset.load(.duration).value)) ?? 1 // 여기 에러 처리 필요함
                    let timeScale: Float = (try? await Float(urlAsset.load(.duration).timescale)) ?? 1 // 여기 에러 처리 필요함
                    let secondsLength = value / timeScale
                    self.minDuration = min(secondsLength,self.minDuration)
                    let cnt = self.fetchItems.count
                    
                    let tempFileURL = try await self.moveAssetDirToTempDir(urlAsset: &urlAsset)
                    
                    self.fetchItems.append(AVAssetContainer(id: asset.localIdentifier, idx: cnt, minDuration: 1000,
                                                            originalAssetURL: tempFileURL.absoluteString))
                    
                    self.counter -= 1
                    self.progressSubject.send(min(1, Float(resultCount - self.counter) / Float(2 * resultCount)))
                }catch{
                    throw VideoExecutorErrors.fetchFailed
                }
            }
        }
    }
    private func exportConvertedAssetContainers() async throws{
        var newAVssetContainers:[AVAssetContainer] = []
        let resultCount = fetchItems.count
        for (idx,item) in fetchItems.enumerated(){
            newAVssetContainers.append(AVAssetContainer(id: item.id, idx: item.idx, minDuration: self.minDuration, originalAssetURL: item.originalAssetURL))
            self.progressSubject.send(min(1,Float(idx) / Float(resultCount * 2) + 0.5))
        }
        fetchItems.removeAll()
        print("새 영상 컨테이너들",newAVssetContainers)
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
