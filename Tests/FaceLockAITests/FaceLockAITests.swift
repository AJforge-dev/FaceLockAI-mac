import Foundation
import FaceLockCore

@main
struct TestRunner {
    static func main() {
        print("Running FaceLockAI Standalone Unit Tests...")
        
        let service = FaceRecognitionService.shared
        
        // Test 1: Cosine Similarity Exact Match
        let vectorA: [Float] = [1.0, 2.0, 3.0, 4.0]
        let vectorB: [Float] = [1.0, 2.0, 3.0, 4.0]
        let similarity = service.cosineSimilarity(vectorA, vectorB)
        assert(similarity > 0.999, "Test 1 Failed: Expected similarity > 0.999")
        print("✓ Test 1 Passed: Cosine Similarity Exact Match (\(similarity))")
        
        // Test 2: Cosine Similarity Orthogonal Vectors
        let vectorC: [Float] = [1.0, 0.0]
        let vectorD: [Float] = [0.0, 1.0]
        let orthSim = service.cosineSimilarity(vectorC, vectorD)
        assert(abs(orthSim) < 0.001, "Test 2 Failed: Expected orthSim < 0.001")
        print("✓ Test 2 Passed: Cosine Similarity Orthogonal (\(orthSim))")
        
        // Test 3: Threshold Matching
        let template: [Float] = [0.5, 0.5, 0.5, 0.5]
        let live: [Float] = [0.5, 0.5, 0.49, 0.5]
        let matchResult = service.matchVector(live, enrolledTemplates: [template], threshold: 0.85)
        assert(matchResult.isMatch == true, "Test 3 Failed: Expected isMatch = true")
        print("✓ Test 3 Passed: Threshold Matching (Confidence: \(matchResult.confidence))")
        
        // Test 4: Vault Category Mapping Test
        let photoCategory = VaultCategory.photos
        assert(photoCategory.iconName == "photo.stack.fill", "Test 4 Failed: Vault Category icon check")
        print("✓ Test 4 Passed: Vault Category Photo Icon Mapping")

        print("\n🎉 ALL UNIT TESTS PASSED SUCCESSFULLY!")
    }
}
