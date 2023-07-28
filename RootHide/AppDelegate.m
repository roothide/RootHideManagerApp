#import "AppDelegate.h"
#import "AppListTableViewController.h"
#import "VarCleanController.h"
#import "SettingTableViewController.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
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
