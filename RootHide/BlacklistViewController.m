#import "BlacklistViewController.h"
#include "AppDelegate.h"
#import "AppInfo.h"

BOOL isUUIDPathOf(NSString* path, NSString* parent);

BOOL isDefaultInstallationPath(NSString* path)
{
    return isUUIDPathOf(path, @"/private/var/containers/Bundle/Application/");
}

@interface PrivateApi_LSApplicationWorkspace
- (NSArray*)allInstalledApplications;
- (bool)openApplicationWithBundleID:(id)arg1;
- (NSArray*)privateURLSchemes;
- (NSArray*)publicURLSchemes;
@end

@interface BlacklistViewController () <UISearchBarDelegate> {
    UISearchController *searchController;
    NSArray *applications;
    NSArray *appsArray;
    
    NSMutableArray* filteredApps;
    BOOL isFiltered;
}

// Declare the reloadSearch method
- (void)reloadSearch;

@end

@implementation BlacklistViewController

+ (instancetype)sharedInstance {
    static BlacklistViewController* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setTitle:Localized(@"App List")];
    
    isFiltered = false;
    
    searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.delegate = self;
    searchController.searchBar.placeholder = Localized(@"Search by name or identifier");
    searchController.searchBar.barTintColor = [UIColor whiteColor];
    searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(manualRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    self->applications = [self updateData];
    self->appsArray = [self sortAppList:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoRefresh)
                                          name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)startRefresh:(BOOL)resort {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSArray* newData = [self updateData];
        dispatch_async(dispatch_get_main_queue(), ^{
            self->applications = newData;
            self->appsArray = [self sortAppList:resort];
            [self reloadSearch]; // Call reloadSearch here
            [self.tableView reloadData];
            [self.tableView.refreshControl endRefreshing];
        });
    });
}

- (void)manualRefresh {
    [self startRefresh:YES];
}

- (void)autoRefresh {
    [self startRefresh:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl endRefreshing];
}

- (NSArray*)sortAppList:(BOOL)sortWithStatus {
    NSArray *result = nil;
    
    if(sortWithStatus)
    {
        result = [applications sortedArrayUsingComparator:^NSComparisonResult(AppInfo *app1, AppInfo *app2) {
            return [app1.name localizedStandardCompare:app2.name];
        }];
    }
    else
    {
        NSMutableArray *newapps = [NSMutableArray array];
        [applications enumerateObjectsUsingBlock:^(AppInfo *newobj, NSUInteger idx, BOOL * _Nonnull stop) {
            __block BOOL hasBeenContained = NO;
            [self->appsArray enumerateObjectsUsingBlock:^(AppInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.bundleIdentifier isEqualToString:newobj.bundleIdentifier]) {
                    hasBeenContained = YES;
                    *stop = YES;
                }
            }];
            if (!hasBeenContained) {
                [newapps addObject:newobj];
            }
        }];
        
        NSMutableArray *tmpArray = [NSMutableArray array];
        [self->appsArray enumerateObjectsUsingBlock:^(AppInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [applications enumerateObjectsUsingBlock:^(AppInfo *newobj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.bundleIdentifier isEqualToString:newobj.bundleIdentifier]) {
                    [tmpArray addObject:newobj];
                    *stop = YES;
                }
            }];
        }];

        [tmpArray addObjectsFromArray:newapps];
        result = tmpArray.copy;
    }
    
    return result;
}

- (NSArray*)updateData {
    NSMutableArray* applications = [NSMutableArray new];
    PrivateApi_LSApplicationWorkspace* _workspace = [NSClassFromString(@"LSApplicationWorkspace") new];
    NSArray* allInstalledApplications = [_workspace allInstalledApplications];
    
    for(id proxy in allInstalledApplications)
    {
        AppInfo* app = [AppInfo appWithPrivateProxy:proxy];
        if(!app.isHiddenApp
           && ![app.bundleIdentifier hasPrefix:@"com.apple."]
           && isDefaultInstallationPath(app.bundleURL.path))
        {
            [applications addObject:app];
        }
    }
    
    return applications;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return isFiltered ? filteredApps.count : appsArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"App List";
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    AppInfo* app = isFiltered ? filteredApps[indexPath.row] : appsArray[indexPath.row];
    
    UIImage *image = app.icon;
    cell.imageView.image = [self imageWithImage:image scaledToSize:CGSizeMake(40, 40)];
    
    cell.textLabel.text = app.name;
    cell.detailTextLabel.text = app.bundleIdentifier;
    
    // Add a UISwitch to the cell
    UISwitch *switchView = [[UISwitch alloc] init];
    switchView.on = NO; // Default to disabled state
    [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchView;
    
    return cell;
}

- (void)switchChanged:(UISwitch *)sender {
    // Get the index path of the cell containing the switch
    CGPoint switchPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:switchPosition];
    
    if (indexPath) {
        AppInfo* app = isFiltered ? filteredApps[indexPath.row] : appsArray[indexPath.row];
        
        // Show the same popup as the long-press action
        [self showClearAppDataPopupForApp:app];
        
        // Revert the switch to the disabled state
        sender.on = NO;
    }
}

- (void)showClearAppDataPopupForApp:(AppInfo*)app {
    UIAlertController* appMenuAlert = [UIAlertController alertControllerWithTitle:app.name?:@""
                                                                         message:app.bundleIdentifier?:@""
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* cleanAction = [UIAlertAction actionWithTitle:@"Clear App Data"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction* action) {
        // Trigger the clear app data function
        [self cleanAppDataForApp:app];
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    [appMenuAlert addAction:cleanAction];
    [appMenuAlert addAction:cancelAction];
    
    [self presentViewController:appMenuAlert animated:YES completion:nil];
}

- (void)cleanAppDataForApp:(AppInfo*)app {
    void killAllForApp(const char* bundlePath);
    killAllForApp(app.bundleURL.path.UTF8String);
    
    NSString* error = nil;
    if(geteuid()==0 && getegid()==0) {
        NSString* clearAppData(AppInfo* app);
        error = clearAppData(app);
    } else {
        NSString* RootUserClearAppData(AppInfo* app);
        error = RootUserClearAppData(app);
    }
    if(error) {
        [AppDelegate showMessage:error title:Localized(@"Error")];
    } else {
        [AppDelegate showMessage:@"" title:Localized(@"Cleaned up")];
    }
}

- (void)reloadSearch {
    NSString* searchText = searchController.searchBar.text;
    if (searchText.length == 0) {
        isFiltered = false;
    } else {
        isFiltered = true;
        filteredApps = [[NSMutableArray alloc] init];
        searchText = searchText.lowercaseString;
        for (AppInfo* app in appsArray) {
            NSRange nameRange = [app.name.lowercaseString rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange bundleIdRange = [app.bundleIdentifier.lowercaseString rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound || bundleIdRange.location != NSNotFound) {
                [filteredApps addObject:app];
            }
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearch];
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    isFiltered = false;
    [self.tableView reloadData];
}
@end
