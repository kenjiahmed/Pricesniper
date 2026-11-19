import Foundation
import LinkPresentation
import UIKit

struct ScrapedProduct {
    let title: String
    let price: Double?
    let currency: String
    let imageData: Data?
}

@MainActor
class PriceScraperService {
    static let shared = PriceScraperService()
    
    func fetchProductDetails(from urlString: String) async throws -> ScrapedProduct {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let provider = LPMetadataProvider()
        var title = url.host ?? "Tracked Product"
        var imageData: Data? = nil
        
        if let metadata = try? await provider.startFetchingMetadata(for: url) {
            if let fetchedTitle = metadata.title, !fetchedTitle.isEmpty {
                title = fetchedTitle
            }
            if let imageProvider = metadata.imageProvider {
                imageData = await loadImageData(from: imageProvider)
            }
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let html = String(data: data, encoding: .utf8) ?? ""
        let extractedPrice = extractPrice(from: html)
        
        return ScrapedProduct(
            title: title,
            price: extractedPrice,
            currency: "$",
            imageData: imageData
        )
    }
    
    private func loadImageData(from provider: NSItemProvider) async -> Data? {
        await withCheckedContinuation { continuation in
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage {
                    continuation.resume(returning: uiImage.jpegData(compressionQuality: 0.7))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func extractPrice(from html: String) -> Double? {
        let patterns = [
            #"property="product:price:amount"\s+content="([0-9]+\.?[0-9]*)""#,
            #"property="og:price:amount"\s+content="([0-9]+\.?[0-9]*)""#,
            #""price"\s*:\s*"?([0-9]+\.?[0-9]*)"?"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return Double(html[range])
            }
        }
        return nil
    }
}