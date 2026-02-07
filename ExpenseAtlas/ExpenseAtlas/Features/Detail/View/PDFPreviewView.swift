import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let url: URL?

    var body: some View {
        if let url, let pdfDocument = PDFDocument(url: url) {
            PDFKitView(document: pdfDocument)
        } else {
            ContentUnavailableView(
                "Unable to load PDF",
                systemImage: "doc.fill",
                description: Text("The file could not be opened.")
            )
        }
    }
}
