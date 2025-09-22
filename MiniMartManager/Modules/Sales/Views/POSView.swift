import SwiftUI
import SwiftData

// Enum để xác định loại giá
enum PriceType: String, CaseIterable, Identifiable {
    case retail = "Giá lẻ"
    case wholesale = "Giá sỉ"
    var id: Self { self }
}

// Struct để biểu diễn một đơn vị tính khi bán hàng
struct SalesUnit: Hashable, Identifiable {
    var id: String { name }
    let name: String
    let conversionFactor: Int
}

// Cấu trúc để quản lý một dòng trong giỏ hàng
struct CartItem: Identifiable, Equatable {
    var id: UUID = UUID()
    let product: Product
    var quantity: Int
    var priceType: PriceType = .wholesale
    var discount: Double = 0.0
    var selectedUnit: SalesUnit
    
    var availableUnits: [SalesUnit] {
        var units = [SalesUnit(name: product.unit, conversionFactor: 1)]
        let altUnits = product.alternativeUnits.sorted(by: { $0.conversionFactor < $1.conversionFactor })
        units.append(contentsOf: altUnits.map { SalesUnit(name: $0.name, conversionFactor: $0.conversionFactor) })
        return units
    }
    
    var basePricePerSmallestUnit: Double {
        switch priceType {
        case .retail: return product.retailPrice
        case .wholesale: return product.wholesalePrice > 0 ? product.wholesalePrice : product.retailPrice
        }
    }
    
    var finalPricePerSelectedUnit: Double {
        let priceBeforeDiscount = basePricePerSmallestUnit * Double(selectedUnit.conversionFactor)
        let final = priceBeforeDiscount - discount
        return final > 0 ? final : 0
    }
    
    var lineTotal: Double {
        return finalPricePerSelectedUnit * Double(quantity)
    }
    
    init(product: Product, quantity: Int) {
        self.product = product
        self.quantity = quantity
        self.selectedUnit = SalesUnit(name: product.unit, conversionFactor: 1)
    }
}

// Enum để quản lý focus cho các ô nhập liệu
enum POSFocusField: Hashable {
    case discount(id: UUID)
    case quantity(id: UUID)
}

struct POSView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProducts: [Product]
    @Query(sort: \Customer.name) private var allCustomers: [Customer]
    
    // Khai báo Query để lấy tất cả khuyến mãi
    @Query(sort: \Promotion.name) private var allPromotions: [Promotion]
    
    @StateObject private var cartManager = CartManager()

    @State private var isShowingProductPicker = false
    @State private var isShowingCheckoutSheet = false
    @State private var isShowingScanner = false
    @State private var showShareSheet = false
    @State private var showPostCheckoutAlert = false
    
    @State private var lastCreatedInvoice: Invoice?
    @State private var pdfURLToShare: URL?
    
    @FocusState private var focusedField: POSFocusField?
    
    // Biến tính toán để lọc các khuyến mãi hợp lệ tại thời điểm hiện tại
    private var applicablePromotions: [Promotion] {
        let now = Date()
        return allPromotions.filter { promo in
            promo.isActive &&
            promo.startDate <= now &&
            promo.endDate >= now &&
            promo.isValid(for: cartManager.subtotal)
        }
    }
    
    var body: some View {
        NavigationStack {
            posContent
                .navigationTitle("Bán Hàng")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button { isShowingScanner = true } label: { Image(systemName: "barcode.viewfinder") }
                        Button { isShowingProductPicker = true } label: { Image(systemName: "plus") }
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Xong") { focusedField = nil }
                    }
                }
                .sheet(isPresented: $isShowingProductPicker) { ProductPickerView(cartManager: cartManager) }
                .sheet(isPresented: $isShowingScanner) { BarcodeScannerView { scannedCode in handleScannedCode(scannedCode); isShowingScanner = false } }
                .sheet(isPresented: $showShareSheet) {
                    if let url = pdfURLToShare { ShareSheet(items: [url]) }
                }
                .sheet(isPresented: $isShowingCheckoutSheet) {
                    CheckoutView(cartManager: cartManager) { invoice in
                        self.lastCreatedInvoice = invoice
                        self.showPostCheckoutAlert = true
                    }
                }
                .alert("Thanh toán thành công!", isPresented: $showPostCheckoutAlert) {
                    Button("Đơn hàng mới") { lastCreatedInvoice = nil }
                    Button("In & Gửi Hóa Đơn") {
                        if let invoice = lastCreatedInvoice {
                            self.pdfURLToShare = PDFRenderer.render(view: InvoiceView(invoice: invoice))
                            showShareSheet = true
                        }
                    }
                } message: { Text("Bạn có muốn xuất hóa đơn cho đơn hàng này không?") }
        }
    }
    
    private var posContent: some View {
            VStack(spacing: 0) {
                // Phần chọn khách hàng và khuyến mãi
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                    Picker("Khách hàng", selection: $cartManager.selectedCustomer) {
                        Text("Khách lẻ").tag(Customer?.none)
                        ForEach(allCustomers) { customer in Text(customer.name).tag(customer as Customer?) }
                    }
                    
                    Spacer()
                    
                    // Sử dụng biến `applicablePromotions` đã được lọc sẵn
                    Picker("Khuyến mãi", selection: $cartManager.appliedPromotion) {
                        Text("Không áp dụng").tag(Promotion?.none)
                        ForEach(applicablePromotions) { promo in
                            Text(promo.name).tag(promo as Promotion?)
                        }
                    }
                    // Vô hiệu hóa Picker nếu không có KM nào phù hợp
                    .disabled(applicablePromotions.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
                
                // Phần giỏ hàng
                ScrollViewReader { proxy in
                    ScrollView {
                        if cartManager.items.isEmpty {
                            ContentUnavailableView("Giỏ hàng trống", systemImage: "cart.badge.plus")
                                .padding(.top, 100)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach($cartManager.items) { $item in
                                    cartItemRow(for: $item)
                                        .id(item.id)
                                    Divider().padding(.leading)
                                }
                            }
                            // Thêm một khoảng trống ở cuối để nội dung cuối không bị che khuất
                            Spacer(minLength: 140)
                        }
                    }
                    .onChange(of: focusedField) { oldValue, newValue in
                        if let newValue {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    switch newValue {
                                    case .discount(let id), .quantity(let id):
                                        proxy.scrollTo(id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .onTapGesture { focusedField = nil }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 8) {
                        // Hiển thị tổng tiền hàng
                        HStack {
                            Text("Tổng tiền hàng")
                            Spacer()
                            Text(cartManager.subtotal.formattedAsCurrency())
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        // Hiển thị số tiền giảm giá
                        if cartManager.discountAmount > 0 {
                            HStack {
                                Text(cartManager.appliedPromotion?.name ?? "Giảm giá")
                                Spacer()
                                Text("-\(cartManager.discountAmount.formattedAsCurrency())")
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                        }
                        
                        // Hiển thị tổng cộng cuối cùng
                        HStack {
                            Text("Tổng cộng").font(.title2.weight(.medium))
                            Spacer()
                            Text(cartManager.totalAmount.formattedAsCurrency())
                                .font(.title.bold())
                                .foregroundColor(.accentColor)
                        }
                        
                        Button(action: { isShowingCheckoutSheet = true }) {
                            Label("Thanh Toán", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(VividButtonStyle())
                        .disabled(!cartManager.isCartValid)
                    }
                    .padding()
                    .background(.bar)
                }
            }
        }
    
    @ViewBuilder
    private func cartItemRow(for item: Binding<CartItem>) -> some View {
        let cartItem = item.wrappedValue
        let quantityInBaseUnit = cartItem.quantity * cartItem.selectedUnit.conversionFactor
        let isOverStock = quantityInBaseUnit > cartItem.product.stockQuantity
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(cartItem.product.name).font(.headline)
                Spacer()
                Button(role: .destructive) {
                    withAnimation {
                        cartManager.removeItem(id: cartItem.id)
                    }
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 16) {
                Picker("", selection: item.selectedUnit) {
                    ForEach(cartItem.availableUnits) { unit in
                        Text(unit.name).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .frame(minWidth: 80)
                
                QuantityInputView(quantity: item.quantity, focusedField: $focusedField, focusValue: .quantity(id: cartItem.id))
                
                Spacer()
                
                Picker("", selection: item.priceType) {
                    ForEach(PriceType.allCases) { type in Text(type.rawValue).tag(type) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .disabled(cartItem.product.wholesalePrice <= 0)
            }
            
            HStack {
                Text("Giảm giá")
                    .foregroundColor(.secondary)
                TextField("0", value: item.discount, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .discount(id: cartItem.id))
                
                Text(cartItem.lineTotal.formattedAsCurrency())
                    .fontWeight(.bold)
                    .frame(minWidth: 100, alignment: .trailing)
            }
            
            if isOverStock {
                Text("Vượt tồn kho! (Tồn: \(cartItem.product.stockQuantity / cartItem.selectedUnit.conversionFactor) \(cartItem.selectedUnit.name))")
                    .font(.caption).foregroundColor(.red).bold()
            }
        }
        .padding()
        .background(isOverStock ? Color.red.opacity(0.1) : Color(.systemBackground))
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleScannedCode(_ code: String) {
        guard let product = allProducts.first(where: { $0.barcode == code }) else { return }
        cartManager.addProduct(product)
    }
}

struct ProductPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var cartManager: CartManager
    
    @Query(sort: \Category.name) private var categories: [Category]
    
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Lọc theo danh mục", selection: $selectedCategory) {
                    Text("Tất cả danh mục").tag(Category?.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                FilteredProductGrid(
                    searchText: searchText,
                    selectedCategory: selectedCategory,
                    cartManager: cartManager
                )
            }
            .searchable(text: $searchText, prompt: "Tìm tên sản phẩm")
            .navigationTitle("Chọn Sản Phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Xong") { dismiss() } }
            }
        }
    }
}

private struct FilteredProductGrid: View {
    @ObservedObject var cartManager: CartManager
    @Query private var products: [Product]
    
    private let columns: [GridItem] = [GridItem(.adaptive(minimum: 120))]
    
    init(searchText: String, selectedCategory: Category?, cartManager: CartManager) {
        self.cartManager = cartManager
        let addedProductIDs = cartManager.items.map { $0.product.id }
        let categoryID = selectedCategory?.id
        
        let predicate = #Predicate<Product> { product in
            !addedProductIDs.contains(product.id) &&
            (searchText.isEmpty || product.name.localizedStandardContains(searchText)) &&
            (categoryID == nil || product.category?.id == categoryID) &&
            product.stockQuantity > 0
        }
        
        self._products = Query(filter: predicate, sort: \Product.name)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(products) { product in
                    productGridItem(for: product)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func productGridItem(for product: Product) -> some View {
        Button(action: { cartManager.addProduct(product) }) {
            VStack {
                if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 80)
                        .clipped()
                } else {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .foregroundColor(.secondary.opacity(0.3))
                }
                
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(product.retailPrice.formattedAsCurrency())
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
            }
            .padding(8)
            .frame(minHeight: 160, alignment: .top)
            .background(.background)
            .cornerRadius(10)
            .shadow(radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
