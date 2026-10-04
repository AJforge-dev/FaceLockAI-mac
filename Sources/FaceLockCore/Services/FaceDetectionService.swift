import Foundation
import Vision
import CoreMedia
import CoreImage

public struct FaceFeatureVector: Codable, Sendable {
    public let values: [Float]
    
    public init(values: [Float]) {
        self.values = values
    }
}

public final class FaceDetectionService: @unchecked Sendable {
    public static let shared = FaceDetectionService()
    
    private init() {}
    
    // MARK: - Detect Landmark Features & Compute Normalized Vector
    public func extractFeatureVector(from sampleBuffer: CMSampleBuffer) -> (rect: CGRect, vector: [Float])? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
            guard let results = request.results, let face = results.first else {
                return nil
            }
            
            guard let landmarks = face.landmarks else { return nil }
            let vector = computeLandmarkVector(from: landmarks, boundingBox: face.boundingBox)
            return (face.boundingBox, vector)
        } catch {
            print("Vision landmark error: \(error)")
            return nil
        }
    }
    
    // Convert landmark points into normalized geometric distance ratios
    private func computeLandmarkVector(from landmarks: VNFaceLandmarks2D, boundingBox: CGRect) -> [Float] {
        var points: [CGPoint] = []
        
        if let leftEye = landmarks.leftEye {
            points.append(contentsOf: leftEye.normalizedPoints)
        }
        if let rightEye = landmarks.rightEye {
            points.append(contentsOf: rightEye.normalizedPoints)
        }
        if let nose = landmarks.nose {
            points.append(contentsOf: nose.normalizedPoints)
        }
        if let outerLips = landmarks.outerLips {
            points.append(contentsOf: outerLips.normalizedPoints)
        }
        if let faceContour = landmarks.faceContour {
            points.append(contentsOf: faceContour.normalizedPoints)
        }
        
        guard points.count >= 10 else {
            return Array(repeating: 0.0, count: 32)
        }
        
        // Calculate pair-wise distance ratios for scale-invariant representation
        var distances: [Float] = []
        let referenceDistance = hypot(points[0].x - points[min(5, points.count - 1)].x,
                                      points[0].y - points[min(5, points.count - 1)].y)
        let scale = referenceDistance > 0.0001 ? referenceDistance : 1.0
        
        let step = max(1, points.count / 8)
        for i in stride(from: 0, to: points.count, by: step) {
            for j in stride(from: i + 1, to: points.count, by: step) {
                let dist = Float(hypot(points[i].x - points[j].x, points[i].y - points[j].y) / scale)
                distances.append(dist)
                if distances.count >= 32 { break }
            }
            if distances.count >= 32 { break }
        }
        
        while distances.count < 32 {
            distances.append(0.0)
        }
        
        return distances
    }
}
