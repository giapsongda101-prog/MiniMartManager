//
//  BarcodeGenerator.swift
//  MiniMartManager
//
//  Created by [Your Name] on 11/9/25.
//

import UIKit
import CoreImage.CIFilterBuiltins

struct BarcodeGenerator {
    // Hàm này nhận vào một chuỗi và trả về một ảnh mã vạch (chuẩn Code 128)
    static func generate(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.code128BarcodeGenerator()
        
        filter.message = Data(string.utf8)
        
        // Phóng to ảnh mã vạch để nó rõ nét hơn
        let transform = CGAffineTransform(scaleX: 5, y: 5)
        
        if let outputImage = filter.outputImage?.transformed(by: transform) {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}
