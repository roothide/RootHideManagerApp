// JailbreakDetectorViewController.m

#import "JailbreakDetectorViewController.h"
#import "detection.h"

@interface JailbreakDetectorViewController () <UITableViewDataSource, UITableViewDelegate>
- (void)setupTableView; // Private method declaration
@end

@implementation JailbreakDetectorViewController

+ (BOOL)anyJailbreakChecksDetected {
    NSArray *checks = @[
        @(detect_rootlessJB()), @(detect_kernBypass()), @(detect_chroot()),
        @(detect_mount_fs()), @(detect_bootstraps()), @(detect_trollStoredFilza()),
        @(detect_exception_port()), @(detect_jailbreakd()), @(detect_proc_flags()),
        @(detect_jb_payload()), @(detect_jb_preboot()), @(detect_jailbroken_apps()),
        @(detect_removed_varjb()), @(detect_fugu15Max()), @(detect_url_schemes()),
        @(detect_jbapp_plugins()), @(detect_jailbreak_sigs()), @(detect_jailbreak_port()),
        @(detect_launchd_jbserver()), @(detect_trollstore_app()), @(detect_passcode_status())
    ];
    for (NSNumber *detected in checks) {
        if ([detected boolValue]) return YES;
    }
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"RootHide JailbreakDetector";
    self.view.backgroundColor = [UIColor whiteColor];

    self.detectionMethods = @[
        @{ @"name": @"Jailbreak Path", @"detected": @(detect_rootlessJB()) },
        @{ @"name": @"Kernel Bypass", @"detected": @(detect_kernBypass()) },
        @{ @"name": @"Chroot", @"detected": @(detect_chroot()) },
        @{ @"name": @"Mount FS", @"detected": @(detect_mount_fs()) },
        @{ @"name": @"Bootstraps", @"detected": @(detect_bootstraps()) },
        @{ @"name": @"TrollStored Filza", @"detected": @(detect_trollStoredFilza()) },
        @{ @"name": @"Jailbreakd", @"detected": @(detect_jailbreakd()) },
        @{ @"name": @"Proc Flags", @"detected": @(detect_proc_flags()) },
        @{ @"name": @"JB Payload", @"detected": @(detect_jb_payload()) },
        @{ @"name": @"JB Preboot", @"detected": @(detect_jb_preboot()) },
        @{ @"name": @"Jailbroken Apps", @"detected": @(detect_jailbroken_apps()) },
        @{ @"name": @"Removed /var/jb", @"detected": @(detect_removed_varjb()) },
        @{ @"name": @"Fugu15 Max", @"detected": @(detect_fugu15Max()) },
        @{ @"name": @"URL Schemes", @"detected": @(detect_url_schemes()) },
        @{ @"name": @"JB App Plugins", @"detected": @(detect_jbapp_plugins()) },
        @{ @"name": @"JB Sigs", @"detected": @(detect_jailbreak_sigs()) },
        @{ @"name": @"JB Port", @"detected": @(detect_jailbreak_port()) },
        @{ @"name": @"Launchd JBserver", @"detected": @(detect_launchd_jbserver()) },
        @{ @"name": @"TrollStore", @"detected": @(detect_trollstore_app()) },
        @{ @"name": @"Passcode Status", @"detected": @(detect_passcode_status()) }
    ];

    [self setupTableView];
}

- (void)setupTableView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
}

#pragma mark - UITableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.detectionMethods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    NSDictionary *method = self.detectionMethods[indexPath.row];
    cell.textLabel.text = method[@"name"];
    cell.detailTextLabel.text = [method[@"detected"] boolValue] ? @"Detected" : @"Not Detected";
    if ([method[@"detected"] boolValue]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"]];
    } else {
        cell.accessoryView = nil;
    }
    return cell;
}

// Implement other delegate methods as needed

@end
