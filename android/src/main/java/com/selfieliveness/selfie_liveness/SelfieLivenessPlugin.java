package com.selfieliveness.selfie_liveness;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/** SelfieLivenessPlugin */
public class SelfieLivenessPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {

  ActivityPluginBinding binding;
  private SelfieDelegate delegate;
  private MethodChannel channel;


  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "elatech_liveliness_plugin");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("detectliveliness")) {
      detectLiveness(call,result);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    channel.setMethodCallHandler(null);
  }

  private void detectLiveness(MethodCall call,Result result){
    delegate.detectLivelinesss(call, result);
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
  this.binding=binding;
  this.delegate= new SelfieDelegate(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }
}
