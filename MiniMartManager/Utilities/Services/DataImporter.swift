// MiniMartManager/Utilities/Services/DataImporter.swift

import SwiftUI
import SwiftData
import CoreXLSX
import UniformTypeIdentifiers

@MainActor
class DataImporter {
    private let modelContext: ModelContext

    // Dùng để tra cứu nhanh, tránh query database liên tục
    private var categories: [String: Category] = [:]
    private var suppliers: [String: Supplier] = [:]
    private var attributes: [String: ProductAttribute] = [:]

    enum ImportError: LocalizedError {
        case fileCouldNotBeOpened
        case sheetNotFound(String)
        case columnHeaderNotFound(String, inSheet: String)
        case missingRequiredValue(String, row: Int)
        case invalidDataFormat(String, row: Int)
        case referencedObjectNotFound(String, name: String, row: Int)

        var errorDescription: String? {
            switch self {
            case .fileCouldNotBeOpened:
                return "Không thể mở hoặc phân tích cấu trúc file Excel."
            case .sheetNotFound(let sheetName):
                return "Không tìm thấy trang tính (sheet) '\(sheetName)' trong file."
            case .columnHeaderNotFound(let column, let sheet):
                return "Không tìm thấy cột '\(column)' trong trang tính '\(sheet)'."
            case .missingRequiredValue(let column, let row):
                return "Giá trị bắt buộc bị thiếu ở cột '\(column)', dòng \(row)."
            case .invalidDataFormat(let column, let row):
                return "Định dạng dữ liệu không hợp lệ ở cột '\(column)', dòng \(row)."
            case .referencedObjectNotFound(let type, let name, let row):
                return "Không tìm thấy \(type) có tên '\(name)' đã được định nghĩa trước (dòng \(row))."
            }
        }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func `import`(from url: URL) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw ImportError.fileCouldNotBeOpened
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let file = XLSXFile(filepath: url.path) else {
            throw ImportError.fileCouldNotBeOpened
        }
        
        guard let sharedStrings = try file.parseSharedStrings() else {
            throw ImportError.fileCouldNotBeOpened
        }

        try loadExistingData()

        try parseAndInsert(from: file, sharedStrings: sharedStrings, sheetName: "DanhMuc") { rowData in
            let name = try self.stringValue(from: rowData, for: "Tên Danh Mục", row: rowData.row)
            if self.categories[name] == nil {
                let newCategory = Category(name: name)
                self.modelContext.insert(newCategory)
                self.categories[name] = newCategory
            }
        }
        
        try parseAndInsert(from: file, sharedStrings: sharedStrings, sheetName: "NhaCungCap") { rowData in
            let name = try self.stringValue(from: rowData, for: "Tên Nhà Cung Cấp", row: rowData.row)
            if self.suppliers[name] == nil {
                let phone = self.stringValue(from: rowData, for: "Số Điện Thoại") ?? ""
                let address = self.stringValue(from: rowData, for: "Địa Chỉ") ?? ""
                let newSupplier = Supplier(name: name, phone: phone, address: address)
                self.modelContext.insert(newSupplier)
                self.suppliers[name] = newSupplier
            }
        }

        try parseAndInsert(from: file, sharedStrings: sharedStrings, sheetName: "ThuocTinh") { rowData in
            let name = try self.stringValue(from: rowData, for: "Tên Thuộc Tính", row: rowData.row)
            if self.attributes[name] == nil {
                let newAttribute = ProductAttribute(name: name)
                self.modelContext.insert(newAttribute)
                self.attributes[name] = newAttribute
            }
        }
        
        try parseAndInsert(from: file, sharedStrings: sharedStrings, sheetName: "KhachHang") { rowData in
            let name = try self.stringValue(from: rowData, for: "Tên Khách Hàng", row: rowData.row)
            let phone = self.stringValue(from: rowData, for: "Số Điện Thoại") ?? ""
            
            // SỬA LỖI: Cập nhật logic kiểm tra khách hàng trùng lặp
            let fetchDescriptor: FetchDescriptor<Customer>
            if phone.isEmpty {
                // Nếu không có SĐT, chỉ cần tên trùng là đủ
                fetchDescriptor = FetchDescriptor<Customer>(predicate: #Predicate { $0.name == name && $0.phone == "" })
            } else {
                // Nếu có SĐT, cả tên và SĐT phải trùng
                fetchDescriptor = FetchDescriptor<Customer>(predicate: #Predicate { $0.name == name && $0.phone == phone })
            }
            
            let existingCustomersCount = try self.modelContext.fetchCount(fetchDescriptor)
            
            // Chỉ thêm nếu chưa có khách hàng nào khớp
            if existingCustomersCount == 0 {
                let newCustomer = Customer(name: name, phone: phone)
                self.modelContext.insert(newCustomer)
            }
        }
        
        try importProducts(from: file, sharedStrings: sharedStrings)
        
        try modelContext.save()
    }

    private func parseAndInsert(from file: XLSXFile, sharedStrings: SharedStrings, sheetName: String, createEntity: @escaping (RowData) throws -> Void) throws {
        guard let workbook = try file.parseWorkbooks().first else {
            throw ImportError.fileCouldNotBeOpened
        }

        guard let worksheetPath = try file.parseWorksheetPathsAndNames(workbook: workbook).first(where: { $0.name == sheetName })?.path else {
            throw ImportError.sheetNotFound(sheetName)
        }

        let worksheet = try file.parseWorksheet(at: worksheetPath)
        
        let headers = worksheet.data?.rows.first?.cells.map { $0.stringValue(sharedStrings) ?? "" } ?? []
        
        for row in worksheet.data?.rows.dropFirst() ?? [] {
            var rowData = RowData(row: Int(row.reference), headers: headers)
            for (index, cell) in row.cells.enumerated() {
                if index < headers.count {
                    rowData.values[headers[index]] = cell.stringValue(sharedStrings)
                }
            }
            try createEntity(rowData)
        }
    }

    private func importProducts(from file: XLSXFile, sharedStrings: SharedStrings) throws {
        try parseAndInsert(from: file, sharedStrings: sharedStrings, sheetName: "SanPham") { rowData in
            let sku = try self.stringValue(from: rowData, for: "Mã SKU", row: rowData.row)
            
            let product: Product
            
            let fetchDescriptor = FetchDescriptor<Product>(predicate: #Predicate { $0.sku == sku })
            if let existingProduct = try? self.modelContext.fetch(fetchDescriptor).first {
                product = existingProduct
            } else {
                let newProduct = Product(
                    name: "", sku: sku, unit: "", costPrice: 0, retailPrice: 0
                )
                self.modelContext.insert(newProduct)
                product = newProduct
            }

            product.name = try self.stringValue(from: rowData, for: "Tên Sản Phẩm", row: rowData.row)
            product.unit = try self.stringValue(from: rowData, for: "Đơn Vị Tính", row: rowData.row)
            product.costPrice = try self.doubleValue(from: rowData, for: "Giá Vốn", row: rowData.row)
            product.retailPrice = try self.doubleValue(from: rowData, for: "Giá Bán Lẻ", row: rowData.row)
            product.wholesalePrice = self.doubleValue(from: rowData, for: "Giá Bán Sỉ") ?? 0.0
            product.barcode = self.stringValue(from: rowData, for: "Barcode") ?? ""
            
            if let stock = self.intValue(from: rowData, for: "Tồn Kho Ban Đầu") {
                 product.stockQuantity = stock
            }
            
            // DÒNG THAY ĐỔI: Nhập giá trị cho mức tồn kho tối thiểu
            if let minimumStockLevel = self.intValue(from: rowData, for: "Mức tồn kho tối thiểu") {
                product.minimumStockLevel = minimumStockLevel
            }
            
            if let categoryName = self.stringValue(from: rowData, for: "Tên Danh Mục"), !categoryName.isEmpty {
                guard let foundCategory = self.categories[categoryName] else {
                    throw ImportError.referencedObjectNotFound("Danh mục", name: categoryName, row: rowData.row)
                }
                product.category = foundCategory
            }

            if let supplierName = self.stringValue(from: rowData, for: "Tên Nhà Cung Cấp"), !supplierName.isEmpty {
                 guard let foundSupplier = self.suppliers[supplierName] else {
                    throw ImportError.referencedObjectNotFound("Nhà cung cấp", name: supplierName, row: rowData.row)
                }
                product.supplier = foundSupplier
            }
            
            // Xóa các đơn vị và thuộc tính cũ để nhập lại
            product.alternativeUnits.removeAll()
            product.customAttributes.removeAll()

            if let unitsString = self.stringValue(from: rowData, for: "Đơn Vị Quy Đổi"), !unitsString.isEmpty {
                let unitPairs = unitsString.components(separatedBy: ";")
                for pair in unitPairs {
                    let components = pair.components(separatedBy: ":")
                    if components.count == 2, let factor = Int(components[1].trimmingCharacters(in: .whitespaces)) {
                        let unitName = components[0].trimmingCharacters(in: .whitespaces)
                        if !unitName.isEmpty {
                            let newUnit = ProductUnit(name: unitName, conversionFactor: factor, product: product)
                            self.modelContext.insert(newUnit)
                        }
                    }
                }
            }
            
            if let attrsString = self.stringValue(from: rowData, for: "Thuộc Tính"), !attrsString.isEmpty {
                 let attrPairs = attrsString.components(separatedBy: ";")
                 for pair in attrPairs {
                     let components = pair.components(separatedBy: ":")
                     if components.count == 2 {
                         let attrName = components[0].trimmingCharacters(in: .whitespaces)
                         let attrValue = components[1].trimmingCharacters(in: .whitespaces)
                         if let attribute = self.attributes[attrName] {
                             let newValue = ProductAttributeValue(value: attrValue, product: product, attribute: attribute)
                             self.modelContext.insert(newValue)
                         }
                     }
                 }
            }
        }
    }
    
    private func loadExistingData() throws {
        let existingCategories = try modelContext.fetch(FetchDescriptor<Category>())
        self.categories = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.name, $0) })
        
        let existingSuppliers = try modelContext.fetch(FetchDescriptor<Supplier>())
        self.suppliers = Dictionary(uniqueKeysWithValues: existingSuppliers.map { ($0.name, $0) })
        
        let existingAttributes = try modelContext.fetch(FetchDescriptor<ProductAttribute>())
        self.attributes = Dictionary(uniqueKeysWithValues: existingAttributes.map { ($0.name, $0) })
    }
    
    // MARK: - Helper Functions
    private func stringValue(from rowData: RowData, for header: String, row: Int) throws -> String {
        guard let value = rowData.values[header], !value.isEmpty else {
            throw ImportError.missingRequiredValue(header, row: row)
        }
        return value
    }
    
    private func stringValue(from rowData: RowData, for header: String) -> String? {
        return rowData.values[header]
    }
    
    private func doubleValue(from rowData: RowData, for header: String, row: Int) throws -> Double {
        let strValue = try stringValue(from: rowData, for: header, row: row)
        guard let value = Double(strValue.replacingOccurrences(of: ",", with: "")) else {
            throw ImportError.invalidDataFormat(header, row: row)
        }
        return value
    }

    private func doubleValue(from rowData: RowData, for header: String) -> Double? {
        guard let strValue = stringValue(from: rowData, for: header),
              let value = Double(strValue.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }
        return value
    }
    
    private func intValue(from rowData: RowData, for header: String) -> Int? {
        guard let strValue = stringValue(from: rowData, for: header),
              let value = Int(strValue.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }
        return value
    }

    private struct RowData {
        let row: Int
        let headers: [String]
        var values: [String: String] = [:]
    }
}
