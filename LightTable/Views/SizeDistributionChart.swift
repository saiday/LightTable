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
            HStack {
                Text("Size Distribution")
                    .font(.headline)
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
                "Photos": Color.blue,
                "Videos": Color.purple,
            ])
            .chartYAxis {
                if chartMetric == .storage {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let bytes = value.as(Double.self) {
                                Text(formatBytes(Int64(bytes)))
                            }
                        }
                    }
                } else {
                    AxisMarks()
                }
            }
            .frame(height: 200)
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
}

private struct ChartDataPoint: Identifiable {
    let id = UUID()
    let bucket: String
    let mediaType: String
    let value: Double
}
