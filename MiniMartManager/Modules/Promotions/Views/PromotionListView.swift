import SwiftUI
import SwiftData

struct PromotionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Promotion.startDate, order: .reverse) private var promotions: [Promotion]
    
    @State private var isShowingEditSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(promotions) { promotion in
                    NavigationLink(destination: PromotionEditView(promotionToEdit: promotion)) {
                        promotionRow(for: promotion)
                    }
                }
                .onDelete(perform: deletePromotion)
            }
            .navigationTitle("Quản lý Khuyến mãi")
            .toolbar {
                Button { isShowingEditSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                PromotionEditView()
            }
        }
    }
    
    private func promotionRow(for promotion: Promotion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(promotion.name)
                    .font(.headline)
                
                Text(promotion.promotionType.rawValue)
                    .font(.subheadline)
                
                Text("Hiệu lực: \(promotion.startDate.formatted(date: .numeric, time: .omitted)) - \(promotion.endDate.formatted(date: .numeric, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Hiển thị trạng thái hoạt động
            if promotion.isActive && promotion.endDate >= .now {
                Text("Đang chạy")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            } else {
                Text("Đã kết thúc")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func deletePromotion(at offsets: IndexSet) {
        for index in offsets {
            let promotionToDelete = promotions[index]
            modelContext.delete(promotionToDelete)
        }
    }
}
