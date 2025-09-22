import SwiftUI
import SwiftData

struct ProductListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.name) private var products: [Product]
    
    @State private var isShowingAddProductSheet = false
    @State private var searchText = ""

    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                (product.sku.localizedCaseInsensitiveContains(searchText))
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredProducts.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if products.isEmpty {
                    emptyStateView
                } else {
                    productList
                }
            }
            .navigationTitle("Sản phẩm")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isShowingAddProductSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Tìm theo tên hoặc SKU")
            .sheet(isPresented: $isShowingAddProductSheet) {
                ProductEditView()
            }
        }
    }
    
    private var productList: some View {
        List {
            ForEach(filteredProducts) { product in
                NavigationLink(destination: ProductEditView(productToEdit: product)) {
                    productRow(for: product)
                }
            }
            .onDelete(perform: deleteProducts)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            let productToDelete = filteredProducts[index]
            modelContext.delete(productToDelete)
        }
    }
    
    // CẬP NHẬT GIAO DIỆN HÀNG SẢN PHẨM
    private func productRow(for product: Product) -> some View {
        HStack(spacing: 15) {
            // Hiển thị ảnh sản phẩm
            if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.secondary.opacity(0.3))
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text("SKU: \(product.sku.isEmpty ? "N/A" : product.sku)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(product.retailPrice.formattedAsCurrency())
                    .font(.headline)
                    .foregroundColor(.accentColor)
                Text("Tồn kho: \(product.stockQuantity)")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Chưa có sản phẩm nào",
            systemImage: "shippingbox.fill",
            description: Text("Nhấn nút '+' để thêm sản phẩm mới.")
        )
    }
}
