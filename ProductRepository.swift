import Foundation
import FirebaseFirestore

@MainActor
class ProductRepository: ObservableObject {
    @Published var products: [TrackedProduct] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func startListening(for userId: String) {
        listener?.remove()
        listener = db.collection("products")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error {
                    print("Firestore listener error: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                let decoded = documents.compactMap { doc -> TrackedProduct? in
                    try? doc.data(as: TrackedProduct.self)
                }
                self.products = decoded.sorted { $0.lastChecked > $1.lastChecked }
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
        products = []
    }
    
    func addProduct(_ product: TrackedProduct) {
        do {
            try db.collection("products").document(product.id).setData(from: product)
        } catch {
            print("Error saving product to Firestore: \(error.localizedDescription)")
        }
    }
    
    func deleteProduct(id: String) {
        db.collection("products").document(id).delete()
    }
    
    func simulatePriceDrop(for product: TrackedProduct, factor: Double = 0.85) {
        let newPrice = (product.currentPrice * factor * 100).rounded() / 100
        var updated = product
        updated.currentPrice = newPrice
        updated.lastChecked = Date()
        updated.priceHistory.append(PricePoint(date: Date(), price: newPrice))
        
        do {
            try db.collection("products").document(product.id).setData(from: updated)
        } catch {
            print("Error updating price in Firestore: \(error.localizedDescription)")
        }
    }
}