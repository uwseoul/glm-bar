import Combine
import Foundation

#if canImport(Sparkle)
import Sparkle

@MainActor
final class UpdaterController: ObservableObject {
    private let standardUpdaterController: SPUStandardUpdaterController

    init() {
        standardUpdaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var canCheckForUpdates: Bool {
        standardUpdaterController.updater.canCheckForUpdates
    }

    var automaticUpdatesEnabled: Bool {
        let updater = standardUpdaterController.updater
        return updater.automaticallyChecksForUpdates && updater.automaticallyDownloadsUpdates
    }

    func setAutomaticUpdatesEnabled(_ isEnabled: Bool) {
        let updater = standardUpdaterController.updater
        updater.automaticallyChecksForUpdates = isEnabled
        updater.automaticallyDownloadsUpdates = isEnabled
        objectWillChange.send()
    }

    func checkForUpdates() {
        standardUpdaterController.checkForUpdates(nil)
        objectWillChange.send()
    }
}
#else
@MainActor
final class UpdaterController: ObservableObject {
    var canCheckForUpdates: Bool { false }
    var automaticUpdatesEnabled: Bool { false }

    func setAutomaticUpdatesEnabled(_ isEnabled: Bool) {}
    func checkForUpdates() {}
}
#endif
