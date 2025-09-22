import Foundation

struct NumberToTextConverter {

    private static let numbers: [String] = ["không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"]
    private static let units: [String] = ["", "nghìn", "triệu", "tỷ", "nghìn tỷ"]

    /// Hàm chính để chuyển đổi số thành chữ
    static func convert(_ number: Double) -> String {
        // SỬA LỖI QUAN TRỌNG: Làm tròn số trước khi chuyển đổi sang kiểu Int64
        let wholeNumber = Int64(round(number))
        
        if wholeNumber == 0 { return "Không đồng" }
        if wholeNumber >= 1_000_000_000_000_000 { return "Số quá lớn" }

        var num = wholeNumber
        var resultParts: [String] = []
        var unitIndex = 0
        
        var hasSignificantGroup = false

        repeat {
            let threeDigits = Int(num % 1000)
            let isLastGroup = (num / 1000) == 0

            let currentGroupText = readThreeDigits(threeDigits, isLastGroup: isLastGroup, isFirstGroupEver: unitIndex == 0)
            
            if !currentGroupText.isEmpty {
                hasSignificantGroup = true
                let unitText = units[unitIndex]
                
                resultParts.insert("\(currentGroupText) \(unitText)", at: 0)
            } else if hasSignificantGroup {
                 // Nếu nhóm hiện tại là 000, nhưng trước đó đã có nhóm khác 0,
                 // ta vẫn cần thêm đơn vị để tách các nhóm số lớn hơn.
                let unitText = units[unitIndex]
                 resultParts.insert(unitText, at: 0)
            }

            num /= 1000
            unitIndex += 1
            
        } while num > 0

        // Nối các phần lại và chuẩn hóa
        var finalResult = resultParts.joined(separator: " ")
            .replacingOccurrences(of: "không trăm không mươi", with: "không trăm")
            .replacingOccurrences(of: "không trăm không", with: "không trăm")
            .replacingOccurrences(of: "linh không", with: "linh")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Chữ cái đầu tiên luôn viết hoa
        finalResult = finalResult.prefix(1).uppercased() + finalResult.dropFirst()
        
        // Xử lý các lỗi sau khi nối chuỗi
        if finalResult.hasPrefix("Không trăm ") {
            finalResult = String(finalResult.dropFirst("Không trăm ".count))
        }

        return finalResult + " đồng"
    }

    /// Hàm đọc một nhóm 3 chữ số
    private static func readThreeDigits(_ n: Int, isLastGroup: Bool, isFirstGroupEver: Bool) -> String {
        if n == 0 { return "" }
        
        let tram = n / 100
        let chuc = (n % 100) / 10
        let donvi = n % 10
        var parts: [String] = []

        // Đọc hàng trăm
        if tram > 0 {
            parts.append(numbers[tram])
            parts.append("trăm")
        } else if !isLastGroup || (isLastGroup && n > 99) {
            // Chỉ đọc "không trăm" nếu nó không phải là nhóm cuối cùng
            // Hoặc là nhóm cuối nhưng không phải là một số lớn có nhóm hàng trăm bằng 0 (ví dụ: 120,000)
             if !isFirstGroupEver {
                parts.append("không trăm")
            }
        }

        // Đọc hàng chục
        if chuc > 1 {
            parts.append(numbers[chuc])
            parts.append("mươi")
            if donvi == 1 {
                parts.append("mốt")
            } else if donvi == 4 && n % 100 > 10 {
                 parts.append("tư")
            } else if donvi == 5 {
                parts.append("lăm")
            } else if donvi > 0 {
                parts.append(numbers[donvi])
            }
        } else if chuc == 1 {
            parts.append("mười")
            if donvi == 5 {
                parts.append("lăm")
            } else if donvi > 0 {
                parts.append(numbers[donvi])
            }
        } else { // chuc == 0
            if donvi > 0 {
                if tram > 0 {
                    parts.append("linh")
                }
                parts.append(numbers[donvi])
            }
        }
        
        return parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
}
