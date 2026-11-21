import ApplicationServices.HIServices

@MainActor
final class AARAirPlayRequestsHandler: AARLoggable {
  private static let maxSearchDepth = 12
  private static let messagingTimeoutSeconds: Float = 1

  private let strings: AARAirPlayNotificationStrings
  private var handledRequests: Set<String> = []

  init(strings: AARAirPlayNotificationStrings = .system) {
    self.strings = strings
  }

  func scan(application: AXUIElement) {
    AXUIElementSetMessagingTimeout(application, Self.messagingTimeoutSeconds)

    let windows = elements(of: application, attribute: kAXWindowsAttribute)
    guard !windows.isEmpty else {
      handledRequests.removeAll()
      return
    }
    for window in windows {
      search(window, depth: 0)
    }
  }

  private func search(_ element: AXUIElement, depth: Int) {
    if let acceptAction = acceptAction(of: element) {
      handle(element, acceptAction: acceptAction)
      return
    }
    guard depth < Self.maxSearchDepth else { return }
    for child in elements(of: element, attribute: kAXChildrenAttribute) {
      search(child, depth: depth + 1)
    }
  }

  private func acceptAction(of element: AXUIElement) -> CFString? {
    var namesRef: CFArray?
    guard
      AXUIElementCopyActionNames(element, &namesRef) == .success,
      let names = namesRef as? [String]
    else { return nil }

    return names.first { name in
      guard name.hasPrefix("Name:") else { return false }
      var descriptionRef: CFString?
      AXUIElementCopyActionDescription(element, name as CFString, &descriptionRef)
      let titles = [descriptionRef as String?, customActionTitle(from: name)].compactMap { $0 }
      return titles.contains(where: strings.isAcceptTitle)
    }.map { $0 as CFString }
  }

  private func handle(_ element: AXUIElement, acceptAction: CFString) {
    guard let deviceName = deviceName(of: element) else { return }

    let requestId = string(of: element, attribute: kAXIdentifierAttribute) ?? deviceName
    guard handledRequests.insert(requestId).inserted else { return }

    guard AARDeviceAllowlist.current().allows(deviceName) else {
      logger.notice("ignored airplay request from device not in allowlist: \(deviceName, privacy: .public)")
      return
    }

    let result = AXUIElementPerformAction(element, acceptAction)
    guard result == .success else {
      handledRequests.remove(requestId)
      logger.error("accept action failed with axerror code=\(result.rawValue, privacy: .public)")
      return
    }
    logger.info("accepted airplay request from device: \(deviceName, privacy: .public)")
  }

  private func deviceName(of element: AXUIElement) -> String? {
    let body = elements(of: element, attribute: kAXChildrenAttribute)
      .first { string(of: $0, attribute: kAXIdentifierAttribute)?.lowercased() == "body" }
      .flatMap { string(of: $0, attribute: kAXValueAttribute) }

    if let body, let deviceName = strings.deviceName(inBody: body) {
      return deviceName
    }
    return string(of: element, attribute: kAXDescriptionAttribute)
      .flatMap(strings.deviceName(inDescription:))
  }

  private func customActionTitle(from actionName: String) -> String? {
    actionName
      .dropFirst("Name:".count)
      .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
      .first
      .map(String.init)
  }

  private func elements(of element: AXUIElement, attribute: String) -> [AXUIElement] {
    var valueRef: CFTypeRef?
    AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef)
    return valueRef as? [AXUIElement] ?? []
  }

  private func string(of element: AXUIElement, attribute: String) -> String? {
    var valueRef: CFTypeRef?
    AXUIElementCopyAttributeValue(element, attribute as CFString, &valueRef)
    return valueRef as? String
  }
}
