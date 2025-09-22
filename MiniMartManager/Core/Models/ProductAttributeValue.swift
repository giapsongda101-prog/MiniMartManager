//
//  ProductAttributeValue.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import Foundation
import SwiftData

// Dùng để lưu giá trị cụ thể của một thuộc tính cho một sản phẩm
// Ví dụ: sản phẩm "Áo Thun" có thuộc tính "Màu sắc" với giá trị "Đỏ"
@Model
final class ProductAttributeValue {
    @Attribute(.unique) var id: UUID
    var value: String // Ví dụ: "Đỏ", "XL", "12"
    
    // Relationship: Thuộc tính này của sản phẩm nào
    var product: Product?
    
    // Relationship: Đây là giá trị cho loại thuộc tính nào
    var attribute: ProductAttribute?
    
    init(id: UUID = UUID(), value: String, product: Product? = nil, attribute: ProductAttribute? = nil) {
        self.id = id
        self.value = value
        self.product = product
        self.attribute = attribute
    }
}
