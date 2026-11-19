import SwiftUI
import UIKit

struct AddProductView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var repository: ProductRepository
    
    @State private var urlString = ""
    @State private var title = ""
    @State private var currentPrice = ""
    @State private var targetPrice = ""
    @State private var fetchedImageData: Data? = nil
    @State private var isFetching = false
    @State private var fetchMessage: String? = nil
    @State private var fetchSuccess: Bool? = nil
    
    private var parsedCurrent: Double? { Double(currentPrice) }
    private var parsedTarget: Double? { Double(targetPrice) }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 8) {
                        TextField("https://store.com/item", text: $urlString)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        Button {
                            if let pasted = UIPasteboard.general.string, !pasted.isEmpty {
                                urlString = pasted
                            }
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                        
                        if isFetching {
                            ProgressView()
                        } else {
                            Button("Fetch") {
                                Task { await fetchDetails() }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    
                    if let message = fetchMessage {
                        HStack(spacing: 6) {
                            Image(systemName: (fetchSuccess ?? false) ? "checkmark.circle.fill" : "info.circle.fill")
                            Text(message)
                        }
                        .font(.caption)
                        .foregroundStyle((fetchSuccess ?? false) ? .green : .secondary)
                    }
                } header: {
                    Text("Product Link")
                }
                
                Section("Product Details") {
                    TextField("Product Name", text: $title)
                    
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("Current Price", text: $currentPrice)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("Target Buy Price", text: $targetPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                if let curr = parsedCurrent, let target = parsedTarget {
                    Section("Target Preview") {
                        let diff = curr - target
                        HStack {
                            Text(diff <= 0 ? "Already below target!" : "Needed drop to hit target")
                                .font(.subheadline)
                            Spacer()
                            Text(diff <= 0 ? "Target Hit" : String(format: "-$%.2f", diff))
                                .font(.subheadline.bold())
                                .foregroundStyle(diff <= 0 ? .green : .blue)
                        }
                    }
                }
            }
            .navigationTitle("Track New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let uid = authService.user?.uid,
                              let curr = parsedCurrent,
                              let target = parsedTarget,
                              !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        
                        let now = Date()
                        let newProduct = TrackedProduct(
                            userId: uid,
                            urlString: urlString.isEmpty ? "https://example.com" : urlString,
                            title: title.trimmingCharacters(in: .whitespaces),
                            currentPrice: curr,
                            targetPrice: target,
                            currency: "$",
                            imageDataBase64: fetchedImageData?.base64EncodedString(),
                            lastChecked: now,
                            priceHistory: [PricePoint(date: now, price: curr)]
                        )
                        repository.addProduct(newProduct)
                        dismiss()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || parsedCurrent == nil || parsedTarget == nil || authService.user?.uid == nil)
                }
            }
        }
    }
    
    private func fetchDetails() async {
        isFetching = true
        fetchMessage = nil
        fetchSuccess = nil
        do {
            let result = try await PriceScraperService.shared.fetchProductDetails(from: urlString)
            title = result.title
            fetchedImageData = result.imageData
            if let price = result.price {
                currentPrice = String(format: "%.2f", price)
                fetchMessage = "Fetched title & price."
                fetchSuccess = true
            } else {
                fetchMessage = "Fetched metadata. Enter price manually."
                fetchSuccess = false
            }
        } catch {
            fetchMessage = "Couldn't fetch link. Enter details manually."
            fetchSuccess = false
        }
        isFetching = false
    }
}