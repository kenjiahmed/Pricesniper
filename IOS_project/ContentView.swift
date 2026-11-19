import SwiftUI
import UIKit

enum PriceFilter: String, CaseIterable {
    case all = "All"
    case targetHit = "Target Hit"
    case fakeSale = "Fake Sale"
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var repository: ProductRepository
    
    @State private var selectedFilter: PriceFilter = .all
    @State private var searchText = ""
    @State private var showingAddSheet = false
    
    private var filteredProducts: [TrackedProduct] {
        repository.products.filter { item in
            let matchesSearch = searchText.isEmpty || item.title.localizedCaseInsensitiveContains(searchText)
            switch selectedFilter {
            case .all:
                return matchesSearch
            case .targetHit:
                return matchesSearch && item.currentPrice <= item.targetPrice
            case .fakeSale:
                return matchesSearch && item.isDeceptivePricing
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(PriceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                Group {
                    if filteredProducts.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Tracked Items" : "No Matching Items",
                            systemImage: "tag.slash",
                            description: Text(searchText.isEmpty ? "Tap + to paste a product link and start tracking." : "Try clearing your search or changing the filter.")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredProducts) { product in
                                    NavigationLink(destination: ProductDetailView(product: product)) {
                                        ProductCardView(product: product)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            repository.deleteProduct(id: product.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Price Sniper Pro")
            .searchable(text: $searchText, prompt: "Search tracked items")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        repository.stopListening()
                        authService.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddProductView()
            }
        }
    }
}

struct ProductCardView: View {
    let product: TrackedProduct
    
    private var isTargetMet: Bool {
        product.currentPrice <= product.targetPrice
    }
    
    private var decodedImage: UIImage? {
        guard let b64 = product.imageDataBase64,
              let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let uiImage = decodedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue.opacity(0.14))
                        Image(systemName: "bag.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .frame(width: 74, height: 74)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%@%.2f", product.currency, product.currentPrice))
                        .font(.title3.bold())
                        .foregroundStyle(isTargetMet ? .green : .primary)
                    
                    Text("Target \(product.currency)\(String(format: "%.2f", product.targetPrice))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 6) {
                    if isTargetMet {
                        StatusPill(text: "TARGET HIT", color: .green, icon: "checkmark.seal.fill")
                    }
                    if product.isDeceptivePricing {
                        StatusPill(text: "FAKE SALE", color: .orange, icon: "exclamationmark.triangle.fill")
                    }
                    if !isTargetMet && !product.isDeceptivePricing {
                        StatusPill(text: "WATCHING", color: .blue, icon: "eye.fill")
                    }
                }
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 10, weight: .bold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.16))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}