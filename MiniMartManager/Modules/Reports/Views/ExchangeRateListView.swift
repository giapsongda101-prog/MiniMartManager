import SwiftUI
import SwiftData

struct ExchangeRateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExchangeRate.lastUpdatedDate, order: .reverse) private var rates: [ExchangeRate]
    
    @State private var isShowingEditSheet = false
    @State private var rateToEdit: ExchangeRate?

    var body: some View {
        NavigationStack {
            List {
                Section("Tỷ giá hiện hành") {
                    ForEach(rates) { rate in
                        Button(action: {
                            rateToEdit = rate
                            isShowingEditSheet = true
                        }) {
                            HStack {
                                Text("\(rate.fromCurrency) -> \(rate.toCurrency)")
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(rate.rate.formatted(.number))
                                        .fontWeight(.semibold)
                                    Text("Cập nhật: \(rate.lastUpdatedDate.formatted(date: .numeric, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                    .onDelete(perform: deleteRates)
                }
            }
            .navigationTitle("Quản lý Tỷ giá")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        rateToEdit = nil
                        isShowingEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                ExchangeRateEditView(rate: rateToEdit)
            }
            .overlay {
                if rates.isEmpty {
                    ContentUnavailableView("Chưa có tỷ giá", systemImage: "arrow.left.arrow.right.circle")
                }
            }
        }
    }
    
    private func deleteRates(at offsets: IndexSet) {
        for index in offsets {
            let rateToDelete = rates[index]
            modelContext.delete(rateToDelete)
        }
    }
}
