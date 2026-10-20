import Network

/// Watches whether the network is reachable and reports changes on the main actor.
@MainActor
final class NetworkMonitor {
    /// Called with `true` when the network becomes reachable, `false` when it is lost.
    var onChange: (@MainActor (Bool) -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "io.github.muunleit-projects.thetap.network")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in
                self?.onChange?(online)
            }
        }
        monitor.start(queue: queue)
    }
}