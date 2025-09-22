// MiniMartManager/Core/Auth/Views/LoginView.swift
import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // THÊM LOGO
            Image("LogginLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 25.0))
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                .padding(.bottom, 20)
            
            VStack(spacing: 15) {
                TextField("Tên đăng nhập", text: $username)
                    .padding()
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(10)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.username)
                
                SecureField("Mật khẩu", text: $password)
                    .padding()
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(10)
                    .textContentType(.password)
            }
            .padding(.horizontal)
            
            if showError {
                Text("Tên đăng nhập hoặc mật khẩu không đúng.")
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(action: login) {
                Text("Đăng nhập")
            }
            .buttonStyle(VividButtonStyle())
            .padding(.horizontal)
            
            if canUseBiometrics() {
                Button(action: {
                    authManager.authenticateWithBiometrics()
                }) {
                    Image(systemName: "faceid")
                        .font(.largeTitle)
                        .padding()
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            self.username = UserDefaults.standard.string(forKey: "lastLoggedInUser") ?? ""
        }
    }
    
    private func login() {
        if authManager.login(username: username, password_plaintext: password) {
            showError = false
        } else {
            showError = true
            password = ""
        }
    }
    
    private func canUseBiometrics() -> Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
