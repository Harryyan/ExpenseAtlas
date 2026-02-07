import SwiftUI

struct FileInfoView: View {
    let doc: StatementDoc

    var body: some View {
        List {
            LabeledContent("File", value: doc.originalFileName)
            LabeledContent("Type", value: doc.fileType.rawValue.uppercased())
            LabeledContent("Status", value: doc.status.rawValue)
            LabeledContent("Imported", value: doc.importedAt.formatted())
            if doc.fileSize > 0 {
                LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: doc.fileSize, countStyle: .file))
            }
        }
    }
}
