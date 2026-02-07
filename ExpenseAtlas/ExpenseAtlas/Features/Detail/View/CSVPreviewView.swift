import SwiftUI

struct CSVPreviewView: View {
    @State var vm: CSVPreviewViewModel

    var body: some View {
        Group {
            if let error = vm.loadError {
                ContentUnavailableView(
                    "Unable to load CSV",
                    systemImage: "tablecells",
                    description: Text(error)
                )
            } else if vm.rows.isEmpty {
                ProgressView("Loading...")
            } else {
                CSVTableView(rows: vm.rows)
            }
        }
        .task { vm.load() }
    }
}
