// MiniMartManager/Core/Auth/AuthenticationManager.swift
import SwiftUI
import SwiftData
import LocalAuthentication
import CryptoKit

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        ensureDefaultAdminExists()
    }

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func ensureDefaultAdminExists() {
        let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == "admin" })
        
        do {
            let count = try modelContext.fetchCount(fetchDescriptor)
            if count == 0 {
                // SỬA LỖI: Gọi hàm khởi tạo User với tất cả các tham số
                let adminUser = User(
                    username: "admin",
                    passwordHash: hashPassword("123"),
                    role: .admin,
                    createdAt: .now
                )

                modelContext.insert(adminUser)
                try modelContext.save()
                print("Default admin user created with a hashed password.")
            }
        } catch {
            print("Failed to create or check for default admin user: \(error)")
        }
    }

    func login(username: String, password_plaintext: String) -> Bool {
        let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == username })
        
        do {
            guard let user = try modelContext.fetch(fetchDescriptor).first else {
                return false
            }
            
            if user.passwordHash == hashPassword(password_plaintext) {
                self.currentUser = user
                UserDefaults.standard.set(user.username, forKey: "lastLoggedInUser")
                return true
            }
            
            return false
        } catch {
            print("Failed to fetch user for login: \(error)")
            return false
        }
    }
    
    func logout() {
        self.currentUser = nil
    }
    
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Đăng nhập vào tài khoản của bạn"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        if let lastUser = UserDefaults.standard.string(forKey: "lastLoggedInUser") {
                            let fetchDescriptor = FetchDescriptor<User>(predicate: #Predicate { $0.username == lastUser })
                            if let user = try? self?.modelContext.fetch(fetchDescriptor).first {
                                self?.currentUser = user
                            }
                        }
                    } else {
                        print(authenticationError?.localizedDescription ?? "Failed to authenticate")
                    }
                }
            }
        } else {
            print(error?.localizedDescription ?? "Biometrics not available")
        }
    }
    
    func changePassword(oldPassword_plaintext: String, newPassword_plaintext: String) -> Bool {
        guard let user = currentUser else {
            return false
        }

        if user.passwordHash == hashPassword(oldPassword_plaintext) {
            user.passwordHash = hashPassword(newPassword_plaintext)
            do {
                try modelContext.save()
                return true
            } catch {
                print("Lỗi khi lưu mật khẩu mới: \(error)")
                return false
            }
        }
        
        return false
    }
}
