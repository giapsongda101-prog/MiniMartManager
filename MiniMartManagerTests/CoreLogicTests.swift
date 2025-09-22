import XCTest
import SwiftData
@testable import MiniMartManager

@MainActor
final class CoreLogicTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    // Thiết lập môi trường test trong bộ nhớ
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    // Dọn dẹp môi trường sau mỗi lần test
    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - Test Models
    
    func testProductCreation() throws {
        let category = Category(name: "Đồ uống")
        let supplier = Supplier(name: "Công ty ABC")
        let product = Product(name: "Nước ngọt", unit: "lon", costPrice: 8000, retailPrice: 10000, category: category, supplier: supplier)
        
        modelContext.insert(product)
        try modelContext.save()
        
        let fetchedProduct = try modelContext.fetch(FetchDescriptor<Product>()).first
        
        XCTAssertNotNil(fetchedProduct, "Sản phẩm phải được tạo thành công")
        XCTAssertEqual(fetchedProduct?.name, "Nước ngọt")
        XCTAssertEqual(fetchedProduct?.category?.name, "Đồ uống")
        XCTAssertEqual(fetchedProduct?.supplier?.name, "Công ty ABC")
    }

    // MARK: - Test Authentication
    
    func testAdminLogin() throws {
        let authManager = AuthenticationManager(modelContext: modelContext)
        
        let loginSuccess = authManager.login(username: "admin", password_plaintext: "123")
        XCTAssertTrue(loginSuccess, "Đăng nhập với tài khoản admin mặc định phải thành công")
        XCTAssertNotNil(authManager.currentUser, "currentUser không được rỗng sau khi đăng nhập thành công")
        XCTAssertEqual(authManager.currentUser?.role, .admin, "Vai trò của người dùng phải là admin")
    }
    
    func testChangePassword() throws {
        let authManager = AuthenticationManager(modelContext: modelContext)
        _ = authManager.login(username: "admin", password_plaintext: "123")
        
        let changeSuccess = authManager.changePassword(oldPassword_plaintext: "123", newPassword_plaintext: "newpass")
        XCTAssertTrue(changeSuccess, "Đổi mật khẩu phải thành công với mật khẩu cũ đúng")
        
        authManager.logout()
        
        let loginWithOldPasswordFails = authManager.login(username: "admin", password_plaintext: "123")
        XCTAssertFalse(loginWithOldPasswordFails, "Đăng nhập với mật khẩu cũ phải thất bại")
        
        let loginWithNewPasswordSucceeds = authManager.login(username: "admin", password_plaintext: "newpass")
        XCTAssertTrue(loginWithNewPasswordSucceeds, "Đăng nhập với mật khẩu mới phải thành công")
    }

    // MARK: - Test Cart & Checkout Logic
    
    func testAddToCartAndCheckout() throws {
        let product1 = Product(name: "Bánh mì", unit: "cái", costPrice: 5000, retailPrice: 7000, stockQuantity: 20)
        let product2 = Product(name: "Sữa tươi", unit: "hộp", costPrice: 6000, retailPrice: 8000, stockQuantity: 30)
        modelContext.insert(product1)
        modelContext.insert(product2)
        
        let cartManager = CartManager()
        
        cartManager.addProduct(product1, quantity: 2)
        cartManager.addProduct(product2, quantity: 1)
        
        XCTAssertEqual(cartManager.items.count, 2, "Giỏ hàng phải có 2 sản phẩm")
        XCTAssertEqual(cartManager.totalAmount, 2 * 7000 + 1 * 8000, "Tổng giá trị giỏ hàng phải được tính đúng")
        
        let newInvoice = cartManager.checkout(paid: true, modelContext: modelContext)
        
        XCTAssertNotNil(newInvoice, "Hóa đơn phải được tạo sau khi thanh toán")
        XCTAssertEqual(product1.stockQuantity, 18, "Tồn kho sản phẩm 1 phải bị trừ đi 2")
        XCTAssertEqual(product2.stockQuantity, 29, "Tồn kho sản phẩm 2 phải bị trừ đi 1")
        
        let transactions = try modelContext.fetch(FetchDescriptor<StockTransaction>())
        XCTAssertEqual(transactions.count, 2, "Phải có 2 giao dịch kho được tạo")
        
        let fundTransactions = try modelContext.fetch(FetchDescriptor<FundTransaction>())
        XCTAssertEqual(fundTransactions.count, 1, "Phải có 1 giao dịch quỹ được tạo")
        XCTAssertEqual(fundTransactions.first?.type, "THU")
        XCTAssertEqual(fundTransactions.first?.amount, 22000)
    }
    
    // MARK: - Tiện ích
    
    // Định nghĩa Schema cho môi trường test
    private var schema: Schema {
        return Schema([
            Product.self, Category.self, Supplier.self, Customer.self,
            GoodsReceipt.self, GoodsReceiptDetail.self,
            Invoice.self, InvoiceDetail.self,
            DebtTransaction.self, FundTransaction.self,
            ReturnSlip.self, ReturnSlipDetail.self,
            StockTransaction.self,
            SupplierReturnSlip.self, SupplierReturnSlipDetail.self,
            ProductAttribute.self, ProductAttributeValue.self,
            ProductUnit.self, User.self
        ])
    }
}
