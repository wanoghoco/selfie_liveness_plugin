#import "SelfieLivenessPlugin.h"
#if __has_include(<selfie_liveness/selfie_liveness-Swift.h>)
#import <selfie_liveness/selfie_liveness-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "selfie_liveness-Swift.h"
#endif

@implementation SelfieLivenessPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSelfieLivenessPlugin registerWithRegistrar:registrar];
}
@end
