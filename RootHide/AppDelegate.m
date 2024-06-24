#import "AppDelegate.h"
#import "BlacklistViewController.h"
#import "varCleanController.h"
#import "SettingViewController.h"
#include "NSJSONSerialization+Comments.h"

#include <sys/mount.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <spawn.h>

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
        
        __block UIViewController* availableVC=nil;
        while(!availableVC) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController* vc = UIApplication.sharedApplication.keyWindow.rootViewController;
                while(vc.presentedViewController){
                    vc = vc.presentedViewController;
                    if(vc.isBeingDismissed) return;
                }
                availableVC = vc;
            });
            if(!availableVC) usleep(1000*100);
        }
        
        __block BOOL presented = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [availableVC presentViewController:alert animated:YES completion:^{ presented=YES; }];
        });
        
        while(!presented) usleep(100*1000);
    });
}

+ (void)showMessage:(NSString*)msg title:(NSString*)title {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Got It") style:UIAlertActionStyleDefault handler:nil]];
    [self showAlert:alert];
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
    
    struct statfs s={0};
    statfs("/usr/standalone/firmware", &s);
    NSString* path = [NSString stringWithFormat:@"%s/../../../", s.f_mntfromname];
    NSArray* defaultContent = @[
        @"AppleInternal",
        @"private",
        @"System",
        @"usr",
        @"LocalPolicy.cryptex1.img4", //ios16+?
    ];
    NSArray* prebootContent = [NSFileManager.defaultManager contentsOfDirectoryAtPath:path error:nil];
    NSMutableSet* prebootContentSet = [NSMutableSet setWithArray:prebootContent];
    [prebootContentSet minusSet:[NSSet setWithArray:defaultContent]];
    if(prebootContentSet.count > 0) {
        
        NSMutableArray* items = [NSMutableArray new];
        [prebootContentSet.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [items addObject:[NSString stringWithFormat:@"\"%@/%@\"",[path stringByResolvingSymlinksInPath],obj]];
        }];

        [AppDelegate showMessage:[NSString stringWithFormat:@"\n%@\n\n\n(%@)",
                                  [items componentsJoinedByString:@"\n\n"],
                                  Localized(@"*WARNING*: Don't touch any other files in /private/preboot/, otherwise it will cause bootloop")]
                           title:Localized(@"legacy rootless jailbreak Detected")];
        
        char* args[] = {"/sbin/mount", "-u", "-w", "/private/preboot", NULL};
        
        pid_t pid=0;
        assert(posix_spawn(&pid, args[0], NULL, NULL, args, NULL) == 0);
        
        int status=0;
        waitpid(pid, &status, 0);
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        int s = socket(AF_INET, SOCK_STREAM, 0);
        
        struct sockaddr_in a;
        a.sin_family = AF_INET;
        a.sin_addr.s_addr = inet_addr("127.0.0.1");
        a.sin_port = htons(22);

        if(connect(s, (struct sockaddr*)&a, sizeof(a)) == 0) {
            [AppDelegate showMessage:Localized(@"SSH Service has been installed, you can uninstall it via Sileo/Zebra.") title:Localized(@"SSH Detected")];
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
            [AppDelegate showMessage:Localized(@"Frida Service has been installed, you can uninstall it via Sileo/Zebra.") title:Localized(@"Frida Detected")];
        }
        
        close(s);
    });
    
    return YES;
}
@end
