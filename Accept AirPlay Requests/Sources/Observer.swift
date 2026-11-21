import AppKit.NSRunningApplication
import ApplicationServices.HIServices

@MainActor
public final class AARNotificationCenterObserver: AARLoggable {
  public static let shared = AARNotificationCenterObserver()

  private static let notificationCenterBundleId = "com.apple.notificationcenterui"
  private static let observedNotifications = [
    kAXWindowCreatedNotification,
    kAXCreatedNotification,
    kAXLayoutChangedNotification,
  ]

  private let handler = AARAirPlayRequestsHandler()
  private var observer: AXObserver?
  private var observedPid: pid_t?

  private init() {}

  public func ensureObserving() {
    guard let pid = notificationCenterPid() else {
      stopObserving()
      return
    }
    guard pid != observedPid else { return }

    stopObserving()

    var newObserver: AXObserver?
    let createResult = AXObserverCreate(pid, { _, _, _, _ in
      MainActor.assumeIsolated { AARNotificationCenterObserver.shared.scan() }
    }, &newObserver)
    guard createResult == .success, let newObserver else {
      logger.error("failed to create ax observer, axerror code=\(createResult.rawValue, privacy: .public)")
      return
    }

    let application = AXUIElementCreateApplication(pid)
    let registered = Self.observedNotifications.filter { notification in
      let result = AXObserverAddNotification(newObserver, application, notification as CFString, nil)
      if result != .success {
        logger.error(
          "failed to observe \(notification, privacy: .public), axerror code=\(result.rawValue, privacy: .public)"
        )
      }
      return result == .success
    }
    guard !registered.isEmpty else { return }

    CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(newObserver), .commonModes)
    observer = newObserver
    observedPid = pid
    logger.info("observing notification center with pid=\(pid, privacy: .public)")
  }

  public func scan() {
    guard let pid = observedPid ?? notificationCenterPid() else { return }
    handler.scan(application: AXUIElementCreateApplication(pid))
  }

  private func stopObserving() {
    if let observer {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .commonModes)
      logger.debug("stopped observing notification center")
    }
    observer = nil
    observedPid = nil
  }

  private func notificationCenterPid() -> pid_t? {
    guard
      let application = NSRunningApplication.runningApplications(
        withBundleIdentifier: Self.notificationCenterBundleId
      ).first(where: { !$0.isTerminated })
    else {
      logger.error("failed to find notification center application")
      return nil
    }
    return application.processIdentifier
  }
}
