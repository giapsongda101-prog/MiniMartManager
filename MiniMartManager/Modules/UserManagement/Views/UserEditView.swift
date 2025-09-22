// MiniMartManager/Modules/UserManagement/Views/UserEditView.swift
import SwiftUI
import SwiftData
import CryptoKit

struct UserEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var userToEdit: User?
    
    @State private var username: String = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .employee
    
    private var isNewUser: Bool { userToEdit == nil }
    private var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        (isNewUser ? !password.isEmpty : true)
    }
    
    private var navigationTitle: String {
        isNewUser ? "Tạo Người Dùng Mới" : "Sửa Thông Tin"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin đăng nhập") {
                    TextField("Tên đăng nhập", text: $username)
                        .disabled(!isNewUser)
                    
                    if isNewUser {
                        SecureField("Mật khẩu", text: $password)
                    } else {
                        Text("Để đổi mật khẩu, vui lòng dùng chức năng 'Đổi mật khẩu'.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Phân quyền") {
                    Picker("Vai trò", selection: $selectedRole) {
                        ForEach(UserRole.allCases) { role in
                            Text(role.displayName).tag(role)
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
            .onAppear {
                if let user = userToEdit {
                    username = user.username
                    selectedRole = user.role
                }
            }
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func save() {
        if let user = userToEdit {
            user.role = selectedRole
        } else {
            // SỬA LỖI: Gọi hàm khởi tạo User với tất cả các tham số
            let hashedPassword = hashPassword(password)
            let newUser = User(
                username: username,
                passwordHash: hashedPassword,
                role: selectedRole,
                createdAt: .now
            )
            modelContext.insert(newUser)
        }
        dismiss()
    }
}
