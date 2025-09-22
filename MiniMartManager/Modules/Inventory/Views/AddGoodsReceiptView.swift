import SwiftUI
import SwiftData

// Cấu trúc để quản lý một đơn vị tính khi nhập hàng
struct ReceiptUnit: Hashable, Identifiable {
    var id: String { name }
    let name: String
    let conversionFactor: Int
}

// Cấu trúc để quản lý một dòng sản phẩm trong phiếu nhập
struct ReceiptItem: Identifiable, Equatable {
    var id: UUID
    let product: Product
    var quantity: Int
    var costPrice: Double
    var selectedUnit: ReceiptUnit

    var availableUnits: [ReceiptUnit] {
        var units = [ReceiptUnit(name: product.unit, conversionFactor: 1)]
        let altUnits = product.alternativeUnits.sorted(by: { $0.conversionFactor < $1.conversionFactor })
        units.append(contentsOf: altUnits.map { ReceiptUnit(name: $0.name, conversionFactor: $0.conversionFactor) })
        return units
    }

    init(product: Product) {
        self.id = product.id
        self.product = product
        self.quantity = 1
        
        if let losUnit = product.alternativeUnits.first(where: { $0.name.lowercased() == "lố" }) {
            self.selectedUnit = ReceiptUnit(name: losUnit.name, conversionFactor: losUnit.conversionFactor)
            self.costPrice = product.costPrice * Double(losUnit.conversionFactor)
        } else {
            self.selectedUnit = ReceiptUnit(name: product.unit, conversionFactor: 1)
            self.costPrice = product.costPrice
        }
    }
}

enum ReceiptFocusField: Hashable {
    case quantity(id: UUID)
    case costPrice(id: UUID)
}

struct AddGoodsReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Supplier.name) private var suppliers: [Supplier]
    // THÊM: Truy vấn tỷ giá hối đoái
    @Query private var exchangeRates: [ExchangeRate]

    @State private var selectedSupplier: Supplier?
    @State private var isPaid: Bool = true
    @State private var receiptItems: [ReceiptItem] = []
    @State private var isShowingProductPicker = false
    // THÊM: Biến trạng thái để lưu loại tiền tệ và tỷ giá
    @State private var selectedCurrency: Currency = .VND
    @State private var exchangeRate: Double = 1.0

    @FocusState private var focusedField: ReceiptFocusField?

    private var totalAmount: Double {
        receiptItems.reduce(0) { $0 + (Double($1.quantity) * $1.costPrice) }
    }
    
    private var isFormValid: Bool {
        !receiptItems.isEmpty && selectedSupplier != nil
    }
    
    // TÌM TỶ GIÁ THEO LOẠI TIỀN TỆ ĐÃ CHỌN
    private var currentExchangeRate: Double {
        if selectedCurrency == .VND {
            return 1.0
        }
        return exchangeRates.first(where: { $0.fromCurrency == selectedCurrency.rawValue })?.rate ?? 0.0
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Thông tin chung")) {
                        Picker("Nhà cung cấp (bắt buộc)", selection: $selectedSupplier) {
                            Text("Chọn NCC").tag(Supplier?.none)
                            ForEach(suppliers) { supplier in Text(supplier.name).tag(supplier as Supplier?) }
                        }
                        Toggle("Đã thanh toán cho NCC", isOn: $isPaid)
                        // THÊM: Picker để chọn loại tiền tệ
                        Picker("Tiền tệ", selection: $selectedCurrency) {
                            ForEach(Currency.allCases) { currency in
                                Text(currency.rawValue).tag(currency)
                            }
                        }
                        .onChange(of: selectedCurrency) {
                            self.exchangeRate = currentExchangeRate
                        }
                        // HIỂN THỊ TỶ GIÁ HIỆN HÀNH
                        if selectedCurrency != .VND {
                            LabeledContent("Tỷ giá quy đổi (1 \(selectedCurrency.rawValue) = VNĐ)", value: exchangeRate.formatted(.number))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section(header: Text("Danh sách sản phẩm nhập")) {
                        ForEach($receiptItems) { $item in
                            receiptItemRow(for: $item)
                        }
                        .onDelete(perform: removeReceiptItem)
                        
                        Button(action: { isShowingProductPicker = true }) {
                            Label("Thêm sản phẩm", systemImage: "plus")
                        }
                    }
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Tổng cộng").font(.title2)
                        Spacer()
                        // ĐÃ SỬA LỖI: Cập nhật lại định dạng tiền tệ
                        Text(totalAmount.formatted(.currency(code: selectedCurrency.rawValue))).font(.title.bold()).foregroundColor(.accentColor)
                    }
                    if selectedCurrency != .VND {
                        HStack {
                            Text("~").font(.headline)
                            Spacer()
                             // ĐÃ SỬA LỖI: Cập nhật lại định dạng tiền tệ
                            Text((totalAmount * exchangeRate).formatted(.currency(code: "VND"))).font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.bar)
            }
            .navigationTitle("Tạo Phiếu Nhập Kho")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }.disabled(!isFormValid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") { focusedField = nil }
                }
            }
            .sheet(isPresented: $isShowingProductPicker) {
                ProductPickerForReceiptView(receiptItems: $receiptItems)
            }
            // KHỞI TẠO GIÁ TRỊ TỶ GIÁ BAN ĐẦU
            .onAppear {
                self.exchangeRate = currentExchangeRate
            }
        }
    }
    
    @ViewBuilder
    private func receiptItemRow(for item: Binding<ReceiptItem>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.wrappedValue.product.name).font(.headline)
            
            HStack {
                Picker("Đơn vị", selection: item.selectedUnit) {
                    ForEach(item.wrappedValue.availableUnits) { unit in
                        Text(unit.name).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: item.wrappedValue.selectedUnit) { _, newUnit in
                    let baseCostPrice = item.wrappedValue.product.costPrice
                    item.wrappedValue.costPrice = baseCostPrice * Double(newUnit.conversionFactor)
                }
                
                Spacer()
                
                HStack {
                    Text("Số lượng")
                    TextField("SL", value: item.quantity, format: .number)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .quantity(id: item.id))
                }
            }
            
            HStack {
                Text("Giá nhập (1 \(item.wrappedValue.selectedUnit.name))")
                Spacer()
                TextField("Giá", value: item.costPrice, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedField, equals: .costPrice(id: item.id))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func removeReceiptItem(at offsets: IndexSet) {
        receiptItems.remove(atOffsets: offsets)
    }
    
    private func save() {
        guard let supplier = selectedSupplier, !receiptItems.isEmpty else { return }

        let goodsReceipt = GoodsReceipt(
            receiptDate: .now,
            totalAmount: totalAmount,
            paymentStatus: isPaid ? "PAID" : "UNPAID",
            amountPaid: isPaid ? totalAmount : 0,
            supplier: supplier,
            user: nil // TODO: Thay thế bằng người dùng hiện tại
        )

        for item in receiptItems {
            let receiptDetail = GoodsReceiptDetail(
                quantity: item.quantity,
                costPriceAtTimeOfReceipt: item.costPrice,
                product: item.product
            )
            goodsReceipt.details.append(receiptDetail)
            
            let quantityInBaseUnit = item.quantity * item.selectedUnit.conversionFactor
            let costPricePerBaseUnit = item.costPrice / Double(item.selectedUnit.conversionFactor)
            
            // SỬA LỖI: Cập nhật giá vốn bằng phương pháp giá vốn trung bình có trọng số (WAC)
            if item.product.stockQuantity > 0 {
                let oldStock = Double(item.product.stockQuantity)
                let oldCostPrice = item.product.costPrice
                let newQuantity = Double(quantityInBaseUnit)
                let newCostPrice = costPricePerBaseUnit
                let newWeightedAverageCost = ((oldCostPrice * oldStock) + (newCostPrice * newQuantity)) / (oldStock + newQuantity)
                item.product.costPrice = newWeightedAverageCost
            } else {
                // Nếu tồn kho cũ là 0, giá vốn mới chính là giá nhập mới
                item.product.costPrice = costPricePerBaseUnit
            }
            
            item.product.stockQuantity += quantityInBaseUnit
            
            let stockTx = StockTransaction(
                product: item.product,
                quantityChange: quantityInBaseUnit,
                transactionDate: .now,
                transactionType: "NHAPKHO",
                reason: "Nhập \(item.quantity) \(item.selectedUnit.name) từ NCC: \(supplier.name)"
            )
            modelContext.insert(stockTx)
        }
        
        if isPaid {
            // THÊM: Tạo giao dịch quỹ với thông tin tiền tệ
            let fundTx = FundTransaction(
                type: "CHI",
                amount: totalAmount,
                currency: selectedCurrency.rawValue,
                exchangeRateAtTransaction: exchangeRate,
                reason: "Thanh toán nhập hàng từ \(supplier.name)",
                transactionDate: .now,
                isSystemGenerated: true
            )
            modelContext.insert(fundTx)
        }
        
        modelContext.insert(goodsReceipt)
        
        dismiss()
    }
}

struct ProductPickerForReceiptView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Product.name) private var products: [Product]
    @Binding var receiptItems: [ReceiptItem]
    
    @State private var searchText = ""
    
    private var filteredProducts: [Product] {
        products.filter { product in
            let isAlreadyAdded = receiptItems.contains(where: { $0.product.id == product.id })
            return !isAlreadyAdded && (searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredProducts) { product in
                Button(action: { addProductToReceipt(product) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(product.name).font(.headline)
                            Text("Tồn kho hiện tại: \(product.stockQuantity)").foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(product.costPrice.formatted(.currency(code: "VND")))
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Tìm tên sản phẩm")
            .navigationTitle("Chọn Sản Phẩm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Xong") { dismiss() } }
            }
        }
    }
    
    private func addProductToReceipt(_ product: Product) {
        let newItem = ReceiptItem(product: product)
        receiptItems.append(newItem)
    }
}
