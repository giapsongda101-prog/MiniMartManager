//
//  ProductAttribute.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

// Dùng để định nghĩa các loại thuộc tính có thể có, ví dụ: "Màu sắc", "Size", "Bảo hành (tháng)"
@Model
final class ProductAttribute {
    @Attribute(.unique) var id: UUID
    var name: String // Ví dụ: "Màu sắc"
    
    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
