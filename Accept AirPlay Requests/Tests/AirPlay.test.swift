import Testing
@testable import Accept_AirPlay_Requests

@Suite struct AARAirPlayNotificationStringsTests {
  private let strings = AARAirPlayNotificationStrings(localizations: [
    "en": ["ACCEPT": "Accept", "AIRPLAY_BODY": "“%@” would like to AirPlay to this Mac."],
    "ru": ["ACCEPT": "Принять", "AIRPLAY_BODY": "«%@» собирается выполнить AirPlay на\u{a0}этот Mac."],
    "de": ["ACCEPT": "Akzeptieren", "AIRPLAY_BODY": "„%1$@“ möchte Inhalte mit AirPlay auf diesen Mac übertragen."],
  ])

  @Test func extractsDeviceNameFromBodyInAnyLocalization() {
    #expect(strings.deviceName(inBody: "“iPhone Маши” would like to AirPlay to this Mac.") == "iPhone Маши")
    #expect(strings.deviceName(inBody: "«iPad» собирается выполнить AirPlay на этот Mac.") == "iPad")
    #expect(strings.deviceName(inBody: "„MacBook“ möchte Inhalte mit AirPlay auf diesen Mac übertragen.") == "MacBook")
  }

  @Test func rejectsUnrelatedBody() {
    #expect(strings.deviceName(inBody: "test body") == nil)
  }

  @Test func extractsDeviceNameFromBannerDescription() {
    #expect(strings.deviceName(inDescription: "AirPlay, “iPhone” would like to AirPlay to this Mac.") == "iPhone")
    #expect(strings.deviceName(inDescription: "Script Editor, Title, body") == nil)
  }

  @Test func matchesAcceptTitlesOnly() {
    #expect(strings.isAcceptTitle("Принять"))
    #expect(strings.isAcceptTitle("accept"))
    #expect(!strings.isAcceptTitle("Отклонить"))
  }
}

@Suite struct AARDeviceAllowlistTests {
  @Test func allowsEveryDeviceWithoutConfiguredList() {
    #expect(AARDeviceAllowlist(entries: nil).allows("Any iPhone"))
  }

  @Test func allowsOnlyListedDevices() {
    let allowlist = AARDeviceAllowlist(entries: ["iPhone Маши"])
    #expect(allowlist.allows("iphone  маши"))
    #expect(!allowlist.allows("iPhone Пети"))
  }

  @Test func deniesEveryDeviceWithEmptyList() {
    #expect(!AARDeviceAllowlist(entries: []).allows("iPhone"))
  }
}
