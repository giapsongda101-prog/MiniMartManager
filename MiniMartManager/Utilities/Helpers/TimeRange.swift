// MiniMartManager/Utilities/Helpers/TimeRange.swift
import Foundation

// Enum để chọn khoảng thời gian báo cáo, có thể được sử dụng bởi nhiều View khác nhau
enum TimeRange: String, CaseIterable, Identifiable {
    case today = "Hôm nay"
    case last7Days = "7 Ngày Qua"
    case last30Days = "30 Ngày Qua"
    case thisWeek = "Tuần này"
    case thisMonth = "Tháng này"
    case thisYear = "Năm nay"
    case custom = "Tùy chỉnh"
    var id: Self { self }
}
