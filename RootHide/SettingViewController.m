#import "SettingViewController.h"
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
    NSString *rulesFilePath = jbroot(@"/var/mobile/Library/RootHide/varCleanRules-custom.plist");
    NSCharacterSet *CharacterSet = [NSCharacterSet URLQueryAllowedCharacterSet];
    NSString *encodedURLString = [rulesFilePath stringByAddingPercentEncodingWithAllowedCharacters:CharacterSet];
    NSURL *filzaURL = [NSURL URLWithString:[@"filza://view" stringByAppendingString:encodedURLString]];
    
    self.menuData = @[
        @{
            @"groupTitle": Localized(@"General"),
            @"items": @[
                @{
                    @"textLabel": Localized(@"Whitelist Mode"),
                    @"detailTextLabel": Localized(@"auto blacklist newly installed apps"),
                    @"type": @"switch",
                    @"switchKey": @"whitelistMode",
                    @"disabled": @YES
                },
            ]
        },
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
    
    NSDictionary* settings = [AppDelegate getDefaultsForKey:@"settings"];
    if([item[@"type"] isEqualToString:@"switch"]) {
        UISwitch *theSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        if(item[@"status"])
            [theSwitch setOn:[item[@"status"] boolValue] ];
        else
            [theSwitch setOn:[[settings objectForKey:item[@"switchKey"]] boolValue] ];
        [theSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        if(item[@"disabled"])[theSwitch setEnabled:![item[@"disabled"] boolValue]];
        cell.accessoryView = theSwitch;
    }
    
    if([item[@"type"] isEqualToString:@"url"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//
    
    NSDictionary *groupData = self.menuData[indexPath.section];
    NSArray *items = groupData[@"items"];
    
    NSDictionary *item = items[indexPath.row];
    
    if([item[@"type"] isEqualToString:@"url"]) {
        NSURL* url = [NSURL URLWithString:item[@"url"]];
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
        if(canOpen) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"URL") message:item[@"url"] preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Got It") style:UIAlertActionStyleDefault handler:nil]];
            [self.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }
}
@end
