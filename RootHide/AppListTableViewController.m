// ref https://github.com/XsF1re/FlyJB-App

#import "AppListTableViewController.h"

#import "LMApp.h"

@interface PrivateApi_LSApplicationWorkspace
- (NSArray*)allInstalledApplications;
- (bool)openApplicationWithBundleID:(id)arg1;
- (NSArray*)privateURLSchemes;
- (NSArray*)publicURLSchemes;
@end

@interface AppListTableViewController () {
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

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length == 0) {
        isFiltered = false;
    } else {
        isFiltered = true;
        filteredApps = [[NSMutableArray alloc] init];
        
        for (LMApp* app in appsArray) {
            NSRange nameRange = [app.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange bundleIdRange = [app.bundleIdentifier rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(nameRange.location != NSNotFound || bundleIdRange.location != NSNotFound) {
                [filteredApps addObject:app];
            }
        }
    }
    
    [self.tableView reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setTitle:@"Blacklist"];
    
    isFiltered = false;
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.delegate = self;
    searchController.searchBar.placeholder = @"name or identifier";
    searchController.searchBar.barTintColor = [UIColor whiteColor];
    searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(startRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    [self updateData];
}

- (void)startRefresh {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self updateData];
        dispatch_async(dispatch_get_main_queue(), ^{
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
        if(!app.isHiddenApp && ([app.applicationType containsString:@"User"]))
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
    return [[UIView alloc] init];;
}
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] init];;
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [theSwitch setOn:[defaults boolForKey:app.bundleIdentifier]];
    
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:switchInCell.on forKey:app.bundleIdentifier];
    [defaults synchronize];
}
@end
