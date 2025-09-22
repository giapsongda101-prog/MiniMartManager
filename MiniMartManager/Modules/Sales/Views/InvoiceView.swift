import SwiftUI

struct InvoiceView: View {
    let invoice: Invoice
    
    // Tính toán lại tổng tiền hàng trước khi có bất kỳ giảm giá nào
    private var subtotal: Double {
        // Cộng lại số tiền đã được giảm giá để ra tổng ban đầu
        return invoice.totalAmount + invoice.discountAmount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            Divider()
            
            // Customer Info
            customerInfoView
            
            Divider()
            
            // Items Table Header
            itemsHeaderView
            
            // Items List
            ForEach(invoice.details) { detail in
                itemRowView(for: detail)
            }
            
            Divider()
            
            // Phần tổng kết
            summaryView
            
            Spacer()
            
            // Footer
            footerView
        }
        .padding()
        .background(Color.white)
        .foregroundColor(.black)
    }
    
    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("MiniMart Manager")
                    .font(.title2.bold())
                Text("HÓA ĐƠN BÁN HÀNG")
                    .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Số: \(invoice.id.uuidString.prefix(8))")
                Text("Ngày: \(invoice.creationDate.formatted(date: .numeric, time: .shortened))")
            }
        }
    }
    
    private var customerInfoView: some View {
        VStack(alignment: .leading) {
            Text("Khách hàng: \(invoice.customer?.name ?? "Khách lẻ")")
            if let phone = invoice.customer?.phone, !phone.isEmpty {
                Text("SĐT: \(phone)")
            }
        }
    }
    
    private var itemsHeaderView: some View {
        HStack {
            Text("Sản phẩm").bold().frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            Text("SL").bold().frame(width: 40, alignment: .trailing)
            Text("Đơn giá").bold().frame(width: 80, alignment: .trailing)
            Text("Thành tiền").bold().frame(width: 90, alignment: .trailing)
        }
        .font(.footnote)
    }
    
    private func itemRowView(for detail: InvoiceDetail) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(detail.product?.name ?? "N/A")
                Text("(\(detail.unitName))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            
            Text("\(detail.quantity)").frame(width: 40, alignment: .trailing)
            Text(detail.pricePerUnitAtSale.formattedAsCurrency()).frame(width: 80, alignment: .trailing)
            Text((Double(detail.quantity) * detail.pricePerUnitAtSale).formattedAsCurrency()).frame(width: 90, alignment: .trailing)
        }
        .font(.footnote)
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Tổng tiền hàng:").bold()
                Spacer()
                Text(subtotal.formattedAsCurrency())
            }
            
            // Chỉ hiển thị dòng khuyến mãi nếu có
            if let promoName = invoice.appliedPromotionName, invoice.discountAmount > 0 {
                HStack {
                    Text("Khuyến mãi (\(promoName)):").bold()
                    Spacer()
                    Text("-\(invoice.discountAmount.formattedAsCurrency())")
                        .foregroundColor(.red)
                }
            }
            
            HStack {
                Text("Khách cần trả:").font(.headline).bold()
                Spacer()
                Text(invoice.totalAmount.formattedAsCurrency())
                    .font(.headline).bold()
            }
            
            HStack {
                Text("Khách đã trả:").bold()
                Spacer()
                Text(invoice.amountPaid.formattedAsCurrency())
            }
            
            let remainingDebt = invoice.totalAmount - invoice.amountPaid
            if remainingDebt > 0 {
                HStack {
                    Text("Còn nợ:").bold()
                    Spacer()
                    Text(remainingDebt.formattedAsCurrency()).foregroundColor(.red)
                }
            }
            
            Divider().padding(.vertical, 4)
            
            // SỬA LỖI: Gọi đúng tên hàm là 'convert'
            VStack(alignment: .leading) {
                Text("Bằng chữ:").bold()
                // Sử dụng hàm convert() và không cần ép kiểu sang Int
                Text(NumberToTextConverter.convert(invoice.totalAmount))
                    .italic()
            }
            .font(.footnote)
        }
        .padding(.top, 5)
    }
    
    private var footerView: some View {
        VStack {
            Text("Cảm ơn quý khách và hẹn gặp lại!")
                .font(.caption.italic())
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
