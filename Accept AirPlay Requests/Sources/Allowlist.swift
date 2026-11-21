import Foundation.NSUserDefaults

public struct AARDeviceAllowlist: Sendable {
  public static let defaultsKey = "AllowedDevices"

  private let entries: Set<String>?

  init(entries: [String]?) {
    self.entries = entries.map { Set($0.map(Self.normalized)) }
  }

  public static func current(from defaults: UserDefaults = .standard) -> Self {
    .init(entries: defaults.stringArray(forKey: defaultsKey))
  }

  public func allows(_ deviceName: String) -> Bool {
    guard let entries else { return true }
    return entries.contains(Self.normalized(deviceName))
  }

  private static func normalized(_ name: String) -> String {
    name.normalizedWhitespace.lowercased()
  }
}
