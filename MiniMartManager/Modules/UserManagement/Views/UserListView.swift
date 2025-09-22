// MiniMartManager/Modules/UserManagement/Views/UserListView.swift
import SwiftUI
import SwiftData

struct UserListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \User.username) private var users: [User]
    
    @State private var isShowingEditSheet = false
    // THÊM MỚI: Các state để hiển thị cảnh báo
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(users) { user in
                    NavigationLink(destination: UserEditView(userToEdit: user)) {
                        VStack(alignment: .leading) {
                            Text(user.username).font(.headline)
                            Text(user.role.rawValue).font(.subheadline).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteUsers)
            }
            .navigationTitle("Quản lý Người dùng")
            .toolbar {
                Button { isShowingEditSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                UserEditView()
            }
            // THÊM MỚI: Gắn alert vào view
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func deleteUsers(at offsets: IndexSet) {
        for index in offsets {
            let userToDelete = users[index]
            
            // TỐI ƯU HÓA LOGIC:
            // Kiểm tra không cho xóa admin cuối cùng
            let adminUsers = users.filter { $0.role == .admin }
            if userToDelete.role == .admin && adminUsers.count <= 1 {
                alertTitle = "Không thể xóa"
                alertMessage = "Không thể xóa người dùng Admin cuối cùng của hệ thống."
                showAlert = true
                continue // Bỏ qua việc xóa
            }
            
            modelContext.delete(userToDelete)
        }
    }
}
