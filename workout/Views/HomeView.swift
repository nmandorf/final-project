//
//  HomeView.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Home")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    StatCard(title: "Weight Progress", subtitle: viewModel.trackingStats.subtitle) {
                        WeightChart(weights: viewModel.trackingStats.weights, dates: viewModel.trackingStats.dates)
                    }
                    
                    StatCard(title: "Average Reps", subtitle: viewModel.trackingStats.subtitle) {
                        if let avg = viewModel.trackingStats.averageReps {
                            Text("\(avg, specifier: "%.1f") reps")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        } else {
                            PlaceholderText(message: "Log a workout to see averages.")
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear(perform: viewModel.loadTrackingStats)
    }
}

private struct StatCard<Content: View>: View {
    let title: String
    let subtitle: String
    private let contentView: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.contentView = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            contentView
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
    }
}

private struct WeightChart: View {
    let weights: [Double]
    let dates: [Date]
    
    private typealias ChartEntry = (weight: Double, date: Date)
    
    private var sanitizedEntries: [ChartEntry] {
        let count = min(weights.count, dates.count)
        guard count > 0 else { return [] }
        
        var entries: [ChartEntry] = []
        entries.reserveCapacity(count)
        
        for index in 0..<count {
            let weight = weights[index]
            guard weight.isFinite else { continue }
            entries.append((weight: weight, date: dates[index]))
        }
        
        return entries.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        let entries = sanitizedEntries
        
        return Group {
            if entries.count < 2 {
                if let weight = entries.first?.weight {
                    VStack(spacing: 8) {
                        Text("\(weight, specifier: "%.0f") lbs")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Log another workout to see progress.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    PlaceholderText(message: "No weight data yet.")
                }
            } else {
                ChartView(entries: entries)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func ChartView(entries: [ChartEntry]) -> some View {
        GeometryReader { geometry in
            let leftPadding: CGFloat = 44
            let rightPadding: CGFloat = 8
            let topPadding: CGFloat = 8
            let bottomPadding: CGFloat = 36
            let chartWidth = max(geometry.size.width - leftPadding - rightPadding, 1)
            let chartHeight = max(geometry.size.height - topPadding - bottomPadding, 1)
            let chartSize = CGSize(width: chartWidth, height: chartHeight)
            let points = chartPoints(for: entries, size: chartSize)
            let weights = entries.map { $0.weight }
            let minWeight = weights.min() ?? 0
            let maxWeight = weights.max() ?? 0
            let ticks = yAxisTicks(minWeight: minWeight, maxWeight: maxWeight)
            let axisX = leftPadding
            let axisBottomY = topPadding + chartHeight
            let formatter = DateFormatter.shortFormatter
            
            ZStack {
                // Axes
                Path { path in
                    path.move(to: CGPoint(x: axisX, y: topPadding))
                    path.addLine(to: CGPoint(x: axisX, y: axisBottomY))
                    path.addLine(to: CGPoint(x: axisX + chartWidth, y: axisBottomY))
                }
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                
                // Y-axis tick labels and hashes
                ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
                    let yPosition = topPadding + chartHeight - CGFloat(tick.fraction) * chartHeight
                    
                    Path { path in
                        path.move(to: CGPoint(x: axisX - 6, y: yPosition))
                        path.addLine(to: CGPoint(x: axisX, y: yPosition))
                    }
                    .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                    
                    Text("\(tick.value, specifier: "%.0f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: axisX - 24, y: yPosition)
                }
                
                // Chart line
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: CGPoint(x: first.x + axisX, y: first.y + topPadding))
                    for point in points.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x + axisX, y: point.y + topPadding))
                    }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                
                // Points and date labels under axis
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    let pointPosition = CGPoint(x: point.x + axisX, y: point.y + topPadding)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(pointPosition)
                    
                    Text(formatter.string(from: entries[index].date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .position(x: pointPosition.x, y: axisBottomY + 14)
                }
            }
        }
        .frame(height: 220)
    }
    
    private func chartPoints(for entries: [ChartEntry], size: CGSize) -> [CGPoint] {
        let weights = entries.map { $0.weight }
        guard let minWeight = weights.min(),
              let maxWeight = weights.max(),
              size.width > 0,
              size.height > 0 else {
            return []
        }
        
        let verticalRange = maxWeight - minWeight == 0 ? 1 : maxWeight - minWeight
        let stepX = entries.count > 1 ? size.width / CGFloat(entries.count - 1) : 0
        
        return weights.enumerated().map { index, value in
            let progress = (value - minWeight) / verticalRange
            let x = CGFloat(index) * stepX
            let y = size.height - (CGFloat(progress) * size.height)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func yAxisTicks(minWeight: Double, maxWeight: Double) -> [(value: Double, fraction: Double)] {
        let range = max(maxWeight - minWeight, 0)
        if range == 0 {
            return [
                (value: maxWeight, fraction: 1),
                (value: maxWeight, fraction: 2.0 / 3.0),
                (value: maxWeight, fraction: 1.0 / 3.0),
                (value: maxWeight, fraction: 0)
            ]
        }
        
        let fractions: [Double] = [1, 2.0 / 3.0, 1.0 / 3.0, 0]
        return fractions.map { fraction in
            let value = minWeight + (range * fraction)
            return (value, fraction)
        }
    }
}

private struct PlaceholderText: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private extension DateFormatter {
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    HomeView()
}
