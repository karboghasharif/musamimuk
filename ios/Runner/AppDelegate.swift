import Flutter
import GoogleMaps
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Native Maps key from Info.plist (`GMSApiKey` ← SocialAuth.xcconfig).
  private var mapsApiKey: String = ""

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
      let trimmed = mapsKey.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty, !trimmed.contains("$(") {
        mapsApiKey = trimmed
        GMSServices.provideAPIKey(trimmed)
      }
    }
    // Required so FCM can present / receive notifications on iOS.
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.musamimuk/google_maps",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "unavailable", message: "AppDelegate gone", details: nil))
        return
      }
      switch call.method {
      case "getApiKey":
        result(self.mapsApiKey)
      case "isConfigured":
        result(!self.mapsApiKey.isEmpty)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
