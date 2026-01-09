#import "AppDelegate.h"
#import "VarCleanRules.h"
#import "BlacklistViewController.h"
#import "varCleanController.h"
#import "SettingViewController.h"
#include "NSJSONSerialization+Comments.h"

#include <zlib.h>
#include <spawn.h>
#include <sys/mount.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <IOKit/IOKitLib.h>

@implementation AppDelegate

+ (id)getDefaultsForKey:(NSString*)key {
    NSString *configFilePath = jbroot(@"/var/mobile/Library/RootHide/RootHideConfig.plist");
    NSDictionary* defaults = [NSDictionary dictionaryWithContentsOfFile:configFilePath];
    return [defaults objectForKey:key];
}

+ (void)setDefaults:(NSObject*)value forKey:(NSString*)key {
    NSString *configFilePath = jbroot(@"/var/mobile/Library/RootHide/RootHideConfig.plist");
    NSMutableDictionary* defaults = [NSMutableDictionary dictionaryWithContentsOfFile:configFilePath];
    if(!defaults) defaults = [[NSMutableDictionary alloc] init];
    [defaults setValue:value forKey:key];
    [defaults writeToFile:configFilePath atomically:YES];
}

+ (void)showAlert:(UIAlertController*)alert {
    
    static dispatch_queue_t alertQueue = nil;
    
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken, ^{
        alertQueue = dispatch_queue_create("alertQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_async(alertQueue, ^{
        __block BOOL presenting = NO;
        __block BOOL presented = NO;
        while(!presenting) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIViewController* vc = UIApplication.sharedApplication.keyWindow.rootViewController;
                while(vc.presentedViewController){
                    vc = vc.presentedViewController;
                    if(vc.isBeingDismissed) {
                        return;
                    }
                }
                presenting = YES;
                [vc presentViewController:alert animated:YES completion:^{ presented=YES; }];
            });
            if(!presenting) usleep(1000*100);
        }
        while(!presented) usleep(100*1000);
    });
}

+ (void)showMessage:(NSString*)msg title:(NSString*)title {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert]; //may crash if on non-main thread
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Got It") style:UIAlertActionStyleDefault handler:nil]];
        [self showAlert:alert];
    });
}

+ (void)showDetectionWarning:(NSString*)msg {
    [AppDelegate showMessage:[NSString stringWithFormat:@"%@\n\n%@\n",Localized(@"⚠️Jailbreak Detection Warning⚠️"),msg] title:Localized(@"⚠️Warning⚠️")];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    __block int repeatCount=0;
    [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer* timer) {
        char* paths[][3] = {
            {"","Library/Preferences",".plist"},
            {"","Library/Application Support/Containers",""},
            {"","Library/SplashBoard/Snapshots",""},
            {"","Library/Caches",""},
            {"","Library/Saved Application State",".savedState"},
            {"","Library/WebKit",""},
            {"","Library/Cookies",".binarycookies"},
            {"","Library/HTTPStorages",""},
        };
        
        for(int i=0; i<sizeof(paths)/sizeof(paths[0]); i++) {
            char mobile[PATH_MAX];
            snprintf(mobile,sizeof(mobile),"/var/mobile/%s/%s%s%s", paths[i][1], NSBundle.mainBundle.bundleIdentifier.UTF8String, paths[i][0], paths[i][2]);
            if(access(mobile, F_OK)==0) {
                [NSFileManager.defaultManager removeItemAtPath:@(mobile) error:nil];
                NSLog(@"remove app file %s\n", mobile);
            }
        }
        
        repeatCount++;
        if(repeatCount > 40) {
            [timer invalidate];
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString* roothideDir = jbroot(@"/var/mobile/Library/RootHide");
    if(![NSFileManager.defaultManager fileExistsAtPath:roothideDir]) {
        NSDictionary* attr = @{NSFilePosixPermissions:@(0755), NSFileOwnerAccountID:@(501), NSFileGroupOwnerAccountID:@(501)};
        assert([NSFileManager.defaultManager createDirectoryAtPath:roothideDir withIntermediateDirectories:YES attributes:attr error:nil]);
    }
    
    NSString* jsonPath = [NSBundle.mainBundle pathForResource:@"varCleanRules" ofType:@"json"];
    NSLog(@"jsonPath=%@", jsonPath);
    NSData* jsonData = [NSData dataWithContentsOfFile:jsonPath];
    assert(jsonData != NULL);
    
    uLong hash = crc32(0, jsonData.bytes, (uInt)jsonData.length);
    NSLog(@"hash=%lx", hash);
    assert(hash==VARCLEANRULESHASH);
    
    NSError* err;
    NSDictionary *rules = [NSJSONSerialization JSONObjectWithCommentedData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) NSLog(@"json error=%@", err);
    assert(rules != NULL);
    NSLog(@"default rules=%@", rules);
    NSString *rulesFilePath = jbroot(@"/var/mobile/Library/RootHide/varCleanRules.plist");
    if([NSFileManager.defaultManager fileExistsAtPath:rulesFilePath]) {
        assert([NSFileManager.defaultManager removeItemAtPath:rulesFilePath error:nil]);
    }
    NSLog(@"copy default rules to %@", rulesFilePath);
    assert([rules writeToFile:rulesFilePath atomically:YES]);
    
    NSString *customedRulesFilePath = jbroot(@"/var/mobile/Library/RootHide/varCleanRules-custom.plist");
    if(![NSFileManager.defaultManager fileExistsAtPath:customedRulesFilePath]) {
        NSDictionary* template = [[NSDictionary alloc] init];
        assert([template writeToFile:customedRulesFilePath atomically:YES]);
    }
    
    self.window = UIWindow.alloc.init;
    self.window.backgroundColor = [UIColor clearColor];
    [self.window makeKeyAndVisible];
    
    BlacklistViewController *listController = [BlacklistViewController sharedInstance];
    varCleanController *cleanController = [varCleanController sharedInstance];
    SettingViewController *setController = [SettingViewController sharedInstance];
    
    
    listController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Blacklist",@"") image:[UIImage systemImageNamed:@"list.bullet.circle"] tag:0];
    cleanController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"varClean",@"") image:[UIImage systemImageNamed:@"trash"] tag:1];
    setController.tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Setting",@"") image:[UIImage systemImageNamed:@"gearshape"] tag:2];
    

    UINavigationController *listNavigationController = [[UINavigationController alloc] initWithRootViewController:listController];
    UINavigationController *cleanNavigationController = [[UINavigationController alloc] initWithRootViewController:cleanController];
    UINavigationController *setNavigationController = [[UINavigationController alloc] initWithRootViewController:setController];
    

    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[listNavigationController, cleanNavigationController, setNavigationController];
    
    //
    //tabBarController.tabBar.scrollEdgeAppearance = [UITabBarAppearance new];
    
    self.window.rootViewController = tabBarController;
    

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    NSMutableArray* prebootDefaultContents = @[
        @".fseventsd",
        @"active", //why don't some guys have this file on their devices?
        @"cryptex1",
        @"Cryptexes",
    ].mutableCopy;
    
    NSArray* activedBootDefaultContents = @[
        @"AppleInternal",
        @"private",
        @"System",
        @"usr",
        @"LocalPolicy.cryptex1.img4", //ios16+?
    ];
    
    NSMutableString* activedBootHash = [NSMutableString new];
    io_registry_entry_t registryEntry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/chosen");
    if (registryEntry) {
        CFDataRef bootManifestHashData = IORegistryEntryCreateCFProperty(registryEntry, CFSTR("boot-manifest-hash"), NULL, 0);
        CFIndex bootManifestHashLength = CFDataGetLength(bootManifestHashData);
        const UInt8* bytes = CFDataGetBytePtr(bootManifestHashData);
        if(bytes) for(int i=0; i<bootManifestHashLength; i++) {
            [activedBootHash appendFormat:@"%02X",bytes[i]];
        }
        CFRelease(bootManifestHashData);
        IOObjectRelease(registryEntry);
    }
    
    NSString* activedBootPath = (activedBootHash && activedBootHash.length>0) ? [@"/private/preboot" stringByAppendingPathComponent:activedBootHash] : nil;
    if(activedBootHash && activedBootPath && [NSFileManager.defaultManager fileExistsAtPath:activedBootPath])
    {
        [prebootDefaultContents addObject:activedBootHash];
        
        NSArray* prebootContent = [NSFileManager.defaultManager contentsOfDirectoryAtPath:@"/private/preboot" error:nil];
        
        NSArray* activedBootContent = [NSFileManager.defaultManager contentsOfDirectoryAtPath:activedBootPath error:nil];
        
        NSMutableSet* prebootContentUnknownSet = [NSMutableSet setWithArray:prebootContent];
        [prebootContentUnknownSet minusSet:[NSSet setWithArray:prebootDefaultContents]];
        
        NSMutableSet* activedBootContentUnknownSet = [NSMutableSet setWithArray:activedBootContent];
        [activedBootContentUnknownSet minusSet:[NSSet setWithArray:activedBootDefaultContents]];
        
        NSArray* unknownContents = [prebootContentUnknownSet.allObjects arrayByAddingObjectsFromArray:activedBootContentUnknownSet.allObjects];
        
        if(unknownContents.count > 0)
        {
            NSMutableArray* items = [NSMutableArray new];
            [unknownContents enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [items addObject:[NSString stringWithFormat:@"\"%@\"",obj]];
            }];
            
            [AppDelegate showDetectionWarning:[NSString stringWithFormat:@"%@:\n\n%@\n\n(%@)",Localized(@"Legacy rootless jailbreak(s)"), [items componentsJoinedByString:@"\n\n"], Localized(@"*WARNING*: Don't touch any other files in /private/preboot/, otherwise it will cause bootloop")]];
            
            pid_t pid=0;
            char* args[] = {"/sbin/mount", "-u", "-w", "/private/preboot", NULL};
            posix_spawn(&pid, args[0], NULL, NULL, args, NULL);
            if(pid > 0) {
                int status=0;
                waitpid(pid, &status, 0);
            }
        }
    }
    else
    {
        [AppDelegate showMessage:[NSString stringWithFormat:@"%@: %@",Localized(@"Unknown preboot system"),activedBootHash] title:Localized(@"Error")];
    }

    
    NSArray* defaultBindMounts = @[
        @"/usr/standalone/firmware",
        @"/System/Library/Pearl/ReferenceFrames",
        @"/System/Library/Caches/com.apple.factorydata",
    ];
    
    NSMutableArray* unknownBindMounts = [NSMutableArray new];
    
    struct statfs * ss=NULL;
    int n = getmntinfo(&ss, 0); //MNT_NOWAIT);
    for(int i=0; i<n; i++) {
        if(strcmp(ss[i].f_fstypename,"bindfs")==0) {
            if(![defaultBindMounts containsObject:@(ss[i].f_mntonname)]) {
                [unknownBindMounts addObject:@(ss[i].f_mntonname)];
            }
        }
    }
    
    if(unknownBindMounts.count > 0)
    {
        NSMutableArray* items = [NSMutableArray new];
        for(NSString* mnt in unknownBindMounts) {
            [items addObject:[NSString stringWithFormat:@"\n\"%@\"", mnt]];
        }
        
        [AppDelegate showDetectionWarning:[NSString stringWithFormat:@"%@:\n%@\n",Localized(@"Unknown Bindfs Mount(s)"),[items componentsJoinedByString:@"\n"]]];
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        int ports[] = { 22, 2222 };
        for(int i=0; i<sizeof(ports)/sizeof(ports[0]); i++)
        {
            int s = socket(AF_INET, SOCK_STREAM, 0);
            
            struct sockaddr_in a;
            a.sin_family = AF_INET;
            a.sin_addr.s_addr = inet_addr("127.0.0.1");
            a.sin_port = htons(ports[i]);
            
            BOOL detected = NO;
            
            if(connect(s, (struct sockaddr*)&a, sizeof(a)) == 0) {
                [AppDelegate showDetectionWarning:Localized(@"SSH Server has been installed, you can uninstall it via Sileo/Zebra.")];
                
                detected = YES;
            }
            
            close(s);
            
            if(detected) break;
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        int s = socket(AF_INET, SOCK_STREAM, 0);
        
        struct sockaddr_in a;
        a.sin_family = AF_INET;
        a.sin_addr.s_addr = inet_addr("127.0.0.1");
        a.sin_port = htons(44);

        if(connect(s, (struct sockaddr*)&a, sizeof(a)) == 0) {
            [AppDelegate showDetectionWarning:Localized(@"Dropbear has been installed, you can uninstall it via Sileo/Zebra.")];
        }
        
        close(s);
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        int s = socket(AF_INET, SOCK_STREAM, 0);
        
        struct sockaddr_in a;
        a.sin_family = AF_INET;
        a.sin_addr.s_addr = inet_addr("127.0.0.1");
        a.sin_port = htons(27042);
        
        if(connect(s, (struct sockaddr*)&a, sizeof(a)) == 0) {
            [AppDelegate showDetectionWarning:Localized(@"Frida Server has been installed, you can uninstall it via Sileo/Zebra.")];
        }
        
        close(s);
    });
    
    NSDictionary *proxySettings = (__bridge NSDictionary *)(CFNetworkCopySystemProxySettings());
    NSNumber* vpn = proxySettings[(NSString *)kCFNetworkProxiesHTTPEnable];
    if(vpn && vpn.boolValue) {
        [AppDelegate showDetectionWarning:Localized(@"Some apps may refuse to run because a VPN/Proxy is enabled.")];
    }
    
    return YES;
}
@end
