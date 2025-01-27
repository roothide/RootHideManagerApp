#import "SettingViewController.h"
#import "jbroot.h"
#include "AppDelegate.h"
#include <sys/mount.h>
#include <spawn.h>
#import "detection.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface SettingViewController ()

@property (nonatomic, retain) NSMutableArray *menuData;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UIButton *runChecksButton;
@property (nonatomic, strong) NSMutableString *detectionLogs;

@end

@implementation SettingViewController

+ (instancetype)sharedInstance {
    static SettingViewController* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)reloadMenu {
    // Use jbroot to resolve the path
    NSString *rulesFilePath = jbroot(@"/var/mobile/Library/varClean/varCleanRules-custom.plist");
    
    NSCharacterSet *CharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodedURLString = [rulesFilePath stringByAddingPercentEncodingWithAllowedCharacters:CharacterSet];
    NSURL *filzaURL = [NSURL URLWithString:[@"filza://view" stringByAppendingString:encodedURLString]];
    
    // Define URL schemes and their descriptions
    NSArray *urlSchemes = @[
        @{ @"scheme": @"cydia://", @"description": @"Cydia" },
        @{ @"scheme": @"undecimus://", @"description": @"Unc0ver" },
        @{ @"scheme": @"sileo://", @"description": @"Sileo" },
        @{ @"scheme": @"zbra://", @"description": @"Zebra" },
        @{ @"scheme": @"apt-repo://", @"description": @"Saily" },
        @{ @"scheme": @"postbox://", @"description": @"Postbox" },
        @{ @"scheme": @"xina://", @"description": @"Xina" },
        @{ @"scheme": @"icleaner://", @"description": @"iCleaner" },
        @{ @"scheme": @"ssh://", @"description": @"SSH" },
        @{ @"scheme": @"santander://", @"description": @"Santander" },
        @{ @"scheme": @"filza://", @"description": @"Filza" },
        @{ @"scheme": @"db-lmvo0l08204d0a0://", @"description": @"Filza (Dropbox)" },
        @{ @"scheme": @"boxsdk-810yk37nbrpwaee5907xc4iz8c1ay3my://", @"description": @"Filza (Dropbox SDK)" },
        @{ @"scheme": @"com.googleusercontent.apps.802910049260-0hf6uv6nsj21itl94v66tphcqnfl172r://", @"description": @"Filza (Google Drive)" },
        @{ @"scheme": @"activator://", @"description": @"Activator" },
        @{ @"scheme": @"trollapps://", @"description": @"TrollApps" },
        @{ @"scheme": @"trollstore://", @"description": @"TrollStore" },
        @{ @"scheme": @"LocationSimulation://", @"description": @"LocSim" },
        @{ @"scheme": @"Scarlet://", @"description": @"Scarlet" },
        @{ @"scheme": @"dumpy2://", @"description": @"Dumpy2" },
        @{ @"scheme": @"dumpy2openpath://", @"description": @"Dumpy2" },
        @{ @"scheme": @"appsdump://", @"description": @"AppsDump2" },
        @{ @"scheme": @"appsdumpopenpath://", @"description": @"AppsDump2" }
    ];
    
    // Create menu items for installed URL schemes
    NSMutableArray *urlSchemeItems = [NSMutableArray array];
    for (NSDictionary *urlScheme in urlSchemes) {
        NSURL *url = [NSURL URLWithString:urlScheme[@"scheme"]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [urlSchemeItems addObject:@{
                @"textLabel": urlScheme[@"description"],
                @"detailTextLabel": urlScheme[@"scheme"],
                @"type": @"url",
                @"url": urlScheme[@"scheme"],
                @"isInstalled": @YES // Mark as installed
            }];
        }
    }
    
    // Detect TrollStore and add it if detected
    if (detect_trollstore_app()) {
        [urlSchemeItems addObject:@{
            @"textLabel": @"TrollStore",
            @"detailTextLabel": @"apple-magnifier://",
            @"type": @"url",
            @"url": @"apple-magnifier://",
            @"isInstalled": @YES // Mark as installed
        }];
    }
    
    // Get the detected jailbreak root path using jbroot("/")
    NSString *jailbreakRootPath = jbroot(@"/");
    
    // Create menu items for the jailbreak path section
    NSMutableArray *jailbreakPathItems = [NSMutableArray array];
    [jailbreakPathItems addObject:@{
        @"textLabel": @"Jailbreak Path",
        @"detailTextLabel": jailbreakRootPath,
        @"type": @"url",
        @"url": jailbreakRootPath
    }];
    
    // Update menuData
    self.menuData = @[
        @{
            @"groupTitle": Localized(@"Advanced"),
            @"items": @[
                @{
                    @"textLabel": Localized(@"Edit varClean Rules"),
                    @"detailTextLabel": Localized(@"view the rules file in Filza"),
                    @"type": @"url", // URL scheme
                    @"url": filzaURL.absoluteString
                },
            ]
        },
        @{
            @"groupTitle": Localized(@"Installed Apps"),
            @"items": urlSchemeItems
        },
        @{
            @"groupTitle": Localized(@"Jailbreak Path"),
            @"items": @[
                @{
                    @"textLabel": @"Jailbreak Path",
                    @"detailTextLabel": jailbreakRootPath,
                    @"type": @"file", // File path
                    @"url": [@"filza://" stringByAppendingString:jailbreakRootPath]
                }
            ]
        }
    ].mutableCopy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setTitle:Localized(@"Setting")];
    
    [self setupUI];
    [self reloadMenu];
}

- (void)setupUI {
    // Create the log text view
    self.logTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 250, self.view.bounds.size.width, 200)];
    self.logTextView.backgroundColor = [UIColor systemGray6Color];
    self.logTextView.editable = NO;
    self.logTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.logTextView.layer.borderWidth = 1.0;
    self.logTextView.text = @"Detected URL Schemes:\n";
    [self.view addSubview:self.logTextView];

    // Create the button
    self.runChecksButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.runChecksButton.frame = CGRectMake(20, CGRectGetMinY(self.logTextView.frame) - 50, self.view.bounds.size.width - 40, 40);
    [self.runChecksButton setTitle:@"Detect Installed URL Schemes" forState:UIControlStateNormal];
    [self.runChecksButton addTarget:self action:@selector(detectInstalledURLSchemes) forControlEvents:UIControlEventTouchUpInside];
    self.runChecksButton.backgroundColor = [UIColor systemBlueColor];
    [self.runChecksButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.runChecksButton.layer.cornerRadius = 8.0;
    [self.view addSubview:self.runChecksButton];
}

// Method to dynamically detect all installed URL schemes
- (void)detectInstalledURLSchemes {
    self.detectionLogs = [[NSMutableString alloc] init];
    
    Class LSApplicationWorkspace_class = objc_getClass("LSApplicationWorkspace");
    SEL defaultWorkspace_sel = sel_registerName("defaultWorkspace");
    SEL applications_sel = sel_registerName("allApplications");

    id workspace = ((id (*)(id, SEL))objc_msgSend)(LSApplicationWorkspace_class, defaultWorkspace_sel);
    NSArray *allApps = ((id (*)(id, SEL))objc_msgSend)(workspace, applications_sel);

    for (id app in allApps) {
        SEL appID_sel = sel_registerName("applicationIdentifier");
        NSString *bundleID = ((id (*)(id, SEL))objc_msgSend)(app, appID_sel);

        SEL appURLHandlers_sel = sel_registerName("urlHandlers");
        NSArray *urlHandlers = ((id (*)(id, SEL))objc_msgSend)(app, appURLHandlers_sel);

        for (NSDictionary *urlHandler in urlHandlers) {
            NSArray *schemes = urlHandler[@"LSHandlerURLScheme"];
            for (NSString *scheme in schemes) {
                [self.detectionLogs appendFormat:@"%@ (Bundle: %@)\n", scheme, bundleID];
            }
        }
    }

    if (self.detectionLogs.length == 0) {
        [self.detectionLogs appendString:@"No URL Schemes found."];
    }

    // Update the log text view with results
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = self.detectionLogs;
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.menuData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *groupData = self.menuData[section];
    NSArray *items = groupData[@"items"];
    return items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *groupData = self.menuData[section];
    return groupData[@"groupTitle"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    NSDictionary *groupData = self.menuData[indexPath.section];
    NSArray *items = groupData[@"items"];
    
    NSDictionary *item = items[indexPath.row];
    cell.textLabel.text = item[@"textLabel"];
    cell.detailTextLabel.text = item[@"detailTextLabel"];
    
    if ([item[@"type"] isEqualToString:@"url"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Show checkmark for installed apps
        if ([item[@"isInstalled"] boolValue]) {
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"]];
        } else {
            cell.accessoryView = nil;
        }
    }
    
    return cell;
}

- (void)switchChanged:(id)sender {
    UISwitch *switchInCell = (UISwitch *)sender;
    CGPoint pos = [switchInCell convertPoint:switchInCell.bounds.origin toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pos];
    
    NSDictionary *groupData = self.menuData[indexPath.section];
    NSArray *items = groupData[@"items"];
    
    NSDictionary *item = items[indexPath.row];
    
    if(item[@"switchKey"]) {
        NSMutableDictionary* settings = [AppDelegate getDefaultsForKey:@"settings"];
        if(!settings) settings = [[NSMutableDictionary alloc] init];
        [settings setObject:@(switchInCell.on) forKey:item[@"switchKey"]];
        [AppDelegate setDefaults:settings forKey:@"settings"];
    }
    else if(item[@"action"]) {
        ((void(^)(void))item[@"action"])();
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *groupData = self.menuData[indexPath.section];
    NSArray *items = groupData[@"items"];

    NSDictionary *item = items[indexPath.row];

    if ([item[@"type"] isEqualToString:@"url"] || [item[@"type"] isEqualToString:@"file"]) {
        NSURL *url = [NSURL URLWithString:item[@"url"]];
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];

        if (canOpen) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            NSString *appName = [item[@"type"] isEqualToString:@"file"] ? @"Filza" : item[@"textLabel"];

            UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"App Not Installed")
                                                                           message:[NSString stringWithFormat:Localized(@"%@ is not installed. Do you want to use your own URL scheme?"), appName]
                                                                    preferredStyle:UIAlertControllerStyleAlert];

            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = Localized(@"Enter your URL scheme (e.g. santander)");
            }];

            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Cancel") style:UIAlertActionStyleCancel handler:nil]];

            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *textField = alert.textFields.firstObject;
                NSString *customScheme = textField.text;
                if (customScheme.length > 0) {
                    NSString *customURLString = [NSString stringWithFormat:@"%@://%@", customScheme, item[@"url"]];
                    NSURL *customURL = [NSURL URLWithString:customURLString];
                    
                    if ([[UIApplication sharedApplication] canOpenURL:customURL]) {
                        [[UIApplication sharedApplication] openURL:customURL options:@{} completionHandler:nil];
                    } else {
                        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:Localized(@"Error")
                                                                                            message:Localized(@"Invalid URL scheme or app not installed.")
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                        [errorAlert addAction:[UIAlertAction actionWithTitle:Localized(@"OK") style:UIAlertActionStyleDefault handler:nil]];
                        [self.navigationController presentViewController:errorAlert animated:YES completion:nil];
                    }
                }
            }]];

            [self.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }
}

@end
