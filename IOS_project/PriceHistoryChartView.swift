import SwiftUI
import Charts

struct PriceHistoryChartView: View {
    let product: TrackedProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price History & Analytics")
                .font(.headline)
            
            Chart(product.priceHistory.sorted(by: { $0.date < $1.date })) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Price", record.price)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Price", record.price)
                )
                .foregroundStyle(.blue)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 220)
            
            if product.isDeceptivePricing {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Warning: Historical data shows this item's average price is lower. Potential fake discount.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}