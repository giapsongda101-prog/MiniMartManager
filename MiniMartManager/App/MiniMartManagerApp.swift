import SwiftUI
import SwiftData

@main
struct MiniMartManagerApp: App {
    @StateObject private var authManager: AuthenticationManager

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Product.self,
            Category.self,
            Supplier.self,
            Customer.self,
            GoodsReceipt.self,
            GoodsReceiptDetail.self,
            Invoice.self,
            InvoiceDetail.self,
            DebtTransaction.self,
            FundTransaction.self,
            ReturnSlip.self,
            ReturnSlipDetail.self,
            StockTransaction.self,
            SupplierReturnSlip.self,
            SupplierReturnSlipDetail.self,
            ProductAttribute.self,
            ProductAttributeValue.self,
            ProductUnit.self,
            User.self,
            Promotion.self // THÊM DÒNG NÀY
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        let modelContext = sharedModelContainer.mainContext
        _authManager = StateObject(wrappedValue: AuthenticationManager(modelContext: modelContext))
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            if authManager.currentUser != nil {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
