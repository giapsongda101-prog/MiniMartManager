import Foundation
import SwiftData

@Model
final class ExchangeRate {
    var id: UUID
    var fromCurrency: String
    var toCurrency: String
    var rate: Double
    var lastUpdatedDate: Date

    init(fromCurrency: String, toCurrency: String, rate: Double) {
        self.id = UUID()
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self.rate = rate
        self.lastUpdatedDate = .now
    }
}

// Enum để định nghĩa các loại tiền tệ
enum Currency: String, CaseIterable, Identifiable {
    case VND = "VNĐ"
    case LAK = "LAK"
    case BATH = "BATH"
    case USD = "USD"

    var id: String { self.rawValue }
}
