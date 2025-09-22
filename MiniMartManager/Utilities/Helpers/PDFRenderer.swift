// MiniMartManager/Utilities/Helpers/PDFRenderer.swift
import SwiftUI
import PDFKit

@MainActor
class PDFRenderer {
    static func render(view: some View) -> URL? {
        let renderer = ImageRenderer(content: view)
        
        // SỬA LỖI TẠI ĐÂY: Xóa dòng 'let pageRect = ...' không được sử dụng
        
        // Chiều rộng view render (mm) -> point. 80mm là chiều rộng giấy in bill phổ biến
        let viewWidthPoints = (80 / 25.4) * 72
        
        renderer.proposedSize = ProposedViewSize(width: viewWidthPoints, height: nil)
        
        guard let image = renderer.uiImage else {
            print("Không thể render view thành ảnh.")
            return nil
        }
        
        // Tính toán lại chiều cao của PDF cho vừa với nội dung
        let imageHeightPoints = image.size.height
        let pageRectFinal = CGRect(x: 0, y: 0, width: viewWidthPoints, height: imageHeightPoints)

        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData)!
        var mediaBox = pageRectFinal
        let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)!
        
        pdfContext.beginPDFPage(nil)
        pdfContext.draw(image.cgImage!, in: pageRectFinal)
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("HoaDon-\(UUID().uuidString).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            print("Đã lưu PDF tại: \(tempURL)")
            return tempURL
        } catch {
            print("Lỗi khi lưu PDF: \(error)")
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
