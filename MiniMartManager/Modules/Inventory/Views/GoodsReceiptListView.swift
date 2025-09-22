// MiniMartManager/Modules/Inventory/Views/GoodsReceiptListView.swift
import SwiftUI
import SwiftData

struct GoodsReceiptListView: View {
    // Query dữ liệu cần thiết
    @Query(sort: \GoodsReceipt.receiptDate, order: .reverse) private var receipts: [GoodsReceipt]
    @Query private var products: [Product]
    @Query(filter: #Predicate<Product> {
        $0.stockQuantity <= $0.minimumStockLevel && $0.minimumStockLevel > 0
    }) private var lowStockProducts: [Product]
    
    // State để mở các sheet
    @State private var isShowingAddSheet = false
    @State private var isShowingAdjustmentSheet = false
    @State private var isShowingSupplierReturnSheet = false
    
    // Các thuộc tính tính toán cho dashboard kho
    private var totalProductCount: Int { products.count }
    private var totalStockQuantity: Int { products.reduce(0) { $0 + $1.stockQuantity } }
    private var totalInventoryValue: Double {
        products.reduce(0) { $0 + (Double($1.stockQuantity) * $1.costPrice) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Section 1: Các chỉ số tổng quan
                Section(header: Text("Tổng quan kho hàng")) {
                    InventoryKPIView(iconName: "shippingbox.fill", title: "Tổng số sản phẩm", value: "\(totalProductCount)", color: .blue)
                    InventoryKPIView(iconName: "archivebox.fill", title: "Tổng số lượng tồn kho", value: "\(totalStockQuantity)", color: .green)
                    InventoryKPIView(iconName: "dollarsign.circle.fill", title: "Tổng giá trị tồn kho", value: totalInventoryValue.formattedAsCurrency(), color: .orange)
                }
                
                // Section 2: Cảnh báo và hành động nhanh
                Section(header: Text("Cảnh báo & Lối tắt")) {
                    if !lowStockProducts.isEmpty {
                        NavigationLink(destination: LowStockWarningView()) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Sản phẩm sắp hết hàng")
                                Spacer()
                                Text("\(lowStockProducts.count)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    NavigationLink(destination: ProductListView()) {
                        Label("Xem tất cả sản phẩm", systemImage: "list.bullet")
                    }
                }
                
                // Section 3: Lịch sử nhập hàng gần đây
                Section(header: Text("Lịch sử nhập hàng gần đây")) {
                    if receipts.isEmpty {
                        Text("Chưa có phiếu nhập kho nào.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(receipts.prefix(5)) { receipt in // Chỉ hiển thị 5 phiếu gần nhất
                            VStack(alignment: .leading) {
                                Text("Ngày nhập: \(receipt.receiptDate.formatted(date: .abbreviated, time: .shortened))")
                                Text("NCC: \(receipt.supplier?.name ?? "N/A")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Tổng tiền: \(receipt.totalAmount.formattedAsCurrency())")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle()) // Thay đổi style để đẹp hơn
            .navigationTitle("Quản Lý Kho")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Nút hành động chính
                    Button { isShowingAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    // Menu cho các hành động phụ
                    Menu {
                        Button { isShowingSupplierReturnSheet = true } label: {
                            Label("Tạo Phiếu Trả NCC", systemImage: "arrow.uturn.left.circle.fill")
                        }
                        Button { isShowingAdjustmentSheet = true } label: {
                            Label("Tạo Phiếu Điều Chỉnh", systemImage: "slider.horizontal.3")
                        }
                        NavigationLink(destination: StockTransactionHistoryView()) {
                            Label("Xem Lịch Sử Kho", systemImage: "clock.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) { AddGoodsReceiptView() }
            .sheet(isPresented: $isShowingAdjustmentSheet) { StockAdjustmentView() }
            .sheet(isPresented: $isShowingSupplierReturnSheet) { SupplierReturnView() }
        }
    }
}

// View phụ để hiển thị các chỉ số trong kho cho đẹp
struct InventoryKPIView: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }
}
