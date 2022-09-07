import Flutter
import UIKit

public class SwiftSelfieLivenessPlugin: NSObject, FlutterPlugin, DismissProtocol {
    var receivedPath = String()
    var resultCallback : FlutterResult!
    
    
    func sendData(filePath: String) {
            receivedPath = filePath
            if resultCallback != nil{
                resultCallback(filePath)
            }else{
                resultCallback("")
            }
        }
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "elatech_liveliness_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftSelfieLivenessPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      resultCallback=result;
      if(call.method=="detectliveliness"){
          detectFace(call:call)
      }
  }
    
    func detectFace(call:FlutterMethodCall){
                   var msgselfieCapture = ""
                   var msgBlinkEye = ""
                   guard let args = call.arguments else {
                       return
                   }
                   if let myArgs = args as? [String: Any],
                       let captureText = myArgs["msgselfieCapture"] as? String,
                       let blinkText = myArgs["msgBlinkEye"] as? String{
                       msgselfieCapture = captureText
                       msgBlinkEye = blinkText
                   }
              self.detectLiveness(captureMessage: msgselfieCapture, blinkMessage: msgBlinkEye)
              
            }
       
       
     public func detectLiveness(captureMessage: String, blinkMessage: String){
           if let viewController = UIApplication.shared.windows.first?.rootViewController as? FlutterViewController{
               let storyboardName = "MainLive"
               let storyboardBundle = Bundle.init(for: type(of: self))
               let storyboard = UIStoryboard(name: storyboardName, bundle: storyboardBundle)
               if let vc = storyboard.instantiateViewController(withIdentifier: "TestViewController") as? TestViewController {
                   vc.captureMessageText = captureMessage
                   vc.modalPresentationStyle = .fullScreen
                   vc.blinkMessageText = blinkMessage
                   viewController.present(vc, animated: true, completion: nil)
                   vc.dismissDelegate = self
               }
           }
       }
}
