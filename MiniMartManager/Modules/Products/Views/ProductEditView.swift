import SwiftUI
import SwiftData
import PhotosUI

struct ProductEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var availableAttributes: [ProductAttribute]
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Supplier.name) private var suppliers: [Supplier]
    
    var productToEdit: Product?
    
    // State cho các thông tin sản phẩm
    @State private var name: String = ""
    @State private var sku: String = ""
    @State private var unit: String = ""
    @State private var barcode: String = ""
    @State private var costPrice: Double = 0.0
    @State private var retailPrice: Double = 0.0
    @State private var wholesalePrice: Double = 0.0
    @State private var stockQuantity: Int = 0
    @State private var minimumStockLevel: Int = 0
    @State private var selectedCategory: Category?
    @State private var selectedSupplier: Supplier?
    
    // STATE MỚI: Dành cho việc chọn ảnh
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var productImageData: Data?

    // State cho các sheet phụ
    @State private var isShowingAddUnitSheet = false
    @State private var isShowingAddAttributeSheet = false
    @State private var selectedUnitToEdit: ProductUnit?
    @State private var selectedAttributeValueToEdit: ProductAttributeValue?

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !unit.trimmingCharacters(in: .whitespaces).isEmpty &&
        retailPrice > 0
    }
    
    private var navigationTitle: String {
        productToEdit == nil ? "Thêm Sản Phẩm Mới" : "Sửa Thông Tin Sản Phẩm"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section cho hình ảnh sản phẩm
                Section(header: Text("Hình ảnh sản phẩm")) {
                    productImageView
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Chọn ảnh mới", systemImage: "photo.on.rectangle")
                    }
                    if productImageData != nil {
                        Button("Xóa ảnh hiện tại", systemImage: "trash", role: .destructive) {
                            selectedPhoto = nil
                            productImageData = nil
                        }
                    }
                }
                
                Section(header: Text("Thông tin cơ bản")) {
                    TextField("Tên sản phẩm (bắt buộc)", text: $name)
                    TextField("Đơn vị tính cơ bản (VD: cái, kg, hộp)", text: $unit)
                    Picker("Danh mục", selection: $selectedCategory) {
                        Text("Chưa phân loại").tag(Category?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(category as Category?)
                        }
                    }
                    Picker("Nhà cung cấp", selection: $selectedSupplier) {
                        Text("Chưa chọn").tag(Supplier?.none)
                        ForEach(suppliers) { supplier in
                            Text(supplier.name).tag(supplier as Supplier?)
                        }
                    }
                }
                
                Section(header: Text("Mã vạch")) {
                    HStack {
                        TextField("Barcode (nếu có)", text: $barcode)
                        if !barcode.isEmpty, let barcodeImage = BarcodeGenerator.generate(from: barcode) {
                            Image(uiImage: barcodeImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                        }
                    }
                }
                
                Section(header: Text("Giá & Tồn kho")) {
                    TextField("Giá vốn", value: $costPrice, formatter: numberFormatter).keyboardType(.decimalPad)
                    TextField("Giá bán lẻ", value: $retailPrice, formatter: numberFormatter).keyboardType(.decimalPad)
                    TextField("Giá bán sỉ", value: $wholesalePrice, formatter: numberFormatter).keyboardType(.decimalPad)
                    if productToEdit == nil {
                        TextField("Số lượng tồn kho ban đầu", value: $stockQuantity, formatter: numberFormatter).keyboardType(.numberPad)
                    }
                    TextField("Mức tồn kho tối thiểu", value: $minimumStockLevel, formatter: numberFormatter).keyboardType(.numberPad)
                }
                
                if let product = productToEdit {
                    Section(header: Text("Đơn vị tính quy đổi")) {
                        ForEach(product.alternativeUnits) { unit in
                            Button { selectedUnitToEdit = unit; isShowingAddUnitSheet = true } label: {
                                HStack {
                                    Text("\(unit.name)").foregroundColor(.primary)
                                    Spacer()
                                    Text("1 \(unit.name) = \(unit.conversionFactor) \(product.unit)").foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteUnit)
                        
                        Button("Thêm đơn vị mới", systemImage: "plus") {
                            selectedUnitToEdit = nil
                            isShowingAddUnitSheet = true
                        }
                    }
                    
                    Section(header: Text("Thuộc tính")) {
                        ForEach(product.customAttributes) { attrValue in
                            Button { selectedAttributeValueToEdit = attrValue; isShowingAddAttributeSheet = true } label: {
                                HStack {
                                    Text(attrValue.attribute?.name ?? "N/A").foregroundColor(.primary)
                                    Spacer()
                                    Text(attrValue.value).foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteAttributeValue)
                        
                        Button("Thêm thuộc tính mới", systemImage: "plus") {
                            selectedAttributeValueToEdit = nil
                            isShowingAddAttributeSheet = true
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }.disabled(!isFormValid)
                }
            }
            .onAppear(perform: loadProductData)
            .sheet(isPresented: $isShowingAddUnitSheet) {
                if let product = productToEdit {
                    AddProductUnitView(product: product, unitToEdit: selectedUnitToEdit)
                }
            }
            .sheet(isPresented: $isShowingAddAttributeSheet) {
                if let product = productToEdit {
                    AddAttributeValueView(product: product, attributeValueToEdit: selectedAttributeValueToEdit)
                }
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                Task {
                    if let data = try? await newPhoto?.loadTransferable(type: Data.self) {
                        productImageData = data
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var productImageView: some View {
        HStack {
            Spacer()
            if let imageData = productImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
            } else {
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private func loadProductData() {
        if let product = productToEdit {
            name = product.name
            sku = product.sku
            unit = product.unit
            barcode = product.barcode
            costPrice = product.costPrice
            retailPrice = product.retailPrice
            wholesalePrice = product.wholesalePrice
            stockQuantity = product.stockQuantity
            minimumStockLevel = product.minimumStockLevel
            selectedCategory = product.category
            selectedSupplier = product.supplier
            productImageData = product.imageData
        }
    }
    
    private func save() {
        if let product = productToEdit {
            product.name = name
            product.sku = sku
            product.unit = unit
            product.barcode = barcode
            product.costPrice = costPrice
            product.retailPrice = retailPrice
            product.wholesalePrice = wholesalePrice
            product.minimumStockLevel = minimumStockLevel
            product.category = selectedCategory
            // SỬA LỖI TẠI ĐÂY: Sử dụng đúng tên biến "selectedSupplier"
            product.supplier = selectedSupplier
            product.imageData = productImageData
        } else {
            let newProduct = Product(
                name: name, barcode: barcode, sku: sku, unit: unit,
                costPrice: costPrice, retailPrice: retailPrice, wholesalePrice: wholesalePrice,
                stockQuantity: stockQuantity,
                minimumStockLevel: minimumStockLevel,
                imageData: productImageData,
                category: selectedCategory,
                supplier: selectedSupplier
            )
            modelContext.insert(newProduct)
        }
        dismiss()
    }
    
    private func deleteUnit(at offsets: IndexSet) {
        if let product = productToEdit {
            for index in offsets {
                modelContext.delete(product.alternativeUnits[index])
            }
        }
    }
    
    private func deleteAttributeValue(at offsets: IndexSet) {
        if let product = productToEdit {
            for index in offsets {
                modelContext.delete(product.customAttributes[index])
            }
        }
    }
}


// VIEW PHỤ ĐỂ THÊM/SỬA GIÁ TRỊ THUỘC TÍNH (Không thay đổi)
struct AddAttributeValueView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var availableAttributes: [ProductAttribute]
    
    let product: Product
    let attributeValueToEdit: ProductAttributeValue?
    
    @State private var selectedAttribute: ProductAttribute?
    @State private var value: String = ""
    
    var isFormValid: Bool {
        selectedAttribute != nil && !value.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var navigationTitle: String {
        attributeValueToEdit == nil ? "Thêm giá trị thuộc tính" : "Sửa giá trị thuộc tính"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Loại thuộc tính", selection: $selectedAttribute) {
                    Text("Chọn...").tag(ProductAttribute?.none)
                    ForEach(availableAttributes) { attr in
                        Text(attr.name).tag(attr as ProductAttribute?)
                    }
                }
                .disabled(attributeValueToEdit != nil)
                
                TextField("Giá trị (VD: Đỏ, XL, 12)", text: $value)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }.disabled(!isFormValid)
                }
            }
            .onAppear {
                if let attrValue = attributeValueToEdit {
                    selectedAttribute = attrValue.attribute
                    value = attrValue.value
                } else {
                    selectedAttribute = availableAttributes.first
                }
            }
        }
    }
    
    private func save() {
        if let attrValue = attributeValueToEdit {
            attrValue.value = value
        } else {
            guard let attribute = selectedAttribute else { return }
            let newValue = ProductAttributeValue(value: value, product: product, attribute: attribute)
            modelContext.insert(newValue)
        }
        dismiss()
    }
}
