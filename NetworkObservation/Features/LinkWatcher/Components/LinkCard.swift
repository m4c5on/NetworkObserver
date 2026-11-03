import SwiftUI

struct LinkCard: View {
    let link: MonitoredLink
    let onOpen: () -> Void
    let onTogglePause: () -> Void
    let onToggleMute: () -> Void
    let onResetStatistics: () -> Void
    let onRemove: () -> Void

    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            StatisticsStrip(statistics: link.statistics)
                .opacity(contentOpacity)
        }
        .padding(14)
        .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
        .contentShape(.rect(cornerRadius: cornerRadius))
        .onTapGesture(count: 2, perform: onOpen)
        .contextMenu {
            Button("Open", systemImage: "arrow.up.right", action: onOpen)
            Button(
                link.isPaused ? "Resume" : "Pause",
                systemImage: link.isPaused ? "play" : "pause",
                action: onTogglePause
            )
            Button(
                link.isMuted ? "Unmute Notifications" : "Mute Notifications",
                systemImage: link.isMuted ? "bell" : "bell.slash",
                action: onToggleMute
            )
            Button("Reset Statistics", systemImage: "arrow.counterclockwise", action: onResetStatistics)
            Divider()
            Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
        }
        .animation(.smooth, value: link.state)
        .animation(.smooth, value: link.isVerifying)
        .animation(.smooth, value: link.isPaused)
    }

    private var header: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                StatusIndicator(state: link.state, isVerifying: link.isVerifying, isPaused: link.isPaused)

                VStack(alignment: .leading, spacing: 3) {
                    Text(link.url.displayString)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    StatusLine(link: link)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .opacity(contentOpacity)

            Spacer(minLength: 8)

            CardIconButton(systemName: "xmark", label: "Remove", action: onRemove)

            CardIconButton(
                systemName: link.isMuted ? "bell.slash.fill" : "bell.fill",
                label: link.isMuted ? "Unmute notifications" : "Mute notifications",
                isHighlighted: link.isMuted,
                action: onToggleMute
            )

            CardIconButton(
                systemName: link.isPaused ? "play.fill" : "pause.fill",
                label: link.isPaused ? "Resume monitoring" : "Pause monitoring",
                isHighlighted: link.isPaused,
                action: onTogglePause
            )

            CardIconButton(systemName: "arrow.up.right", label: "Open in browser", action: onOpen)
        }
    }

    private var contentOpacity: Double {
        link.isPaused ? 0.55 : 1
    }

    private var tint: Color? {
        guard !link.isPaused else { return nil }
        return switch (link.state, link.isVerifying) {
        case (_, true): .orange.opacity(0.18)
        case (.offline, false): .red.opacity(0.22)
        case (.online, false), (.unknown, false): nil
        }
    }
}

private struct CardIconButton: View {
    let systemName: String
    let label: String
    var isHighlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .foregroundStyle(isHighlighted ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary))
                .frame(width: 26, height: 26)
                .background(
                    isHighlighted ? AnyShapeStyle(.orange.opacity(0.2)) : AnyShapeStyle(.quaternary),
                    in: .circle
                )
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

private struct StatusLine: View {
    let link: MonitoredLink

    var body: some View {
        if link.isPaused {
            Text(LinkWatcherFormatting.statusLine(for: link, now: .now))
        } else {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(LinkWatcherFormatting.statusLine(for: link, now: context.date))
            }
        }
    }
}

private struct StatusIndicator: View {
    let state: ConnectionState
    let isVerifying: Bool
    let isPaused: Bool

    var body: some View {
        Image(systemName: symbolName)
            .font(.title2)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.pulse, isActive: !isPaused && (isVerifying || state == .unknown))
            .frame(width: 28)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        if isPaused { return "pause.circle.fill" }
        return switch (state, isVerifying) {
        case (_, true): "arrow.triangle.2.circlepath.circle.fill"
        case (.online, false): "checkmark.circle.fill"
        case (.offline, false): "xmark.circle.fill"
        case (.unknown, false): "circle.dotted"
        }
    }

    private var color: Color {
        if isPaused { return .secondary }
        return switch (state, isVerifying) {
        case (_, true): .orange
        case (.online, false): .green
        case (.offline, false): .red
        case (.unknown, false): .secondary
        }
    }
}

private struct StatisticsStrip: View {
    let statistics: LinkStatistics

    var body: some View {
        HStack(spacing: 16) {
            HistorySparkline(samples: statistics.recentSamples)
                .frame(height: 28)
                .frame(maxWidth: .infinity)

            ForEach(LinkWatcherFormatting.metrics(for: statistics)) { metric in
                VStack(alignment: .trailing, spacing: 1) {
                    Text(metric.value)
                        .font(.callout.weight(.semibold))
                        .monospacedDigit()
                    Text(metric.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                .frame(minWidth: 54, alignment: .trailing)
            }
        }
    }
}

private struct HistorySparkline: View {
    let samples: [CheckSample]

    var body: some View {
        Canvas { context, size in
            let slots = LinkStatistics.historyLimit
            let spacing: CGFloat = 2
            let barWidth = max(1, (size.width - spacing * CGFloat(slots - 1)) / CGFloat(slots))
            let maxLatency = max(1, samples.compactMap { $0.latency?.inMilliseconds }.max() ?? 1)
            let firstSampleSlot = slots - samples.count

            for slot in 0..<slots {
                let x = CGFloat(slot) * (barWidth + spacing)
                let index = slot - firstSampleSlot

                guard samples.indices.contains(index) else {
                    let placeholder = CGRect(x: x, y: size.height - 3, width: barWidth, height: 3)
                    context.fill(Path(roundedRect: placeholder, cornerRadius: 1.5), with: .color(.gray.opacity(0.25)))
                    continue
                }

                let sample = samples[index]
                let ratio = sample.isUp ? max(0.2, (sample.latency?.inMilliseconds ?? 0) / maxLatency) : 1
                let height = size.height * ratio
                let bar = CGRect(x: x, y: size.height - height, width: barWidth, height: height)
                let color: Color = sample.isUp ? .green.opacity(0.75) : .red.opacity(0.85)
                context.fill(Path(roundedRect: bar, cornerRadius: min(barWidth / 2, 2)), with: .color(color))
            }
        }
        .accessibilityLabel("Last \(samples.count) checks")
    }
}
