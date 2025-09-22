import UserNotifications

@MainActor
class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    // Yêu cầu quyền gửi thông báo từ người dùng
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    // Gửi thông báo cảnh báo tồn kho
    func scheduleLowStockNotification(lowStockProductCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Cảnh Báo Tồn Kho"
        content.body = "Có \(lowStockProductCount) sản phẩm sắp hết hàng. Vui lòng kiểm tra và nhập hàng."
        content.sound = .default

        // Gửi thông báo sau 5 giây để người dùng có thời gian thấy giao diện chính
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
