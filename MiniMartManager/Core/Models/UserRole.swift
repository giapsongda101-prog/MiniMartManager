// MiniMartManager/Core/Models/UserRole.swift
import Foundation

// Định nghĩa enum UserRole để phân loại người dùng
enum UserRole: String, CaseIterable, Identifiable, Codable { // THÊM Codable VÀO ĐÂY
    case admin
    case manager
    case employee
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .manager:
            return "Quản lý"
        case .employee:
            return "Nhân viên"
        }
    }
}
