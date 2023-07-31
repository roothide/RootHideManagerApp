#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    
    assert(setuid(0) == 0);
    assert(setgid(0) == 0);
    assert(getuid() == 0);
    assert(getgid() == 0);
    
//    NSString * bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
//    dlopen("/System/Library/PrivateFrameworks/PreferencesUI.framework/PreferencesUI",  RTLD_NOW | RTLD_GLOBAL);
//    dlopen("/System/Library/PrivateFrameworks/Preferences.framework/Preferences",  RTLD_NOW | RTLD_GLOBAL);
//    Class PSAppDataUsagePolicyCacheClass = NSClassFromString(@"PSAppDataUsagePolicyCache");
//    id cacheInstance = [PSAppDataUsagePolicyCacheClass valueForKey:@"sharedInstance"];
//    SEL selector = NSSelectorFromString(@"setUsagePoliciesForBundle:cellular:wifi:");
//    ((bool (*)(id, SEL, NSString *, BOOL, BOOL))objc_msgSend)(
//            cacheInstance, selector, bundleIdentifier, true, true);
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
