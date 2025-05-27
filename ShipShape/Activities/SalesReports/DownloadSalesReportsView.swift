//
// DownloadSalesReportsView.swift
// ShipShape
// https://www.github.com/twostraws/ShipShape
// See LICENSE for license information.
//

import SwiftUI

struct DownloadSalesReportsView: View {
    var client: ASCClient

    @State private var vendorNumber: String = ""
    @State private var startDate: Date =  Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @State private var endDate: Date = Date()

    @State private var isLoading = false
    @State private var fetchingTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Group {
                TextField("Vendor number", text: $vendorNumber)
                DatePicker(selection: $startDate, in: ...Date.now, displayedComponents: .date) {
                    Text("Select start date")
                }
                DatePicker(selection: $endDate, in: startDate...Date.now, displayedComponents: .date) {
                    Text("Select end date")
                }
            }.disabled(isLoading)
            if isLoading {
                VStack {
                    ProgressView("Fetching reports...")
                }
            }

            HStack {
                Button("Cancel") {
                    fetchingTask?.cancel()
                    dismiss()
                }
                Button("Download") {
                    print("Downloading sales reports from \(startDate) to \(endDate)")
                    isLoading = true
                    fetchingTask = Task {
                        await fetchReportsConcurrently(vendorNumber: vendorNumber, startDate: startDate, endDate: endDate)
                        isLoading = false
                        dismiss()
                    }
                }.disabled(isLoading)
            }
        }
        .padding()
    }

    func fetchReportsConcurrently(vendorNumber: String, startDate: Date, endDate: Date) async {
        await withTaskGroup(of: Void.self) { group in
            var currentDate = startDate

            while currentDate <= endDate {
                let date = currentDate

                group.addTask {
                    do {
                        try await client.retrieveSalesReports(vendorNumber: vendorNumber, reportDate: date, skipExisting: true)
                    } catch {
                        print("Error on \(date): \(error)")
                    }
                }

                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
            }

            await group.waitForAll()
        }
    }
}

/*
#Preview {
    DownloadSalesReportsView()
}
*/
