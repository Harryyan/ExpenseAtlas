import Foundation
import PDFKit
import SwiftData

struct PDFStatementProcessor: StatementProcessing {
    private let aiRepository: AIRepositoryProtocol

    init(aiRepository: AIRepositoryProtocol) {
        self.aiRepository = aiRepository
    }

    func generateTransactions(for doc: StatementDoc) async throws -> [Transaction] {
        // Extract text from PDF
        guard let fileURL = doc.fileURL else {
            throw ProcessingError.invalidPDFFormat
        }

        guard let pdfText = extractTextFromPDF(at: fileURL) else {
            throw ProcessingError.failedToExtractText
        }

        // Truncate if too long (Foundation Models has token limits)
        let truncatedText = String(pdfText.prefix(8000))

        // Use Foundation Models to extract structured transaction data
        let result = await aiRepository.extractTransactions(from: truncatedText)

        switch result {
        case .success(let extractedTransactions):
            // Convert extracted data to Transaction models
            return extractedTransactions.map { extracted in
                // Determine currency from extraction or detect from text
                let currency = extracted.currency ?? detectCurrency(from: pdfText) ?? "NZD"

                return Transaction(
                    date: parseDate(extracted.date) ?? Date(),
                    amount: Decimal(string: extracted.amount) ?? 0,
                    currency: currency,
                    direction: extracted.type.lowercased().contains("debit") || extracted.amount.hasPrefix("-") ? .debit : .credit,
                    rawDescription: extracted.description,
                    merchant: extractMerchantName(from: extracted.description),
                    category: .unknown,
                    document: doc
                )
            }
        case .failure(let error):
            // Fallback to demo data if AI extraction fails
            print("AI extraction failed: \(error), using fallback parser")
            return try fallbackParse(pdfText: pdfText, doc: doc)
        }
    }

    private func extractTextFromPDF(at url: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: url) else {
            return nil
        }

        var fullText = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            if let pageText = page.string {
                fullText += pageText + "\n"
            }
        }

        return fullText.isEmpty ? nil : fullText
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = [
            {
                let df = DateFormatter()
                df.dateFormat = "dd/MM/yyyy"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "MM/dd/yyyy"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                return df
            }(),
            {
                let df = DateFormatter()
                df.dateFormat = "d MMM yyyy"
                return df
            }()
        ]

        for formatter in formatters {
            if let date = formatter.date(from: dateString.trimmingCharacters(in: .whitespaces)) {
                return date
            }
        }

        return nil
    }

    private func extractMerchantName(from description: String) -> String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)

        // For transfers, return the full description to preserve account details
        if trimmed.lowercased().contains("transfer from:") ||
           trimmed.lowercased().contains("transfer to:") ||
           trimmed.lowercased().contains("transfer from") ||
           trimmed.lowercased().contains("transfer to") {
            return trimmed
        }

        // For regular merchants, extract first few meaningful words
        let cleaned = description
            .replacingOccurrences(of: "DEBIT", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "CREDIT", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Take up to 4 words for merchant name (more generous than before)
        let words = cleaned.components(separatedBy: .whitespaces)
        let meaningfulWords = words.filter { !$0.isEmpty && $0.count > 1 }

        if meaningfulWords.isEmpty {
            return trimmed
        }

        return meaningfulWords.prefix(4).joined(separator: " ")
    }

    private func detectCurrency(from text: String) -> String? {
        // Common currency patterns in order of specificity
        let patterns = [
            "NZD", "NZ\\$", "\\$NZ",  // New Zealand Dollar
            "AUD", "AU\\$", "\\$AU",  // Australian Dollar
            "USD", "US\\$", "\\$US",  // US Dollar
            "EUR", "€",               // Euro
            "GBP", "£",               // British Pound
            "CAD", "CA\\$", "\\$CA",  // Canadian Dollar
            "CNY", "¥", "RMB"         // Chinese Yuan
        ]

        let currencyMap: [String: String] = [
            "NZD": "NZD", "NZ$": "NZD", "$NZ": "NZD",
            "AUD": "AUD", "AU$": "AUD", "$AU": "AUD",
            "USD": "USD", "US$": "USD", "$US": "USD",
            "EUR": "EUR", "€": "EUR",
            "GBP": "GBP", "£": "GBP",
            "CAD": "CAD", "CA$": "CAD", "$CA": "CAD",
            "CNY": "CNY", "¥": "CNY", "RMB": "CNY"
        ]

        // Check first 2000 characters for currency indicators
        let searchText = String(text.prefix(2000))

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: searchText, range: NSRange(searchText.startIndex..., in: searchText)),
               let range = Range(match.range, in: searchText) {
                let matched = String(searchText[range])
                if let currency = currencyMap[matched] ?? currencyMap[matched.uppercased()] {
                    return currency
                }
            }
        }

        return nil
    }

    private func fallbackParse(pdfText: String, doc: StatementDoc) throws -> [Transaction] {
        // Simple fallback: look for lines with amounts
        var transactions: [Transaction] = []
        let lines = pdfText.components(separatedBy: .newlines)
        let detectedCurrency = detectCurrency(from: pdfText) ?? "NZD"

        for line in lines {
            // Look for patterns like: "date description amount"
            // This is a very basic parser - adjust based on your bank's format
            if let amount = extractAmount(from: line),
               let date = extractDate(from: line) {
                let description = line
                    .replacingOccurrences(of: date, with: "")
                    .replacingOccurrences(of: amount, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if !description.isEmpty {
                    let transaction = Transaction(
                        date: parseDate(date) ?? Date(),
                        amount: Decimal(string: amount.replacingOccurrences(of: ",", with: "")) ?? 0,
                        currency: detectedCurrency,
                        direction: amount.hasPrefix("-") ? .debit : .credit,
                        rawDescription: description,
                        merchant: extractMerchantName(from: description),
                        category: .unknown,
                        document: doc
                    )
                    transactions.append(transaction)
                }
            }
        }

        return transactions
    }

    private func extractAmount(from line: String) -> String? {
        // Regex to match amounts like: 123.45, -123.45, 1,234.56
        let pattern = #"-?\d{1,3}(,\d{3})*\.?\d{0,2}"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            if let range = Range(match.range, in: line) {
                return String(line[range])
            }
        }
        return nil
    }

    private func extractDate(from line: String) -> String? {
        // Regex to match dates like: 01/02/2026, 2026-01-02, 1 Feb 2026
        let patterns = [
            #"\d{1,2}/\d{1,2}/\d{4}"#,
            #"\d{4}-\d{1,2}-\d{1,2}"#,
            #"\d{1,2}\s+[A-Za-z]{3}\s+\d{4}"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                if let range = Range(match.range, in: line) {
                    return String(line[range])
                }
            }
        }
        return nil
    }
}

enum ProcessingError: Error {
    case failedToExtractText
    case invalidPDFFormat
}
