// MiniMartManager/Modules/UserManagement/Views/ChangePasswordView.swift
import SwiftUI

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    // **SỬA LỖI: Bỏ comment dòng này để lấy authManager từ environment**
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    // **THÊM MỚI: State để hiển thị thông báo lỗi**
    @State private var showErrorAlert = false
    @State private var alertMessage = ""

    private var isFormValid: Bool {
        !oldPassword.isEmpty && !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Đổi mật khẩu") {
                    SecureField("Mật khẩu cũ", text: $oldPassword)
                    SecureField("Mật khẩu mới", text: $newPassword)
                    SecureField("Xác nhận mật khẩu mới", text: $confirmPassword)
                }
                
                if !newPassword.isEmpty && newPassword != confirmPassword {
                    Text("Mật khẩu xác nhận không khớp.")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Đổi Mật Khẩu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Hủy") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { changePassword() }.disabled(!isFormValid)
                }
            }
            // **THÊM MỚI: Alert để thông báo kết quả**
            .alert("Thông Báo", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // **SỬA LỖI: Cập nhật lại hàm này**
    private func changePassword() {
        if authManager.changePassword(oldPassword_plaintext: oldPassword, newPassword_plaintext: newPassword) {
            // Nếu thành công, đóng màn hình
            dismiss()
        } else {
            // Nếu thất bại, hiển thị thông báo lỗi
            alertMessage = "Mật khẩu cũ không đúng. Vui lòng thử lại."
            showErrorAlert = true
            oldPassword = ""
            newPassword = ""
            confirmPassword = ""
        }
    }
}
