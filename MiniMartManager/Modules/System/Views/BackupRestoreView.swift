// MiniMartManager/Modules/System/Views/BackupRestoreView.swift
import SwiftUI
import SwiftData

struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var isShowingRestoreImporter = false
    @State private var showRestoreSuccessAlert = false
    @State private var showRestoreErrorAlert = false
    @State private var alertMessage = "" // Thêm state cho nội dung alert
    
    private var databaseURL: URL? {
        guard let url = modelContext.container.configurations.first?.url else {
            return nil
        }
        return url
    }
    
    var body: some View {
        Form {
            Section("Sao lưu Dữ liệu") {
                Text("Sao lưu sẽ xuất toàn bộ dữ liệu của bạn ra một file duy nhất. Hãy cất giữ file này ở một nơi an toàn như iCloud Drive hoặc máy tính.")
                
                if let databaseURL {
                    ShareLink(item: databaseURL, subject: Text("Backup Data"), message: Text("Đây là file sao lưu dữ liệu từ ứng dụng Quản lý Kho.")) {
                        Label("Bắt đầu Sao lưu", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Text("Không thể xác định vị trí cơ sở dữ liệu.")
                        .foregroundColor(.red)
                }
            }
            
            Section("Phục hồi Dữ liệu") {
                Text("Phục hồi sẽ **XÓA SẠCH** toàn bộ dữ liệu hiện tại và thay thế bằng dữ liệu từ file sao lưu bạn chọn. Ứng dụng sẽ tự tạo một bản sao lưu an toàn trước khi thực hiện. Thao tác này không thể hoàn tác.")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Button {
                    isShowingRestoreImporter = true
                } label: {
                    Label("Chọn File để Phục hồi", systemImage: "square.and.arrow.down")
                }
            }
        }
        .navigationTitle("Sao lưu & Phục hồi")
        .fileImporter(isPresented: $isShowingRestoreImporter, allowedContentTypes: [.database]) { result in
            handleRestore(result: result)
        }
        .alert("Phục hồi thành công!", isPresented: $showRestoreSuccessAlert) {
            Button("OK") {}
        } message: {
            Text("Dữ liệu đã được phục hồi. Vui lòng **KHỞI ĐỘNG LẠI** ứng dụng để áp dụng thay đổi.")
        }
        .alert("Lỗi Phục hồi", isPresented: $showRestoreErrorAlert) {
            Button("OK") {}
        } message: {
            Text(alertMessage) // Sử dụng state để hiển thị thông báo lỗi chi tiết
        }
    }
    
    private func handleRestore(result: Result<URL, Error>) {
        guard case .success(let selectedFileURL) = result else {
            alertMessage = "Không thể chọn file. Lỗi: \(result)"
            showRestoreErrorAlert = true
            return
        }
            
        guard let destinationURL = databaseURL else {
            alertMessage = "Không tìm thấy đường dẫn database của ứng dụng."
            showRestoreErrorAlert = true
            return
        }

        // Tạo một bản sao lưu an toàn trước khi phục hồi
        let backupURL = destinationURL.deletingPathExtension().appendingPathExtension("bak")
        do {
            if FileManager.default.fileExists(atPath: backupURL.path) {
                try FileManager.default.removeItem(at: backupURL)
            }
            try FileManager.default.copyItem(at: destinationURL, to: backupURL)
            print("Đã tạo bản sao lưu an toàn tại: \(backupURL.path)")
        } catch {
            alertMessage = "Không thể tạo bản sao lưu an toàn trước khi phục hồi. Lỗi: \(error.localizedDescription)"
            showRestoreErrorAlert = true
            return
        }
        
        // Bắt đầu quá trình phục hồi
        let isAccessing = selectedFileURL.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                selectedFileURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: selectedFileURL, to: destinationURL)
            
            showRestoreSuccessAlert = true
            
        } catch {
            print("Lỗi khi phục hồi database: \(error)")
            alertMessage = "Quá trình phục hồi đã thất bại. Đang cố gắng khôi phục lại từ bản sao lưu an toàn..."
            
            // Nếu có lỗi, phục hồi lại từ bản backup
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: backupURL, to: destinationURL)
                alertMessage += "\nĐã khôi phục thành công dữ liệu cũ. Dữ liệu của bạn vẫn an toàn."
            } catch {
                alertMessage += "\n**CẢNH BÁO:** Không thể tự động khôi phục từ bản sao lưu. Vui lòng thực hiện thủ công từ file .bak. Lỗi: \(error.localizedDescription)"
            }
            showRestoreErrorAlert = true
        }
    }
}

import UniformTypeIdentifiers
extension UTType {
    static var database: UTType {
        UTType(filenameExtension: "sqlite") ?? .data
    }
}
