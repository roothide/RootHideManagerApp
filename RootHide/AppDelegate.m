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

@interface AppDelegate ()
- (void)showAlert:(NSString*)title message:(NSString*)message;
@end

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

- (void)showAlert:(NSString*)title message:(NSString*)message {
    
    static dispatch_queue_t alertQueue = nil;
    
    static dispatch_once_t oncetoken;
    dispatch_once(&oncetoken, ^{
        alertQueue = dispatch_queue_create("alertQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    dispatch_async(alertQueue, ^{
        __block BOOL presented = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Got It") style:UIAlertActionStyleDefault handler:nil]];
            
            UIViewController* vc = self.window.rootViewController;
            while(vc.presentedViewController) vc = vc.presentedViewController;
            [vc presentViewController:alert animated:YES completion:^{ presented=YES; }];
        });
        
        while(!presented) usleep(100*1000);
    });
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString* roothideDir = jbroot(@"/var/mobile/Library/RootHide");
    if(![NSFileManager.defaultManager fileExistsAtPath:roothideDir]) {
        assert([NSFileManager.defaultManager createDirectoryAtPath:roothideDir withIntermediateDirectories:YES attributes:nil error:nil]);
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
    NSString* path = [NSString stringWithFormat:@"%s/../../../procursus", s.f_mntfromname];
    if(access(path.UTF8String, F_OK)==0) {
        [self showAlert:Localized(@"xinaA15 detected") message:Localized(@"xinaA15 jailbreak file has been installed, you can uninstall it via xinaA15 app or hide it in the settings of the RootHide app.")];
    }
    
    NSString* path2 = [NSString stringWithFormat:@"%s/../../../jb", s.f_mntfromname];
    if(access(path2.UTF8String, F_OK)==0) {

        NSString* msg = [NSString stringWithUTF8String:realpath(path2.UTF8String,NULL)];
        [self showAlert:Localized(@"fugu15 removed") message:msg];
        
        char* args[] = {"/sbin/mount", "-u", "-w", "/private/preboot", NULL};
        
        pid_t pid=0;
        assert(posix_spawn(&pid, args[0], NULL, NULL, args, NULL) == 0);
        
        assert([NSFileManager.defaultManager removeItemAtPath:path2 error:&err] == YES);

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
            [self showAlert:Localized(@"SSH Detected") message:Localized(@"SSH Service has been installed, you can uninstall it via Sileo/Zebra.")];
        }
        
        close(s);
    });
    
    return YES;
}
@end
