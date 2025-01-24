#import "SettingViewController.h"
#import "jbroot.h"
#include "AppDelegate.h"
#include <sys/mount.h>
#include <spawn.h>

@interface SettingViewController ()

@property (nonatomic, retain) NSMutableArray *menuData;

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
        @{ @"scheme": @"activator://", @"description": @"Activator" }
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
    
    // Update menuData
    self.menuData = @[
        @{
            @"groupTitle": Localized(@"Advanced"),
            @"items": @[
                @{
                    @"textLabel": Localized(@"Edit varClean Rules"),
                    @"detailTextLabel": Localized(@"view the rules file in Filza"),
                    @"type": @"url",
                    @"url": filzaURL.absoluteString
                },
            ]
        },
        @{
            @"groupTitle": Localized(@"Installed Apps"),
            @"items": urlSchemeItems
        }
    ].mutableCopy;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setTitle:Localized(@"Setting")];
    
    [self reloadMenu];
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
    
    if ([item[@"type"] isEqualToString:@"url"]) {
        NSURL *url = [NSURL URLWithString:item[@"url"]];
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
        if (canOpen) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"App Not Installed")
                                                                           message:[NSString stringWithFormat:Localized(@"%@ is not installed."), item[@"textLabel"]]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Got It") style:UIAlertActionStyleDefault handler:nil]];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }
}
@end
