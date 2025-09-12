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

struct VideoFetchDTO {
    let minDuration: Float
    let items: [AVAssetContainer]
}

enum VideoExecutorState {
    case running(Float)
    case finished(VideoFetchDTO)
}



actor VideoExecutor: VideoExecutorProtocol {
    
    let executeStream: AsyncThrowingStream<VideoExecutorState, any Error>
    private let continuation:  AsyncThrowingStream<VideoExecutorState, any Error>.Continuation
    
    private let videoManager: PHCachingImageManager = .init()
    private var result: PHFetchResult<PHAsset>!
    
    init() {
        let (stream, continuation) = AsyncThrowingStream<VideoExecutorState, any Error>.makeStream()
        self.continuation = continuation
        self.executeStream = stream
    }
    func setFetchResult(result: PHFetchResult<PHAsset>) {
        self.result = result
    }
    func run() async {
        // 여기 락 처리를 안했는데 괜찮을까?
        var fetchAssets: [PHAssetResource] = []
        let lock = NSLock()
        result.enumerateObjects(options: .concurrent) { asset, idx, _ in
            let files = PHAssetResource.assetResources(for: asset).filter { $0.originalFilename.contains(".MOV") }
            guard let file: PHAssetResource = files.first else { return }
            lock.lock()
            fetchAssets.append(file)
            lock.unlock()
        }
        let maxCount = fetchAssets.count
        Task {
            let option = PHAssetResourceRequestOptions()
            option.isNetworkAccessAllowed = true
            var items: [AVAssetContainer] = []
            var minDuration: Float = 1000
            self.continuation.yield(.running(0))
            for (idx, file) in fetchAssets.enumerated() {
                let fileStrings = file.originalFilename.split(separator: ".").map{ String($0) }
                let fileName = "\(fileStrings[0])\(idx).\(fileStrings[1])"
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath:fileURL.path) {
                    try? FileManager.default.removeItem(at: fileURL)
                }
                try await PHAssetResourceManager.default().writeData(
                    for: file,
                    toFile: fileURL,
                    options: option
                )
                
                let urlAsset = AVURLAsset(url: fileURL)
                let value: Float = (try? await Float(urlAsset.load(.duration).value)) ?? 1 // 여기 에러 처리 필요함
                let timeScale: Float = (try? await Float(urlAsset.load(.duration).timescale)) ?? 1 // 여기 에러 처리 필요함
                let secondsLength = value / timeScale
                
                items.append(
                    AVAssetContainer(
                        id: file.assetLocalIdentifier,
                        idx: idx,
                        minDuration: 1000,
                        originalAssetURL: fileURL.absoluteString
                    )
                )
                minDuration = min(secondsLength, minDuration)
                self.continuation.yield(.running(min(1, Float(idx + 1) / Float(maxCount))))
            }
            
            self.continuation.yield(
                .finished(
                    VideoFetchDTO(
                        minDuration: minDuration,
                        items: items
                    )
                )
            )
        }
    }
}

extension VideoExecutor {
    fileprivate func moveAssetDirToTempDir(urlAsset: inout AVURLAsset) async throws -> URL{
        let lastComponent = urlAsset.url.lastPathComponent
        let tempFileURL = FileManager().temporaryDirectory.appendingPathComponent(lastComponent)
        if FileManager.default.fileExists(atPath: tempFileURL.path()) {
            try? FileManager.default.removeItem(at: tempFileURL)
        }
        
        guard let exportSession = AVAssetExportSession(
            asset: urlAsset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
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
            case .cancelled, .completed: break
            case .unknown, .waiting, .exporting, .failed: throw VideoExecutorErrors.failedSavedTempDirectory
            @unknown default: throw VideoExecutorErrors.failedSavedTempDirectory
            }
        }
        return tempFileURL
    }
}

fileprivate extension FileManager {
    func tempFileExist(fileName: String) async throws -> Bool {
        let newFileURL = self.temporaryDirectory.appendingPathComponent(fileName)
        return self.fileExists(atPath: newFileURL.absoluteString)
    }
}
