#import "SettingTableViewController.h"
#include "AppDelegate.h"
#include <sys/mount.h>
#include <spawn.h>

@interface SettingTableViewController ()

@property (nonatomic, retain) NSMutableArray *menuData;

@end

@implementation SettingTableViewController

+ (instancetype)sharedInstance {
    static SettingTableViewController* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)processXinaA15Files:(BOOL)hide withBootpath:(NSString*)bootpath
{
    char* args[] = {"/sbin/mount", "-u", "-w", "/private/preboot", NULL};
    
    pid_t pid=0;
    assert(posix_spawn(&pid, args[0], NULL, NULL, args, NULL) == 0);
    
    int status=0;
    waitpid(pid, &status, 0);
    
    NSArray* bootfiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:bootpath error:nil];
    
    NSString* msg = nil;
    
    if(hide) {
        for(NSString* name in bootfiles)
        {
            if([name isEqualToString:@"procursus"])
            {
                NSError* err=nil;
                if([NSFileManager.defaultManager moveItemAtPath:[bootpath stringByAppendingPathComponent:name] toPath:[bootpath stringByAppendingFormat:@"/xinaA15-%X", arc4random()] error:&err]) {
                    msg = Localized(@"xinaA15 files has been hidden, please reboot your device.\n\nyou can restore it later if you want to use xinaA15 again.");
                } else {
                    msg = [NSString stringWithFormat:Localized(@"hide failed: %@"), err];
                }
            }
        }
        
    } else {
        NSString* xinafilename=nil;
        for(NSString* name in bootfiles)
        {
            if([name hasPrefix:@"xinaA15-"])
            {
                if(xinafilename) {
                    xinafilename = nil;
                    char realbootpath[PATH_MAX]={0};
                    realpath(bootpath.UTF8String, realbootpath);
                    msg = [NSString stringWithFormat:Localized(@"there are multiple xinaA15 jailbreak files, you can restore it manually:\n\n%s/"), realbootpath];
                    break;
                } else {
                    xinafilename = name;
                }
            }
        }
        
        if(xinafilename) {
            NSError* err=nil;
            if([NSFileManager.defaultManager moveItemAtPath:[bootpath stringByAppendingPathComponent:xinafilename] toPath:[bootpath stringByAppendingPathComponent:@"procursus"] error:&err]) {
                msg = Localized(@"xinaA15 files has been restored, you can reboot your device to switch to xinaA15.");
            } else {
                msg = [NSString stringWithFormat:Localized(@"restore failed: %@"), err];
            }
        } else if(!msg) {
            msg = Localized(@"restore failed: xinaA15 file not found!");
        }
    }
    
    if(msg) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"Process xinaA15 Files") message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:Localized(@"Got It") style:UIAlertActionStyleDefault handler:nil]];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)reloadMenu {
    NSString *rulesFilePath = jbroot(@"/var/mobile/Library/RootHide/VarCleanRules-custom.plist");
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
                    @"textLabel": Localized(@"Edit VarClean Rules"),
                    @"detailTextLabel": Localized(@"open the rules file in Filza"),
                    @"type": @"url",
                    @"url": filzaURL.absoluteString
                },
            ]
        },
    ].mutableCopy;
    
    BOOL xinaA15installed = NO;
    BOOL xinaA15fileshide = NO;
    
    struct statfs s={0};
    statfs("/usr/standalone/firmware", &s);
    NSString* bootpath = [NSString stringWithFormat:@"%s/../../../", s.f_mntfromname];
    NSArray* bootfiles = [NSFileManager.defaultManager contentsOfDirectoryAtPath:bootpath error:nil];
    for(NSString* name in bootfiles)
    {
        if([name isEqualToString:@"procursus"]) {
            xinaA15installed = YES;
            xinaA15fileshide = NO;
        } else if([name hasPrefix:@"xinaA15-"]) {
            if(!xinaA15installed) xinaA15fileshide=YES;
        }
    }
    
    if(xinaA15installed || xinaA15fileshide) {
        [self.menuData addObjectsFromArray:@[
            @{
                @"groupTitle": Localized(@"Misc"),
                @"items": @[
                    @{
                        @"textLabel": Localized(@"Hide xinaA15 Files"),
                        @"detailTextLabel": Localized(@"hide xinaA15 files without uninstall it"),
                        @"type": @"switch",
                        @"status": @(xinaA15fileshide),
                        @"action": ^{
                            [self processXinaA15Files:xinaA15installed withBootpath:bootpath];
                            [self reloadMenu];
                            [self.tableView reloadData];
                        }
                    },
                ]
            },
        ]];
    }
    
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
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:item[@"url"]] options:@{} completionHandler:nil];
    }
}
@end
