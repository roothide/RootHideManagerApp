// ref https://github.com/XsF1re/FlyJB-App

#import "AppListTableViewController.h"
#include "AppDelegate.h"
#import "LMApp.h"

#include <sys/sysctl.h>

void killBundleForPath(const char* bundlePath)
{
    NSLog(@"killBundleForPath: %s", bundlePath);
    
    char realBundlePath[PATH_MAX];
    if(!realpath(bundlePath, realBundlePath))
        return;
    
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }
    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    size_t count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char* buffer = (char *)malloc(length);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            char *executablePath = buffer + sizeof(int);
            NSLog(@"executablePath [%d] %s", pid, executablePath);
            char realExecutablePath[PATH_MAX];
            if (realpath(executablePath, realExecutablePath)
                && strncmp(realExecutablePath, realBundlePath, strlen(realBundlePath)) == 0) {
                kill(pid, SIGKILL);
            }
        }
        free(buffer);
    }
    free(info);
}

@interface PrivateApi_LSApplicationWorkspace
- (NSArray*)allInstalledApplications;
- (bool)openApplicationWithBundleID:(id)arg1;
- (NSArray*)privateURLSchemes;
- (NSArray*)publicURLSchemes;
@end

@interface AppListTableViewController () {
    UISearchController *searchController;
    NSArray *appsArray;
    
    NSMutableArray* filteredApps;
    BOOL isFiltered;
}

@end

@implementation AppListTableViewController

+ (instancetype)sharedInstance {
    static AppListTableViewController* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isFiltered = false;
    [self.tableView reloadData];
}

-(void)reloadSearch {
    NSString* searchText = searchController.searchBar.text;
    if(searchText.length == 0) {
        isFiltered = false;
    } else {
        isFiltered = true;
        filteredApps = [[NSMutableArray alloc] init];
        searchText = searchText.lowercaseString;
        for (LMApp* app in appsArray) {
            NSRange nameRange = [app.name.lowercaseString rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange bundleIdRange = [app.bundleIdentifier.lowercaseString rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound || bundleIdRange.location != NSNotFound) {
                [filteredApps addObject:app];
            }
        }
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearch];
    [self.tableView reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setTitle:Localized(@"Blacklist")];
    
    isFiltered = false;
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.delegate = self;
    searchController.searchBar.placeholder = Localized(@"name or identifier");
    searchController.searchBar.barTintColor = [UIColor whiteColor];
    searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(startRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    [self updateData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startRefresh)
                                          name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)startRefresh {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self updateData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadSearch];
            [self.tableView reloadData];
            [self.tableView.refreshControl endRefreshing];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl endRefreshing];
}

- (void)updateData {
    NSMutableArray* applications = [NSMutableArray new];
    PrivateApi_LSApplicationWorkspace* _workspace = [NSClassFromString(@"LSApplicationWorkspace") new];
    NSArray* allInstalledApplications = [_workspace allInstalledApplications];
    
    for(id proxy in allInstalledApplications)
    {
        LMApp* app = [LMApp appWithPrivateProxy:proxy];
        //if(!app.isHiddenApp && ([app.applicationType containsString:@"User"]))
        if(!app.isHiddenApp
           && ![app.bundleIdentifier hasPrefix:@"com.apple."]
           && ([app.bundleURL.path hasPrefix:@"/private/var/containers/Bundle/Application/"]))
        {
            [applications addObject:app];
        }
    }
    
    NSArray *appsSortedByName = [applications sortedArrayUsingComparator:^NSComparisonResult(LMApp *app1, LMApp *app2) {
        return [app1.name localizedStandardCompare:app2.name];
    }];
    
    self->appsArray = appsSortedByName;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(isFiltered)
        return filteredApps.count;
    return appsArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Applist";
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    LMApp* app = appsArray[indexPath.row];
    
    if(isFiltered) {
        app = filteredApps[indexPath.row];
    }
    
    UIImage *image = app.icon;
    cell.imageView.image = [self imageWithImage:image scaledToSize:CGSizeMake(40, 40)];
    
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.bundleIdentifier;
    
    UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    
    NSMutableDictionary* appconfig = [AppDelegate getDefaultsForKey:@"appconfig"];
    [theSwitch setOn:[[appconfig objectForKey:app.bundleIdentifier] boolValue]];
    
    cell.accessoryView = theSwitch;
    [theSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    return cell;
}

- (void)switchChanged:(id)sender {
    // https://stackoverflow.com/questions/31063571/getting-indexpath-from-switch-on-uitableview
    UISwitch *switchInCell = (UISwitch *)sender;
    CGPoint pos = [switchInCell convertPoint:switchInCell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pos];
    
    LMApp* app = appsArray[indexPath.row];
    
    if(isFiltered) {
        app = filteredApps[indexPath.row];
    }
    
    NSMutableDictionary* appconfig = [AppDelegate getDefaultsForKey:@"appconfig"];
    if(!appconfig) appconfig = [[NSMutableDictionary alloc] init];
    [appconfig setObject:@(switchInCell.on) forKey:app.bundleIdentifier];
    [AppDelegate setDefaults:appconfig forKey:@"appconfig"];
    
    
    killBundleForPath(app.bundleURL.path.UTF8String);
    
}
@end
