//
// SalesPeriodSelectionView.swift
// ShipShape
// https://www.github.com/twostraws/ShipShape
// See LICENSE for license information.
//

import SwiftUI

struct SalesPeriodSelectionView: View {

    private var sales: [[String: String]]

    let dateFormatter = DateFormatter()

    let firstDate: Date
    let lastDate: Date

    @Binding var period: ReportingPeriod?
    @Binding var selectedYear: Int?
    @Binding var selectedMonth: Int?

    init(sales: [[String: String]], period: Binding<ReportingPeriod?>, year: Binding<Int?>, month: Binding<Int?>) {
        self.sales = sales
        self._period = period
        self._selectedYear = year
        self._selectedMonth = month

        let dateParser: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MM/dd/yyyy"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }()

        let allDates = sales
            .map { $0["Begin Date"] }
            .filter { $0 != nil }
            .map { dateParser.date(from: $0!) }
            .filter { $0 != nil }
            .map { $0!}
        self.firstDate = allDates.min() ?? Date()
        self.lastDate = allDates.max() ?? Date()
    }

    var body: some View {
        HStack {
            Picker("", selection: $period) {
                Text("Yearly").tag(ReportingPeriod.yearly)
                Text("Monthly").tag(ReportingPeriod.monthly)
                Text("Last 30 days").tag(ReportingPeriod.lastThirtyDays)
            }
            Picker("", selection: $selectedYear) {
                ForEach(yearsBetween(start: firstDate, end: lastDate), id: \.self) {
                    Text(String($0)).tag($0)
                }
            }.opacity((period == .yearly || period == .monthly) ? 1.0: 0.0)
            Picker("", selection: $selectedMonth) {
                ForEach(monthsInYear(selectedYear ?? 2025, start: firstDate, end: lastDate), id: \.self) {
                    Text(dateFormatter.monthSymbols[$0 - 1]).tag($0)
                }
            }.opacity(period == .monthly ? 1.0 : 0.0)
        }
    }

    private func yearsBetween(start: Date, end: Date) -> [Int] {
        let calendar = Calendar.current
        guard let startYear = calendar.dateComponents([.year], from: start).year,
              let endYear = calendar.dateComponents([.year], from: end).year else {
            return []
        }

        return Array(startYear...endYear)
    }

    private func monthsInYear(_ year: Int, start: Date, end: Date) -> [Int] {
        let calendar = Calendar.current
        let rangeStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
        let rangeEnd = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!

        // Clamp the range to the overall start and end
        let effectiveStart = max(start, rangeStart)
        let effectiveEnd = min(end, rangeEnd)

        guard effectiveStart <= effectiveEnd else { return [] }

        let startMonth = calendar.component(.month, from: effectiveStart)
        let endMonth = calendar.component(.month, from: effectiveEnd)

        return Array(startMonth...endMonth)
    }

}

#Preview {
    SalesPeriodSelectionView(sales: [], period: .constant(.lastThirtyDays), year: .constant(nil), month: .constant(nil))
}
