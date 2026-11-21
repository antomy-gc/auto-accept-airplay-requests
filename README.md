<div align="center">
  <picture><img src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/logo.png" alt="Logo" title="(Auto) Accept AirPlay Requests" align="middle" width="100" /></picture>

  # [(Auto) Accept AirPlay Requests](https://auto-accept-airplay-requests.duddu.dev)

  [RELEASE_BADGE]: https://img.shields.io/github/v/release/duddu/auto-accept-airplay-requests?logo=github&logoColor=white
  [SWIFT_BADGE]: https://img.shields.io/badge/swift-v6.0.3-de5d43?logo=swift&logoColor=white
  [ANALYZE_BADGE]: https://img.shields.io/github/actions/workflow/status/duddu/auto-accept-airplay-requests/analyze.yml?logo=github&logoColor=white&label=codeql
  [ANALYZE_WORKFLOW]: https://github.com/duddu/auto-accept-airplay-requests/actions/workflows/analyze.yml
  [TEST_BADGE]: https://img.shields.io/github/actions/workflow/status/duddu/auto-accept-airplay-requests/test.yml?logo=github&logoColor=white&label=tests
  [TEST_WORKFLOW]: https://github.com/duddu/auto-accept-airplay-requests/actions/workflows/test.yml
  [DOCS_BADGE]: https://img.shields.io/github/actions/workflow/status/duddu/auto-accept-airplay-requests/docs.yml?logo=github&logoColor=white&label=vuepress
  [DOCS_WORKFLOW]: https://github.com/duddu/auto-accept-airplay-requests/actions/workflows/docs.yml

  [![GitHub Latest Release][RELEASE_BADGE]](https://github.com/duddu/auto-accept-airplay-requests/releases/latest)
  [![Swift Version][SWIFT_BADGE]](#)
  [![GitHub Actions Analyze Status][ANALYZE_BADGE]][ANALYZE_WORKFLOW]
  [![GitHub Actions Test Status][TEST_BADGE]][TEST_WORKFLOW]
  [![GitHub Actions Docs Status][DOCS_BADGE]][DOCS_WORKFLOW]
</div>
<br>

<!-- #region content -->
<picture>
  <source media="(min-width: 880px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/airplay-notification.png 2x" />
  <img align="right" alt="AirPlay notification alert" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/empty.png" />
</picture>

A lightweight, single-purpose macOS app that automatically allows other devices to AirPlay to your computer, eliminating the need for manual intervention—otherwise required when the device is signed into a different iCloud account. It detects incoming notification alerts for devices attempting to AirPlay to your Mac and programmatically accepts them.

This fork of [duddu/auto-accept-airplay-requests](https://github.com/duddu/auto-accept-airplay-requests) accepts a request as soon as its notification appears, works with every macOS language, and can limit acceptance to an allowlist of devices.

## Feature Highlights

- Accepts requests the moment the notification appears: an **Accessibility observer** on Notification Center triggers the check, with a fallback scan every 2 seconds
- Works in **every macOS language**: the notification text and the "Accept" button title are read from the localization tables of macOS itself
- Optional **allowlist** of devices allowed to AirPlay without confirmation
- Minimal **resource consumption**, meant to run forever with no impact
- Written in **Swift 6**, built as executable with no dependencies 
- Operates as a low-priority, self-recovering **background process**
- Auto-starts on login as registered **Launch Agent** (can be disabled)
- Ensures required **permissions** and gracefully handles their absence

## Get Started

- Build the app from source with Xcode:
  ```sh
  xcodebuild -project "Accept AirPlay Requests.xcodeproj" \
    -scheme "Accept AirPlay Requests" \
    -configuration Release \
    -derivedDataPath "$PWD/DerivedData/Accept AirPlay Requests" \
    build
  ```
  The application bundle is written to `DerivedData/Accept AirPlay Requests/Build/Products/Release/Accept AirPlay Requests.app`.
- Move the application bundle ("Accept AirPlay Requests.app") to your preferred folder (e.g. /Applications or /Users/YourUser/Applications).
- Double click to open the app; an alert will instruct you how to grant the required permission.

> [!NOTE]
> The project signs the app with an Apple Development certificate of team `4QLLA9Y6LR`. To sign with your own team, append `DEVELOPMENT_TEAM=<your team id>` to the build command. An ad-hoc signature (`CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=`) works too, but macOS then resets the Accessibility permission after every rebuild.

After the initial setup, the application will now run in the background (i.e. no visible icon on your Dock), and will only bother you in case your action is needed (e.g. a needed permission was revoked).

## Use cases

This app is for anyone wishing to regularly use a Mac as an AirPlay receiver from a device not logged into the same iCloud account, especially if they cannot always promptly react to incoming notifications on that computer.

E.g. let's say you have a Mac at home that you use mainly as a media/data server, so it may not always be connected to a physical monitor, mouse, or keyboard (e.g. maybe you mainly access it via VNC or SSH). You just want anybody on your network to be able to AirPlay to it from their device. Sounds easy? Right! Sadly, this will never happen without your manual intervention: macOS will *always* pop up a notification alert for you to accept, *unless* you are logged into iCloud with the very same Apple account on both the device and the receiver Mac.  
This happens even if you both are **on the same network**, even if you **previously approved** the same device, and even if the device user is in your **same iCloud Family**.

<picture class="allow-airplay-for">
  <source media="(min-width: 1070px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/allow-airplay-for-settings.png 2x" />
  <img align="right" alt="Allow AirPlay for" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/empty.png" />
</picture>

> [!NOTE]
> This behavior is not affected by the option you selected in *System Settings > General > AirDrop & Handoff > **Allow AirPlay for***. That setting (albeit still required) only determines which devices will be able to *detect* your Mac as an AirPlay receiver.

## Usage & Configuration

### Privacy & Security

<picture>
  <source media="(min-width: 980px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/accessibility-permission.png 2x" />
  <img align="right" alt="Accessibility permission" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/empty.png" />
</picture>

The only required permission is in *System Settings > Privacy & Security > **Accessibility***. It's needed to simulate clickling the "Accept" button on the incoming AirPlay notifications. The app ensures automatically this permission has been granted and alerts you with instructions if not.

### Allowed devices

By default every incoming AirPlay request is accepted. To accept requests only from specific devices, list their names in the `AllowedDevices` preference:

```sh
defaults write dev.duddu.AcceptAirPlayRequests AllowedDevices -array "Masha's iPhone" "Living Room iPad"
```

The running app applies changes immediately. Names are compared ignoring letter case and repeated spaces. Requests from other devices stay on screen for you to accept or decline manually, and the app logs the name of every ignored device (see [Logging](#logging)): the log shows the exact name a device uses. An empty list (`-array` with no names) leaves every request to manual confirmation.

To accept every device again:

```sh
defaults delete dev.duddu.AcceptAirPlayRequests AllowedDevices
```

A device name is chosen by its owner and can be changed at any time, so anyone who knows an allowed name can reuse it.

### Stop the background process

<picture>
  <source media="(min-width: 980px)" srcset="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/allow-in-the-background.png 2x" />
  <img align="right" alt="Allow in the Background" src="https://raw.githubusercontent.com/duddu/auto-accept-airplay-requests/refs/heads/latest/Docs/assets/empty.png" />
</picture>

As the app runs in the background, to manage it you can always use the toggle in *System Settings > General > Login Items & Extensions > **Allow in the Background***. Disabling the app there will stop the background process and prevent it from auto-start on login. You can toggle it back on anytime.

### Check the app is running

If at anytime you want to check the app is running in the background as expected (after checking it's toggled on in *System Settings > General > Login Items & Extensions > **Allow in the Background***), you can do so by just double-click the app (as if to re-open it): an info alert with title "App running in the background" will confirm you all is working.  
Of course, another obvious option is to look for the app name in Activity Monitor. One last is to stream the [logging](#logging) emitted by the running app.

### Update the app version

To update the app, you must first [stop](#stop-the-background-process) the running background process. Then, simply replace the existing application bundle ("Accept AirPlay Requests.app") with a newly built one and re-enable the background process.  
After that re-open the app file just to [check it's running](#check-the-app-is-running).

### Uninstall the app

First [stop](#stop-the-background-process) the running background process, then move the application bundle ("Accept AirPlay Requests.app") to the Trash. Any configuration related to this app will be automatically removed from System Settings after the next system reboot.

## Development

Feel free to report any issue or suggest an enhancement. Any contribution is more than welcome: please open your Pull Request against the *latest* branch.

### Logging

Run the following command from your terminal to live-stream all logs emitted by the app:

```sh
log stream --predicate 'subsystem CONTAINS "dev.duddu.AcceptAirPlayRequests"' --level debug
```
<!-- #endregion content -->
