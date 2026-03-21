import SwiftUI
import Charts

enum ChartMetric: String, CaseIterable {
    case count = "Count"
    case storage = "Storage"
}

struct SizeDistributionChart: View {
    let buckets: [SizeBucket]
    @State private var chartMetric: ChartMetric = .count

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("SIZE DISTRIBUTION")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.text2)
                Spacer()
                Picker("Metric", selection: $chartMetric) {
                    ForEach(ChartMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 160)
            }

            // Chart container
            Chart {
                ForEach(chartDataPoints) { point in
                    BarMark(
                        x: .value("Size Range", point.bucket),
                        y: .value(chartMetric == .count ? "Assets" : "Size", point.value)
                    )
                    .foregroundStyle(by: .value("Type", point.mediaType))
                }
            }
            .chartForegroundStyleScale([
                "Photos": Theme.helvetiaBlue,
                "Videos": Theme.dullCitrine,
            ])
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if chartMetric == .storage {
                            if let bytes = value.as(Double.self) {
                                Text(formatBytes(Int64(bytes)))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.text3)
                            }
                        } else {
                            if let count = value.as(Double.self) {
                                Text(formatCount(count))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.text3)
                            }
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.text3)
                }
            }
            .chartLegend(position: .bottom, alignment: .leading, spacing: 12)
            .frame(height: 200)
            .padding(20)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Theme.border, lineWidth: 1)
            )
        }
    }

    private var chartDataPoints: [ChartDataPoint] {
        buckets.flatMap { bucket -> [ChartDataPoint] in
            let imageValue: Double
            let videoValue: Double
            switch chartMetric {
            case .count:
                imageValue = Double(bucket.imageCount)
                videoValue = Double(bucket.videoCount)
            case .storage:
                imageValue = Double(bucket.imageTotalSize)
                videoValue = Double(bucket.videoTotalSize)
            }
            return [
                ChartDataPoint(bucket: bucket.label, mediaType: "Photos", value: imageValue),
                ChartDataPoint(bucket: bucket.label, mediaType: "Videos", value: videoValue),
            ]
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatCount(_ value: Double) -> String {
        let intValue = Int(value)
        if intValue >= 1_000_000 {
            return "\(intValue / 1_000_000)M"
        } else if intValue >= 1_000 {
            return "\(intValue / 1_000)K"
        }
        return "\(intValue)"
    }
}

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let bucket: String
    let mediaType: String
    let value: Double
}
