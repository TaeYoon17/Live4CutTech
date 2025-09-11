import Testing
import AVFoundation
import Combine
import Photos

import MachO

@testable import LiveFourCut

final class MockVideoExecutor: VideoExecutorProtocol {
    let itemsSubject: PassthroughSubject<[AVAssetContainer], Never> = .init()
    private(set) var minDuration: Float = 1000
    let progressSubject: PassthroughSubject<Float, Never> = .init()
    
    func setFetchResult(result: PHFetchResult<PHAsset>) async { }
    
    func run() async {
        let mockAssets = await loadMockVideoAssets()
        itemsSubject.send(mockAssets)
    }
    
    private func loadMockVideoAssets() async -> [AVAssetContainer] {
        let bundle = Bundle(for: type(of: self))
        let videoNames = ["first", "second", "third", "four"]
        
        let videoURLs: [URL] = videoNames.compactMap { name in
            guard let url = bundle.url(forResource: name, withExtension: "mov") else {
                print("Warning: Could not find \(name).mov in test bundle")
                return nil
            }
            return url
        }
        var res: [AVAssetContainer] = []
        for (idx, videoURL) in videoURLs.enumerated() {
            let asset = AVAsset(url: videoURL)
            let value: Float = (try? await Float(asset.load(.duration).value)) ?? 1 // 여기 에러 처리 필요함
            let timeScale: Float = (try? await Float(asset.load(.duration).timescale)) ?? 1 // 여기 에러 처리 필요함
            let secondsLength = value / timeScale
            self.minDuration = min(secondsLength, self.minDuration)
            res.append(
                AVAssetContainer(
                    id: videoURL.absoluteString,
                    idx: idx,
                    minDuration: 1000,
                    originalAssetURL: videoURL.absoluteString
                )
            )
        }
        return res
    }
}


@Test
func testExample() {
    let cmTime = CMTime(seconds: 2, preferredTimescale: 2)
    let cmTime2 = CMTime(seconds: 1.41, preferredTimescale: 10)
    let cmTime3 = CMTime(seconds: 14.1, preferredTimescale: 10)
    
    print(cmTime, cmTime.seconds)
    print(cmTime2, cmTime2.seconds)
    print(cmTime3, cmTime3.seconds)
    
}



fileprivate func reportMemory() -> UInt64 {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
    
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    
    guard result == KERN_SUCCESS else { return 0 }
    return info.phys_footprint // 실제 물리 메모리 사용량 (bytes)
}
