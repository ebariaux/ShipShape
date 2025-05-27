//
// SalesReportsView.swift
// ShipShape
// https://www.github.com/twostraws/ShipShape
// See LICENSE for license information.
//

import SwiftGzip
import SwiftUI

enum ReportingPeriod {
    case yearly, monthly, lastThirtyDays
}

struct SalesReportsView: View {
    @State private var loadState = LoadState.loading

    var app: ASCApp
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    @State private var sales = [[String: String]]()

    @State private var firstDate = Date()
    @State private var lastDate = Date()
    @State private var totalSales = 0

    @State private var selectedPeriod: ReportingPeriod? = .lastThirtyDays
    @State private var selectedYear: Int? = 2025
    @State private var selectedMonth: Int? = 1

    var body: some View {
        // TODO: removing this lines makes the view not properly update
        SalesSummaryView(sales: sales)
        LoadingView(loadState: $loadState, retryAction: load) {
            VStack {
                SalesSummaryView(sales: sales)
                Form {

                    SalesPeriodSelectionView(sales: sales, period: $selectedPeriod, year: $selectedYear, month: $selectedMonth)
                        .padding([.bottom, .horizontal])
                }

                if let selectedPeriod {
                    SalesChartView(sales: sales, selectedPeriod: selectedPeriod, selectedYear: selectedYear, selectedMonth: selectedMonth)
                        .padding([.bottom, .horizontal])
                } else {
                    Text("Please select a valid period")
                }
            }
        }
        .task(load)
    }

    private func load() async {
        loadState = .loading
        do {
            try await parseAllReports()
            loadState = .loaded
        } catch {
            print(error.localizedDescription)
            loadState = .failed
        }
    }

    private func parseAllReports() async throws {
        let reportType = "SALES"
        let reportSubType = "SUMMARY"
        let reportFrequency = "DAILY"

        let fileManager = FileManager.default
        let files = try fileManager.contentsOfDirectory(at: URL(filePath: "."), includingPropertiesForKeys: nil)

        let pattern = #"SalesReport-\#(reportType)-\#(reportSubType)-\#(reportFrequency)-.*\.txt\.gz"#
        let regex = try NSRegularExpression(pattern: pattern)


        var allSales = [[String: String]]()

        for fileURL in files {
            let fileName = fileURL.lastPathComponent
            if regex.firstMatch(in: fileName, range: NSRange(fileName.startIndex..., in: fileName)) != nil {
                try await allSales.append(contentsOf: parseSalesReport(from: fileURL))
            }
        }
        print(allSales)

        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "MM/dd/yyyy"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter
        }()

        let allDates: [Date] = allSales
            .map { $0["Begin Date"] }
            .filter { $0 != nil }
            .map { dateFormatter.date(from: $0!) }
            .filter { $0 != nil }
            .map { $0!}
        print(allDates)
        firstDate = allDates.min() ?? Date()
        lastDate = allDates.max() ?? Date()
        totalSales = allSales
            .map { Int($0["Units"] ?? "0") ?? 0 }
            .reduce(0, +)

        sales = allSales
    }

    private func parseSalesReport(from fileURL: URL) async throws -> [[String: String]] {
        let decompressor = GzipDecompressor()

        let compressedData = try Data(contentsOf: fileURL)
        print("Read content of \(fileURL)")

        // TODO: optimize for // processing
        // try? await Task.sleep(for: .seconds(3))

        let decompressedData = try await decompressor.unzip(data: compressedData)
        let content = String(data: decompressedData, encoding: .utf8)
        if let content {
            let linesContent = content.split(separator: "\n").map { line in
                line.split(separator: "\t")
            }
            guard !linesContent.isEmpty else { return [] }
            let headers = linesContent.first!.map { String($0) }
            return linesContent.dropFirst().reduce(into: []) { result, line in
                let info = zip(headers, line).reduce(into: [String: String]()) {
                    $0[$1.0] = String($1.1)
                }
                if info["SKU"] == app.attributes.sku {
                    result.append(info)
                }
            }
        }
        return []
    }
}

#Preview {
    SalesReportsView(app: ASCApp.example)
}
