// MiniMartManager/Core/Models/User.swift
import Foundation
import SwiftData
import CryptoKit

@Model
final class User {
    var id: UUID
    var username: String
    var passwordHash: String
    var role: UserRole
    var createdAt: Date
    
    @Relationship(deleteRule: .nullify, inverse: \Invoice.user)
    var invoices: [Invoice]?

    init(id: UUID = UUID(), username: String, passwordHash: String, role: UserRole, createdAt: Date = .now, invoices: [Invoice]? = nil) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.role = role
        self.createdAt = createdAt
        self.invoices = invoices
    }
}
