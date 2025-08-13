import Network
import Foundation

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    @Published var isOnline: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "net.monitor")
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async { self?.isOnline = path.status == .satisfied }
        }
        monitor.start(queue: queue)
    }
} 