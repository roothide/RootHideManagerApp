#import "AppDelegate.h"
#import "AppListTableViewController.h"
#import "VarCleanController.h"
#import "SettingTableViewController.h"
#include "NSJSONSerialization+Comments.h"

@interface AppDelegate ()
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString* roothideDir = jbroot(@"/var/mobile/Library/RootHide");
    if(![NSFileManager.defaultManager fileExistsAtPath:roothideDir]) {
        assert([NSFileManager.defaultManager createDirectoryAtPath:roothideDir withIntermediateDirectories:YES attributes:nil error:nil]);
    }
    
    NSString* jsonPath = [NSBundle.mainBundle pathForResource:@"VarCleanRules" ofType:@"json"];
    NSLog(@"jsonPath=%@", jsonPath);
    NSData* jsonData = [NSData dataWithContentsOfFile:jsonPath];
    assert(jsonData != NULL);
    NSError* err;
    NSDictionary *rules = [NSJSONSerialization JSONObjectWithCommentedData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) NSLog(@"json error=%@", err);
    assert(rules != NULL);
    NSLog(@"default rules=%@", rules);
    NSString *rulesFilePath = jbroot(@"/var/mobile/Library/RootHide/VarCleanRules.plist");
    if([NSFileManager.defaultManager fileExistsAtPath:rulesFilePath]) {
        assert([NSFileManager.defaultManager removeItemAtPath:rulesFilePath error:nil]);
    }
    NSLog(@"copy default rules to %@", rulesFilePath);
    assert([rules writeToFile:rulesFilePath atomically:YES]);
    
    NSString *customedRulesFilePath = jbroot(@"/var/mobile/Library/RootHide/VarCleanRules-custom.plist");
    if(![NSFileManager.defaultManager fileExistsAtPath:customedRulesFilePath]) {
        NSDictionary* template = [[NSDictionary alloc] init];
        assert([template writeToFile:customedRulesFilePath atomically:YES]);
    }
    
    self.window = UIWindow.alloc.init;
    self.window.backgroundColor = [UIColor clearColor];
    [self.window makeKeyAndVisible];
    
    AppListTableViewController *listController = [AppListTableViewController sharedInstance];
    VarCleanController *cleanController = [VarCleanController sharedInstance];
    SettingTableViewController *setController = [SettingTableViewController sharedInstance];
    
    
    listController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Blacklist" image:[UIImage systemImageNamed:@"list.bullet.circle"] tag:0];
    cleanController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"VarClean" image:[UIImage systemImageNamed:@"clear"] tag:1];
    setController.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Setting" image:[UIImage systemImageNamed:@"gearshape"] tag:2];
    

    UINavigationController *listNavigationController = [[UINavigationController alloc] initWithRootViewController:listController];
    UINavigationController *cleanNavigationController = [[UINavigationController alloc] initWithRootViewController:cleanController];
    UINavigationController *setNavigationController = [[UINavigationController alloc] initWithRootViewController:setController];
    

    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    tabBarController.viewControllers = @[listNavigationController, cleanNavigationController, setNavigationController];
    
    //
    //tabBarController.tabBar.scrollEdgeAppearance = [UITabBarAppearance new];
    
    self.window.rootViewController = tabBarController;
    
    return YES;
}
@end
