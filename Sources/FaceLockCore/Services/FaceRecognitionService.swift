import Foundation

public final class FaceRecognitionService: Sendable {
    public static let shared = FaceRecognitionService()
    
    private init() {}

    // Cosine similarity computation between two normalized feature vectors
    public func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        guard v1.count == v2.count, !v1.isEmpty else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var normA: Float = 0.0
        var normB: Float = 0.0
        
        for i in 0..<v1.count {
            dotProduct += v1[i] * v2[i]
            normA += v1[i] * v1[i]
            normB += v2[i] * v2[i]
        }
        
        let denominator = sqrt(normA) * sqrt(normB)
        if denominator < 0.00001 { return 0.0 }
        return dotProduct / denominator
    }

    // Match live vector against enrolled reference templates
    public func matchVector(_ liveVector: [Float], enrolledTemplates: [[Float]], threshold: Float = 0.85) -> (isMatch: Bool, confidence: Float) {
        guard !enrolledTemplates.isEmpty else { return (false, 0.0) }
        
        var maxConfidence: Float = 0.0
        for template in enrolledTemplates {
            let sim = cosineSimilarity(liveVector, template)
            if sim > maxConfidence {
                maxConfidence = sim
            }
        }
        
        let isMatch = maxConfidence >= threshold
        return (isMatch, maxConfidence)
    }
}
