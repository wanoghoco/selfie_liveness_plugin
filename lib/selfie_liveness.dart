import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SelfieLiveness {
  static const MethodChannel _channel =
      MethodChannel("elatech_liveliness_plugin");

  static Future<String> detectLiveness(
      {required String msgselfieCapture, required String msgBlinkEye}) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return defaultTargetPlatform.toString();
    }
    String response = await _channel.invokeMethod("detectliveliness",
        {"msgselfieCapture": msgselfieCapture, "msgBlinkEye": msgBlinkEye});
    return response;
  }
}
