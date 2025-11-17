import AVFoundation
import UIKit

actor VideoOrientationFixer {
    
    func fixOrientationIfNeeded(sourceURL: URL) async -> URL {
        let asset = AVAsset(url: sourceURL)
        
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            return sourceURL
        }
        
        let transform = try? await videoTrack.load(.preferredTransform)
        let naturalSize = try? await videoTrack.load(.naturalSize)
        
        guard let naturalSize = naturalSize else {
            return sourceURL
        }
        
        // Skip if already portrait
        if naturalSize.height > naturalSize.width {
            return sourceURL
        }
        
        // Skip if video already has rotation transform
        guard let transform = transform, transform == .identity else {
            return sourceURL
        }
        
        return await addPortraitTransform(sourceURL: sourceURL, naturalSize: naturalSize)
    }
    
    private func addPortraitTransform(sourceURL: URL, naturalSize: CGSize) async -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            return sourceURL
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        let composition = AVMutableVideoComposition()
        composition.renderSize = CGSize(width: naturalSize.height, height: naturalSize.width)
        composition.frameDuration = CMTime(value: 1, timescale: 30)
        
        // Portrait transform (90° clockwise)
        let transform = CGAffineTransform(rotationAngle: .pi / 2)
            .concatenating(CGAffineTransform(translationX: naturalSize.height, y: 0))
        
        if let videoTrack = try? await asset.loadTracks(withMediaType: .video).first {
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: try! await asset.load(.duration))
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
            layerInstruction.setTransform(transform, at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
            composition.instructions = [instruction]
            
            exportSession.videoComposition = composition
        }
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            do {
                if FileManager.default.fileExists(atPath: sourceURL.path) {
                    try FileManager.default.removeItem(at: sourceURL)
                }
                try FileManager.default.moveItem(at: outputURL, to: sourceURL)
                
                // Ensure file is synced to disk
                let fileHandle = try? FileHandle(forUpdating: sourceURL)
                try? fileHandle?.synchronize()
                try? fileHandle?.close()
                
                return sourceURL
            } catch {
                return outputURL
            }
        }
        
        return sourceURL
    }
}
