//
//  ProductUnit.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

// Model để định nghĩa các đơn vị tính quy đổi cho một sản phẩm
@Model
final class ProductUnit {
    @Attribute(.unique) var id: UUID
    var name: String // Tên đơn vị quy đổi, ví dụ: "Lốc", "Thùng"
    var conversionFactor: Int // Hệ số quy đổi ra đơn vị cơ bản. Ví dụ: 1 Lốc = 6 Lon
    
    // Mối quan hệ: Đơn vị này thuộc về sản phẩm nào
    var product: Product?
    
    init(id: UUID = UUID(), name: String, conversionFactor: Int, product: Product? = nil) {
        self.id = id
        self.name = name
        self.conversionFactor = conversionFactor
        self.product = product
    }
}
