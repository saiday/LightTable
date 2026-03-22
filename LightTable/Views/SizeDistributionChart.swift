import SwiftUI
import Charts

enum ChartMetric: String, CaseIterable {
    case count = "Count"
    case storage = "Storage"
}

struct SizeDistributionChart: View {
    let buckets: [SizeBucket]
    @State private var chartMetric: ChartMetric = .count
    @State private var animateChart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text("SIZE DISTRIBUTION")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(0.8)
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

            // Chart
            Chart {
                ForEach(chartDataPoints) { point in
                    BarMark(
                        x: .value("Size Range", point.bucket),
                        y: .value(chartMetric == .count ? "Assets" : "Size", animateChart ? point.value : 0)
                    )
                    .foregroundStyle(by: .value("Type", point.mediaType))
                    .annotation(position: .top) {
                        if point.mediaType == "Videos" {
                            let total = bucketTotals[point.bucket] ?? 0
                            if total > 0 {
                                Text(chartMetric == .count ? formatCount(total) : formatBytes(Int64(total)))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.text3)
                            }
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Photos": Theme.eosinePink,
                "Videos": Theme.neutralGray,
            ])
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if chartMetric == .storage {
                            if let bytes = value.as(Double.self) {
                                Text(formatBytes(Int64(bytes)))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.text3)
                            }
                        } else {
                            if let count = value.as(Double.self) {
                                Text(formatCount(count))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.text3)
                            }
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.text3)
                }
            }
            .chartLegend {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle().fill(Theme.eosinePink).frame(width: 8, height: 8)
                        Text("Photos").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text2)
                    }
                    HStack(spacing: 4) {
                        Circle().fill(Theme.neutralGray).frame(width: 8, height: 8)
                        Text("Videos").font(.system(size: 11, weight: .medium)).foregroundStyle(Theme.text2)
                    }
                }
            }
            .frame(height: 180)
            .animation(.default, value: chartMetric)
            .animation(.default, value: animateChart)
            .onAppear {
                withAnimation(.default) {
                    animateChart = true
                }
            }
        }
        .surfaceCard()
    }

    private var bucketTotals: [String: Double] {
        Dictionary(grouping: chartDataPoints, by: \.bucket)
            .mapValues { $0.reduce(0) { $0 + $1.value } }
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
    var id: String { "\(bucket)-\(mediaType)" }
    let bucket: String
    let mediaType: String
    let value: Double
}
