import SwiftUI
import UniformTypeIdentifiers

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    private var currentUserRole: UserRole {
        authManager.currentUser?.role ?? .employee
    }

    var body: some View {
        TabView {
            if currentUserRole == .admin || currentUserRole == .manager {
                DashboardView()
                    .tabItem { Label("Tổng quan", systemImage: "chart.pie.fill") }
                POSView()
                    .tabItem { Label("Bán hàng", systemImage: "cart.fill") }
                GoodsReceiptListView()
                    .tabItem { Label("Kho hàng", systemImage: "archivebox.fill") }
                DebtTabView()
                    .tabItem { Label("Công nợ", systemImage: "list.bullet.rectangle.portrait.fill") }
                MoreView(userRole: currentUserRole)
                    .tabItem { Label("Thêm", systemImage: "ellipsis.circle.fill") }
            } else if currentUserRole == .employee {
                POSView()
                    .tabItem { Label("Bán hàng", systemImage: "cart.fill") }
                MoreView(userRole: currentUserRole)
                    .tabItem { Label("Thêm", systemImage: "ellipsis.circle.fill") }
            }
        }
    }
}

struct MoreView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isShowingFileImporter = false
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    let userRole: UserRole

    var body: some View {
        NavigationStack {
            List {
                if userRole == .admin || userRole == .manager {
                    Section("Quản lý Dữ liệu") {
                        NavigationLink(destination: ProductListView()) { Label("Sản phẩm", systemImage: "shippingbox.fill") }
                        NavigationLink(destination: CustomerListView()) { Label("Khách hàng", systemImage: "person.2.fill") }
                        NavigationLink(destination: SupplierListView()) { Label("Nhà cung cấp", systemImage: "building.2.fill") }
                        NavigationLink(destination: CategoryListView()) { Label("Danh mục", systemImage: "tag.fill") }
                        NavigationLink(destination: AttributeListView()) { Label("Thuộc tính", systemImage: "slider.horizontal.3") }
                    }
                    Section("Nghiệp vụ khác") {
                        // DÒNG MỚI: Thêm mục quản lý khuyến mãi
                        NavigationLink(destination: PromotionListView()) { Label("Quản lý Khuyến mãi", systemImage: "gift.fill") }
                        NavigationLink(destination: ReturnView()) { Label("Lịch sử Trả hàng", systemImage: "arrow.uturn.backward.circle.fill") }
                    }
                }
                
                Section("Hệ thống") {
                    if userRole == .admin {
                        NavigationLink(destination: UserListView()) { Label("Quản lý Người dùng", systemImage: "person.badge.key.fill") }
                        NavigationLink(destination: BackupRestoreView()) { Label("Sao lưu & Phục hồi", systemImage: "icloud.and.arrow.up.fill") }
                        Button { isShowingFileImporter = true } label: { Label("Nhập từ Excel", systemImage: "square.and.arrow.down") }
                        .foregroundColor(.primary)
                    }
                }
                
                Section("Tài khoản") {
                    NavigationLink(destination: ChangePasswordView()) { Label("Đổi mật khẩu", systemImage: "key.fill") }
                    Button(role: .destructive) { authManager.logout() } label: { Label("Đăng xuất", systemImage: "arrow.right.square.fill") }
                }
            }
            .navigationTitle("Thêm")
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [UTType.spreadsheet],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert(alertTitle, isPresented: $showAlert) { Button("OK") {} } message: { Text(alertMessage) }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                alertTitle = "Lỗi"
                alertMessage = "Không có file nào được chọn."
                showAlert = true
                return
            }
            
            Task {
                let importer = DataImporter(modelContext: modelContext)
                do {
                    try await importer.import(from: url)
                    alertTitle = "Thành công"
                    alertMessage = "Dữ liệu đã được nhập thành công từ file Excel."
                    showAlert = true
                } catch {
                    alertTitle = "Lỗi Nhập Liệu"
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
            
        case .failure(let error):
            alertTitle = "Lỗi"
            alertMessage = "Không thể chọn file: \(error.localizedDescription)"
            showAlert = true
        }
    }
}
