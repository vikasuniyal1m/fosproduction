import Flutter
import UIKit
import ClockKit

/// Registers the watch_face_installer channel (works with UIScene / FlutterSceneDelegate).
public class WatchFaceInstallerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "watch_face_installer",
      binaryMessenger: registrar.messenger()
    )
    let instance = WatchFaceInstallerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "installAppleWatchFace":
      guard
        let args = call.arguments as? [String: Any],
        let fileName = args["fileName"] as? String
      else {
        result(FlutterError(
          code: "BAD_ARGS",
          message: "Expected a 'fileName' argument.",
          details: nil
        ))
        return
      }
      let filePath = args["filePath"] as? String
      installAppleWatchFace(fileName: fileName, filePath: filePath, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func installAppleWatchFace(
    fileName: String,
    filePath: String?,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 14.0, *) else {
      result(FlutterError(
        code: "CLOCKKIT_UNAVAILABLE",
        message: "Watch face sharing requires iOS 14 or later.",
        details: nil
      ))
      return
    }

    #if targetEnvironment(simulator)
    result(FlutterError(
      code: "SIMULATOR_NOT_SUPPORTED",
      message: "Watch face install does not work in the iPhone Simulator, even with a paired Watch simulator. Use a real iPhone with a paired Apple Watch.",
      details: nil
    ))
    return
    #endif

    guard let fileURL = resolveWatchFaceURL(fileName: fileName, filePath: filePath) else {
      result(FlutterError(
        code: "FILE_NOT_FOUND",
        message: "Could not find \(fileName) in the app bundle or Documents.",
        details: nil
      ))
      return
    }

    let library = CLKWatchFaceLibrary()
    library.addWatchFace(at: fileURL) { error in
      DispatchQueue.main.async {
        if let error = error as NSError? {
          result(self.flutterError(for: error))
        } else {
          result([
            "success": true,
            "message": "Watch face sent to the Apple Watch app. Open it on your iPhone to add the face."
          ])
        }
      }
    }
  }

  private func resolveWatchFaceURL(fileName: String, filePath: String?) -> URL? {
    if let filePath = filePath,
       FileManager.default.fileExists(atPath: filePath) {
      return URL(fileURLWithPath: filePath)
    }

    let nsName = fileName as NSString
    let base = nsName.deletingPathExtension
    let ext = nsName.pathExtension.isEmpty ? "watchface" : nsName.pathExtension

    if let bundled = Bundle.main.url(forResource: base, withExtension: ext) {
      return bundled
    }

    let documents = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask
    ).first
    if let candidate = documents?.appendingPathComponent(fileName),
       FileManager.default.fileExists(atPath: candidate.path) {
      return candidate
    }
    return nil
  }

  @available(iOS 14.0, *)
  private func flutterError(for error: NSError) -> FlutterError {
    if error.domain == CLKWatchFaceLibrary.ErrorDomain,
       let code = CLKWatchFaceLibrary.ErrorCode(rawValue: error.code) {
      switch code {
      case .faceNotAvailable:
        return FlutterError(
          code: "NO_PAIRED_WATCH",
          message: "No paired Apple Watch is available for this face.",
          details: error.localizedDescription
        )
      case .invalidFile:
        return FlutterError(
          code: "INVALID_FILE",
          message: "The .watchface file is invalid or could not be parsed.",
          details: error.localizedDescription
        )
      @unknown default:
        break
      }
    }
    return FlutterError(
      code: "INSTALL_FAILED",
      message: error.localizedDescription,
      details: nil
    )
  }
}
