import SwiftUI
import UIKit

struct ProductDetailView: View {
    let product: TrackedProduct
    @EnvironmentObject var repository: ProductRepository
    
    private var decodedImage: UIImage? {
        guard let b64 = product.imageDataBase64,
              let data = Data(base64Encoded: b64) else { return nil }
        return UIImage(data: data)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let uiImage = decodedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal)
                }
                
                Text(product.title)
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatBox(
                        label: "Current Price",
                        value: String(format: "%@%.2f", product.currency, product.currentPrice),
                        accent: product.currentPrice <= product.targetPrice ? .green : .primary
                    )
                    StatBox(
                        label: "Target Price",
                        value: String(format: "%@%.2f", product.currency, product.targetPrice),
                        accent: .blue
                    )
                    StatBox(
                        label: "Historical Avg",
                        value: String(format: "%@%.2f", product.currency, product.historicalAverage),
                        accent: .secondary
                    )
                    StatBox(
                        label: "Vs. Average",
                        value: "\(product.priceVariancePercentage > 0 ? "+" : "")\(product.priceVariancePercentage)%",
                        accent: product.priceVariancePercentage > 0 ? .orange : .green
                    )
                }
                .padding(.horizontal)
                
                PriceHistoryChartView(product: product)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                VStack(spacing: 10) {
                    Button {
                        repository.simulatePriceDrop(for: product)
                    } label: {
                        Label("Simulate 15% Price Drop", systemImage: "arrow.down.right.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.16))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    
                    if let url = URL(string: product.urlString), url.scheme != nil {
                        Link(destination: url) {
                            Label("Open Product Page", systemImage: "safari")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.ultraThinMaterial)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let accent: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}