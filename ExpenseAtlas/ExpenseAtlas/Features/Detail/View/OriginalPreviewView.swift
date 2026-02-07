import SwiftUI

struct OriginalPreviewView: View {
    let doc: StatementDoc

    var body: some View {
        Group {
            switch doc.fileType {
            case .pdf:
                PDFPreviewView(url: doc.fileURL)
            case .csv:
                CSVPreviewView(vm: CSVPreviewViewModel(url: doc.fileURL))
            default:
                FileInfoView(doc: doc)
            }
        }
    }
}
