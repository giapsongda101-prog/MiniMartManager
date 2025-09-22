// MiniMartManager/App/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        // SỬA LỖI: Kiểm tra trạng thái đăng nhập bằng cách kiểm tra currentUser
        if authManager.currentUser != nil {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
