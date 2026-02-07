import SwiftUI

struct CSVTableView: View {
    let rows: [[String]]

    private var headers: [String] {
        rows.first ?? []
    }

    private var dataRows: [[String]] {
        Array(rows.dropFirst())
    }

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(dataRows.indices, id: \.self) { rowIndex in
                        HStack(spacing: 0) {
                            ForEach(dataRows[rowIndex].indices, id: \.self) { colIndex in
                                Text(dataRows[rowIndex][colIndex])
                                    .frame(minWidth: 100, alignment: .leading)
                                    .padding(8)
                                    .background(rowIndex % 2 == 0 ? Color.clear : Color.secondary.opacity(0.1))
                            }
                        }
                        Divider()
                    }
                } header: {
                    HStack(spacing: 0) {
                        ForEach(headers.indices, id: \.self) { index in
                            Text(headers[index])
                                .font(.headline)
                                .frame(minWidth: 100, alignment: .leading)
                                .padding(8)
                        }
                    }
                    .background(.regularMaterial)
                }
            }
        }
    }
}
