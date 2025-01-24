//
//  AccelerationChartView.swift
//  watchOS-motion-writer
//
//  Created by Shingo Toyoda on 2025/01/24.
//

import SwiftUI
import Charts

struct AccelerationChartView: View {
    let csvContent: String
    @State private var dataPoints: [AccelerationData] = []
    
    var body: some View {
        VStack {
            Chart {
                ForEach(Array(dataPoints.enumerated()), id: \.element.id) { index, point in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("加速度X", point.accelerationX)
                    )
                    .foregroundStyle(by: .value("Category", "X"))
                    
                    LineMark(
                        x: .value("Index", index),
                        y: .value("加速度Y", point.accelerationY))
                    .foregroundStyle(by: .value("Category", "Y"))
                    
                    LineMark(
                        x: .value("Index", index),
                        y: .value("加速度Z", point.accelerationZ)
                    )
                    .foregroundStyle(by: .value("Category", "Z"))
                }
            }
            .onAppear {
                parseCSV()
            }
            .onChange(of: csvContent) {
                parseCSV()
            }
        }
    }
    
    private func parseCSV() {
        let lines = csvContent.components(separatedBy: "\n")
        var points: [AccelerationData] = []
        
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            if columns.count >= 3 {
                if let x = Double(columns[0]),
                   let y = Double(columns[1]),
                   let z = Double(columns[2]) {
                    points.append(AccelerationData(
                        accelerationX: x,
                        accelerationY: y,
                        accelerationZ: z
                    ))
                }
            }
        }
        dataPoints = points
        print(dataPoints)
    }
}

struct AccelerationData: Identifiable {
    let id = UUID()
    let accelerationX: Double
    let accelerationY: Double
    let accelerationZ: Double
}
#Preview {
    let csvContent = """
acceleration_x,acceleration_y,acceleration_z
0.12,-0.98,0.05
0.15,-0.97,0.06
0.18,-0.96,0.07
0.21,-0.95,0.08
0.24,-0.94,0.09
0.27,-0.93,0.10
0.30,-0.92,0.11
0.33,-0.91,0.12
0.36,-0.90,0.13
0.39,-0.89,0.14
0.42,-0.88,0.15
"""
    AccelerationChartView(csvContent: csvContent)
}
