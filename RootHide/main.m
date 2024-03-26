#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/message.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    
    //Keyboard Preference & Localized won't work
//    assert(setuid(0) == 0);
//    assert(getuid() == 0);
//    assert(setgid(0) == 0);
//    assert(getgid() == 0);
    
    NSLog(@"uid=%d euid=%d gid=%d egid=%d", getuid(), geteuid(), getgid(), getegid());
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
