//
//  LatencySparklineView.swift
//  NetworkObservation
//
//  Real-time gateway-latency strip chart shown under the health label. Background bands mark
//  the ok/degraded zones at ConnectionHealthDomain.gatewayDegradedThresholdMs; a `nil` sample
//  (gateway unreachable that cycle) breaks the line and is flagged with a red marker at the top.
//

import SwiftUI

struct LatencySparklineView: View {
    typealias Domain = ConnectionHealthDomain

    let samples: [Double?]

    private let chartHeight: CGFloat = 44
    private let lineColor = Color.accentColor

    var body: some View {
        Canvas { context, size in
            let threshold = Domain.gatewayDegradedThresholdMs
            let maxSample = samples.compactMap { $0 }.max() ?? threshold
            let scaleMax = max(maxSample * 1.15, threshold * 1.5)
            let capacity = Domain.latencyHistoryLimit
            let stepX = capacity > 1 ? size.width / CGFloat(capacity - 1) : size.width

            func x(_ index: Int) -> CGFloat { CGFloat(index) * stepX }
            func y(_ value: Double) -> CGFloat {
                size.height * (1 - CGFloat(min(value, scaleMax) / scaleMax))
            }

            drawZones(context: &context, size: size, thresholdY: y(threshold))
            drawLineAndArea(context: &context, size: size, x: x, y: y)
            drawFailureMarkers(context: &context, size: size, x: x)
        }
        .frame(height: chartHeight)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func drawZones(context: inout GraphicsContext, size: CGSize, thresholdY: CGFloat) {
        let okZone = CGRect(x: 0, y: thresholdY, width: size.width, height: size.height - thresholdY)
        let degradedZone = CGRect(x: 0, y: 0, width: size.width, height: thresholdY)
        context.fill(Path(okZone), with: .color(.green.opacity(0.12)))
        context.fill(Path(degradedZone), with: .color(.yellow.opacity(0.14)))
    }

    private func drawLineAndArea(
        context: inout GraphicsContext,
        size: CGSize,
        x: (Int) -> CGFloat,
        y: (Double) -> CGFloat
    ) {
        for run in contiguousRuns() {
            var linePath = Path()
            for (offset, index) in run.enumerated() {
                let point = CGPoint(x: x(index), y: y(samples[index] ?? 0))
                if offset == 0 {
                    linePath.move(to: point)
                } else {
                    linePath.addLine(to: point)
                }
            }

            var areaPath = linePath
            if let last = run.last, let first = run.first {
                areaPath.addLine(to: CGPoint(x: x(last), y: size.height))
                areaPath.addLine(to: CGPoint(x: x(first), y: size.height))
                areaPath.closeSubpath()
            }

            context.fill(
                areaPath,
                with: .linearGradient(
                    Gradient(colors: [lineColor.opacity(0.25), lineColor.opacity(0)]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )
            context.stroke(linePath, with: .color(lineColor), lineWidth: 1.5)
        }
    }

    private func drawFailureMarkers(context: inout GraphicsContext, size: CGSize, x: (Int) -> CGFloat) {
        for (index, sample) in samples.enumerated() where sample == nil {
            let marker = Path(ellipseIn: CGRect(x: x(index) - 2, y: 0, width: 4, height: 4))
            context.fill(marker, with: .color(.red))
        }
    }

    /// Splits sample indices into runs separated by `nil` gaps, so the line breaks at outages
    /// instead of interpolating through them.
    private func contiguousRuns() -> [[Int]] {
        var runs: [[Int]] = []
        var current: [Int] = []
        for (index, sample) in samples.enumerated() {
            if sample != nil {
                current.append(index)
            } else if !current.isEmpty {
                runs.append(current)
                current = []
            }
        }
        if !current.isEmpty { runs.append(current) }
        return runs
    }
}
