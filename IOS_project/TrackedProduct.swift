import Foundation
import SwiftData

@Model
class TrackedProduct {
    var id: UUID
    var urlString: String
    var title: String
    var currentPrice: Double
    var targetPrice: Double
    var currency: String
    var imageData: Data?
    var lastChecked: Date
    
    // Relational link: One product has many historical price records (Cascading delete)
    @Relationship(deleteRule: .cascade, inverse: \PriceRecord.product)
    var priceHistory: [PriceRecord] = []
    
    init(urlString: String, title: String, currentPrice: Double, targetPrice: Double, currency: String, imageData: Data?) {
        self.id = UUID()
        self.urlString = urlString
        self.title = title
        self.currentPrice = currentPrice
        self.targetPrice = targetPrice
        self.currency = currency
        self.imageData = imageData
        self.lastChecked = Date()
        self.priceHistory = [PriceRecord(date: Date(), price: currentPrice)]
    }
}

@Model
class PriceRecord {
    var id: UUID
    var date: Date
    var price: Double
    var product: TrackedProduct?
    
    init(date: Date, price: Double) {
        self.id = UUID()
        self.date = date
        self.price = price
    }
}

extension TrackedProduct {
    var historicalAverage: Double {
        guard !priceHistory.isEmpty else { return currentPrice }
        let total = priceHistory.reduce(0.0) { $0 + $1.price }
        return total / Double(priceHistory.count)
    }
    
    // Algorithmic Fake-Sale Detection: checks if current price is above long-term median
    var isDeceptivePricing: Bool {
        guard priceHistory.count >= 4 else { return false }
        let sortedPrices = priceHistory.map { $0.price }.sorted()
        let medianPrice = sortedPrices[sortedPrices.count / 2]
        return currentPrice > (medianPrice * 1.08)
    }
    
    var priceVariancePercentage: Int {
        let avg = historicalAverage
        guard avg > 0 else { return 0 }
        let diff = currentPrice - avg
        return Int((diff / avg) * 100)
    }
}