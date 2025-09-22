//
//  Formatters.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation

extension Double {
    // Sửa lỗi: Đã thêm dấu cách giữa "func" và "formattedAsCurrency"
    func formattedAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN") // Vietnamese locale for "đ" symbol
        formatter.maximumFractionDigits = 0 // No decimal part for VNĐ
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
