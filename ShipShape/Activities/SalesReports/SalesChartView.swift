//
// SalesChartView.swift
// ShipShape
// https://www.github.com/twostraws/ShipShape
// See LICENSE for license information.
//

import Charts
import SwiftUI

struct SalesChartView: View {

    private var sales: [[String: String]]

    private var selectedPeriod: ReportingPeriod
    private var selectedYear: Int?
    private var selectedMonth: Int?

    private var xLabel: String = ""
    private var chartData: [(String, Int)] = []

    init(sales: [[String: String]], selectedPeriod: ReportingPeriod, selectedYear: Int? = nil, selectedMonth: Int? = nil) {
        self.sales = sales
        self.selectedPeriod = selectedPeriod
        self.selectedYear = selectedYear
        self.selectedMonth = selectedMonth

        let dateParser: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MM/dd/yyyy"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }()

        switch selectedPeriod {
        case .lastThirtyDays:
            xLabel = "Day"
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none

            var calendar = Calendar.current
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let today = calendar.startOfDay(for: Date())

            for offset in (0..<30).reversed() {
                if let day = calendar.date(byAdding: .day, value: -offset, to: today) {
                    let salesNumber = sales.filter {
                        guard let dateString = $0["Begin Date"] else { return false }
                        guard let date = dateParser.date(from: dateString) else { return false }
                        return date == day
                    }
                    .map { Int($0["Units"] ?? "0") ?? 0 }
                    .reduce(0, +)
                    chartData.append((dateFormatter.string(from: day), salesNumber))
                }
            }
        case .monthly:
            xLabel = "Day"
            if let selectedYear, let selectedMonth {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd"
                let yearSales = sales.filter {
                    guard let dateString = $0["Begin Date"] else { return false }
                    guard let date = dateParser.date(from: dateString) else { return false }
                    return Calendar.current.component(.year, from: date) == selectedYear
                }
                for day in datesIn(month: selectedMonth, year: selectedYear) {
                    let salesNumber = yearSales.filter {
                        guard let dateString = $0["Begin Date"] else { return false }
                        guard let date = dateParser.date(from: dateString) else { return false }
                        return date == day
                    }
                    .map { Int($0["Units"] ?? "0") ?? 0 }
                    .reduce(0, +)
                    chartData.append((dateFormatter.string(from: day), salesNumber))
                }
            }
        case .yearly:
            xLabel = "Month"
            if let selectedYear {
                let yearSales = sales.filter {
                    guard let dateString = $0["Begin Date"] else { return false }
                    guard let date = dateParser.date(from: dateString) else { return false }
                    return Calendar.current.component(.year, from: date) == selectedYear
                }
                for month in 1...12 {
                    let salesNumber = yearSales.filter {
                        guard let dateString = $0["Begin Date"] else { return false }
                        guard let date = dateParser.date(from: dateString) else { return false }
                        return Calendar.current.component(.month, from: date) == month
                    }
                    .map { Int($0["Units"] ?? "0") ?? 0 }
                    .reduce(0, +)
                    chartData.append((dateParser.monthSymbols[month - 1], salesNumber))
                }
            }
        }
    }

    var body: some View {
        Chart {
            ForEach(chartData, id: \.0) { month, sales in
                BarMark(
                    x: .value(xLabel, month),
                    y: .value("Sales", sales)
                )
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let stringValue = value.as(String.self) {
                        Text(stringValue)
                            .rotationEffect(.degrees(selectedPeriod == .monthly ? 0: -90))
                            .fixedSize()
                            .frame(height: frameHeightForPeriod)
                    }
                }
            }
        }
    }

    private var frameHeightForPeriod: CGFloat {
        switch selectedPeriod {
        case .lastThirtyDays:
            return 80
        case .monthly:
            return 20
        case .yearly:
            return 60
        }
    }

    private func datesIn(month: Int, year: Int) -> [Date] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let dateComponents = DateComponents(year: year, month: month)
        guard let startDate = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(from: DateComponents(year: year, month: month, day: day))
        }
    }
}

#Preview {
    SalesChartView(sales: [], selectedPeriod: .lastThirtyDays, selectedYear: nil, selectedMonth: nil)
}
