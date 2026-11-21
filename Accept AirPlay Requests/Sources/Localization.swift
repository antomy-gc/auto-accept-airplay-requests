import Foundation

public struct AARAirPlayNotificationStrings: Sendable, AARLoggable {
  public struct BodyTemplate: Sendable, Hashable {
    let prefix: String
    let suffix: String

    init?(format: String) {
      let format = format.normalizedWhitespace
      guard let placeholder = format.range(of: #"%(\d+\$)?@"#, options: .regularExpression)
      else { return nil }
      prefix = String(format[..<placeholder.lowerBound])
      suffix = String(format[placeholder.upperBound...])
    }

    func deviceName(in text: String) -> String? {
      guard
        text.count >= prefix.count + suffix.count,
        text.hasPrefix(prefix),
        text.hasSuffix(suffix)
      else { return nil }
      return String(text.dropFirst(prefix.count).dropLast(suffix.count))
    }
  }

  public static let systemTableURL = URL(
    filePath: "/System/Library/UserNotifications/Bundles/com.apple.controlcenter.notifications.airplay.bundle/Contents/Resources/Localizable.loctable"
  )

  static let fallbackLocalizations: [String: [String: String]] = [
    "en": ["ACCEPT": "Accept", "AIRPLAY_BODY": "“%@” would like to AirPlay to this Mac."]
  ]

  public static let system = Self(contentsOf: systemTableURL)

  let acceptTitles: Set<String>
  let bodyTemplates: Set<BodyTemplate>

  init(localizations: [String: [String: String]]) {
    let tables = localizations.values
    acceptTitles = Set(tables.compactMap { $0["ACCEPT"]?.normalizedWhitespace.lowercased() })
    bodyTemplates = Set(tables.compactMap { $0["AIRPLAY_BODY"].flatMap(BodyTemplate.init) })
  }

  init(contentsOf url: URL) {
    guard
      let data = try? Data(contentsOf: url),
      let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
      let root = plist as? [String: Any]
    else {
      Self.logger.error("failed to load localizations from \(url.path, privacy: .public)")
      self.init(localizations: Self.fallbackLocalizations)
      return
    }

    let localizations = root.compactMapValues { table in
      (table as? [String: Any])?.compactMapValues { $0 as? String }
    }
    self.init(localizations: localizations.merging(Self.fallbackLocalizations) { current, _ in current })
    Self.logger.debug("loaded \(localizations.count) localizations")
  }

  public func isAcceptTitle(_ title: String) -> Bool {
    acceptTitles.contains(title.normalizedWhitespace.lowercased())
  }

  public func deviceName(inBody body: String) -> String? {
    let body = body.normalizedWhitespace
    return bodyTemplates.lazy.compactMap { $0.deviceName(in: body) }.first
  }

  public func deviceName(inDescription description: String) -> String? {
    let parts = description.normalizedWhitespace.components(separatedBy: ", ")
    return parts.indices.lazy
      .compactMap { deviceName(inBody: parts[$0...].joined(separator: ", ")) }
      .first
  }
}

extension String {
  var normalizedWhitespace: String {
    components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }
}
