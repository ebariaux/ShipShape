//
// SalesSummaryView.swift
// ShipShape
// https://www.github.com/twostraws/ShipShape
// See LICENSE for license information.
//

import SwiftUI

struct SalesSummaryView: View {

    private var sales: [[String: String]]

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    let firstDate: Date
    let lastDate: Date
    let totalSales: Int

    init(sales: [[String: String]]) {
        self.sales = sales

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
        self.totalSales = sales
            .map { Int($0["Units"] ?? "0") ?? 0 }
            .reduce(0, +)
    }

    var body: some View {
        Text("Total sales between \(firstDate, formatter: dateFormatter) and \(lastDate, formatter: dateFormatter): \(totalSales)")
    }
}

#Preview {
    SalesSummaryView(sales: [])
}
