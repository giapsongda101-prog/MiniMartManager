import Foundation
import SwiftData

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var barcode: String
    var sku: String
    var unit: String
    var costPrice: Double
    var retailPrice: Double
    var wholesalePrice: Double
    var stockQuantity: Int
    var minimumStockLevel: Int = 0

    // DÒNG MỚI: Thêm thuộc tính để lưu dữ liệu ảnh
    // .externalStorage giúp SwiftData lưu các dữ liệu lớn (như ảnh) hiệu quả hơn
    @Attribute(.externalStorage) var imageData: Data?

    var category: Category?
    var supplier: Supplier?

    @Relationship(deleteRule: .cascade, inverse: \ProductAttributeValue.product)
    var customAttributes: [ProductAttributeValue] = []

    @Relationship(deleteRule: .cascade, inverse: \ProductUnit.product)
    var alternativeUnits: [ProductUnit] = []

    // CẬP NHẬT HÀM init
    init(id: UUID = UUID(),
         name: String,
         barcode: String = "",
         sku: String = "",
         unit: String,
         costPrice: Double,
         retailPrice: Double,
         wholesalePrice: Double = 0.0,
         stockQuantity: Int = 0,
         minimumStockLevel: Int = 0,
         imageData: Data? = nil, // Thêm imageData vào init
         category: Category? = nil,
         supplier: Supplier? = nil) {
        self.id = id
        self.name = name
        self.barcode = barcode
        self.sku = sku
        self.unit = unit
        self.costPrice = costPrice
        self.retailPrice = retailPrice
        self.wholesalePrice = wholesalePrice
        self.stockQuantity = stockQuantity
        self.minimumStockLevel = minimumStockLevel
        self.imageData = imageData // Gán giá trị cho imageData
        self.category = category
        self.supplier = supplier
    }
}
