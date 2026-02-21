import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  
  var audioPlayers: [String: AVAudioPlayer] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "retro_cam_audio", binaryMessenger: controller.binaryMessenger)
      
    audioChannel.setMethodCallHandler({ [weak self]
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        
      if call.method == "playSystemSound" {
         guard let args = call.arguments as? [String: Any], 
               let soundName = args["soundName"] as? String else {
             result(FlutterError(code: "INVALID_ARGS", message: "Invalid soundName", details: nil))
             return
         }
          
         let flutterKey = controller.lookupKey(forAsset: "assets/sounds/\(soundName).wav")
         if let path = Bundle.main.path(forResource: flutterKey, ofType: nil) {
             let soundURL = URL(fileURLWithPath: path)
             do {
                 let player = try AVAudioPlayer(contentsOf: soundURL)
                 player.volume = 1.0
                 player.prepareToPlay()
                 player.play()
                 self?.audioPlayers[soundName] = player
                 result(nil)
             } catch {
                 result(FlutterError(code: "AUDIO_ERROR", message: "Failed to play sound: \(error)", details: nil))
             }
         } else {
             result(FlutterError(code: "ASSET_MISSING", message: "Could not find asset: \(flutterKey)", details: nil))
         }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
