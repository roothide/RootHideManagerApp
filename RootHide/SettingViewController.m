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
        @{ @"description": @"Activator", @"scheme": @"activator://" },
            @{ @"description": @"Altstore", @"scheme": @"altstore://, altstore-com.rileytestut.Altstore://" },
            @{ @"description": @"AnyGo", @"scheme": @"anygofree://" },
            @{ @"description": @"AppCake", @"scheme": @"appcake://" },
            @{ @"description": @"AppDB", @"scheme": @"appdb-ios://" },
            @{ @"description": @"AppsDump2", @"scheme": @"appsdump://, appsdumpopenpath://" },
            @{ @"description": @"Apps Manager", @"scheme": @"adm://" },
            @{ @"description": @"APT (Advanced Package Tool)", @"scheme": @"apt://" },
            @{ @"description": @"Cercube for YouTube", @"scheme": @"cercube://" },
            @{ @"description": @"Checkra1n", @"scheme": @"checkra1n://" },
            @{ @"description": @"Chimera", @"scheme": @"chimera://" },
            @{ @"description": @"Clone App", @"scheme": @"cloneapp://" },
            @{ @"description": @"Cydia", @"scheme": @"cydia://" },
            @{ @"description": @"CyberGhost", @"scheme": @"cyberghost://" },
            @{ @"description": @"Debugger", @"scheme": @"debug://" },
            @{ @"description": @"DPKG (Debian Package)", @"scheme": @"dpkg://" },
            @{ @"description": @"Dopamine", @"scheme": @"dopamine://" },
            @{ @"description": @"Dumpy2", @"scheme": @"dumpy2://, dumpy2openpath://" },
            @{ @"description": @"Electra", @"scheme": @"electra://" },
            @{ @"description": @"ElleKit", @"scheme": @"ellekit://" },
            @{ @"description": @"ESign", @"scheme": @"esign://" },
            @{ @"description": @"ExpressVPN", @"scheme": @"expresvpn://" },
            @{ @"description": @"Filza", @"scheme": @"filza://, db-lmvo0l08204d0a0://, boxsdk-810yk37nbrpwaee5907xc4iz8c1ay3my://, com.googleusercontent.apps.802910049260-0hf6uv6nsj21itl94v66tphcqnfl172r://" },
            @{ @"description": @"FilzaPlus", @"scheme": @"filzaplus://" },
            @{ @"description": @"Flex", @"scheme": @"twitterkit-kfv4SvicaOSX8UxbItMCaVcNM://, com.flex://, flex://" },
            @{ @"description": @"Flex3", @"scheme": @"flex3://" },
            @{ @"description": @"Frida", @"scheme": @"frida://" },
            @{ @"description": @"GDB Debugger", @"scheme": @"gdb://" },
            @{ @"description": @"iCleaner", @"scheme": @"icleaner://" },
            @{ @"description": @"iFile", @"scheme": @"ifile://" },
            @{ @"description": @"Ignition", @"scheme": @"ignition://" },
            @{ @"description": @"iGameGod", @"scheme": @"gamegodopen://" },
            @{ @"description": @"Icy", @"scheme": @"icy://" },
            @{ @"description": @"iOSGods", @"scheme": @"iosgods://" },
            @{ @"description": @"Jailbreak Bypass", @"scheme": @"bypass://" },
            @{ @"description": @"Jailbreak Info", @"scheme": @"jailbreak://" },
            @{ @"description": @"LibHooker", @"scheme": @"libhooker://" },
            @{ @"description": @"LLDB Debugger", @"scheme": @"lldb://" },
            @{ @"description": @"LocSim", @"scheme": @"LocationSimulation://, locationfakelocation://" },
            @{ @"description": @"Midnight", @"scheme": @"midnight://" },
            @{ @"description": @"MTerminal", @"scheme": @"mterminal://" },
            @{ @"description": @"MultiTweak", @"scheme": @"multitweak://" },
            @{ @"description": @"NewTerm", @"scheme": @"newterm://" },
            @{ @"description": @"NordVPN", @"scheme": @"nordvpn://, fb104904993305938://" },
            @{ @"description": @"OpenSSH", @"scheme": @"openssh://" },
            @{ @"description": @"OpenVPN", @"scheme": @"openvpn://, openvpn-connect://" },
            @{ @"description": @"Palera1n", @"scheme": @"palera1n://" },
            @{ @"description": @"Potatso", @"scheme": @"potatsolite://, potatso://, ss://, ssr://" },
            @{ @"description": @"Prequel", @"scheme": @"prequel://, prefs://, com.googleusercontent.apps.1010491207191-poa1j88pjgsvu0r5hdi9pgae41mu0apu://" },
//rp            @{ @"description": @"RD Client", @"scheme": @"x-msauth-rdcios://, rdc://, rdc-intuneman://, rdp://, rdp-intuneman://" },
            @{ @"description": @"ReProvision", @"scheme": @"reProvision://" },
            @{ @"description": @"Rex", @"scheme": @"rex://" },
            @{ @"description": @"Santander", @"scheme": @"santander://" },
            @{ @"description": @"Saily", @"scheme": @"apt-repo://" },
            @{ @"description": @"Scarlet", @"scheme": @"Scarlet://" },
            @{ @"description": @"Shadow Jailbreak Detection Bypass", @"scheme": @"shadow://" },
            @{ @"description": @"Shadowrocket", @"scheme": @"shadowrocket://, rocket://, ss://, sr://, shadowsocks://, ssr://, vmess://, socks://, ssocks://, sub://, trojan://, trojan-go://, snell://, vless://, relay://, hysteria://, hysteria2://, clash://, tuic://, wireguard://, wg://, ssh://" },
            @{ @"description": @"SideStore", @"scheme": @"sidestore://, sidestore-com.SideStore.SideStore://" },
            @{ @"description": @"Signulous", @"scheme": @"signulous://" },
            @{ @"description": @"SMS Activate", @"scheme": @"sms-activate.org://, com.googleusercontent.apps.417467183712-769e5or7mrke6jpugf4apasuinupttu5://" },
            @{ @"description": @"SMS Virtual", @"scheme": @"com.googleusercontent.apps.250829852194-k3slpecs1tnk3ssqe4mirjjs2enhpghf://" },
            @{ @"description": @"SSH", @"scheme": @"ssh://" },
            @{ @"description": @"Substrate", @"scheme": @"substrate://" },
            @{ @"description": @"Substrate Preferences", @"scheme": @"prefs:root=CydiaSubstrate" },
            @{ @"description": @"Surge", @"scheme": @"surge://, surge3://, surge5://, db-dec03t2bmy30i0a://" },
            @{ @"description": @"TrollApps", @"scheme": @"trollapps://" },
            @{ @"description": @"TrollStore", @"scheme": @"trollstore://" },
            @{ @"description": @"TweakBox", @"scheme": @"tweakbox://" },
            @{ @"description": @"TweakSettings", @"scheme": @"tweaks://" },
            @{ @"description": @"V2Box", @"scheme": @"v2box://, vless://, vmess://, trojan://, ss://, ssh://, socks://" },
//            @{ @"description": @"VNC", @"scheme": @"vnc://, msauth.com.realvnc.VNCViewer://, com.realvnc.vncviewer.sso://" },
            @{ @"description": @"VPN Proxy Master", @"scheme": @"vpnmaster://, fb982752668449751://, com.googleusercontent.apps.410654193708-bvi393kara802mk8b1rp76ih8un6t0sd://, purplevpn://" },
            @{ @"description": @"Xina", @"scheme": @"xina://" },
            @{ @"description": @"YouTube Downloader", @"scheme": @"youtubedl://" },
            @{ @"description": @"Zebra", @"scheme": @"zbra://" }
    ];
    
    // Create menu items for installed URL schemes
    NSMutableArray *urlSchemeItems = [NSMutableArray array];
    for (NSDictionary *urlScheme in urlSchemes) {
        NSArray *schemes = [urlScheme[@"scheme"] componentsSeparatedByString:@", "];
        for (NSString *scheme in schemes) {
            NSURL *url = [NSURL URLWithString:scheme];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [urlSchemeItems addObject:@{
                    @"textLabel": urlScheme[@"description"],
                    @"detailTextLabel": scheme,
                    @"type": @"url",
                    @"url": scheme,
                    @"isInstalled": @YES // Mark as installed
                }];
            }
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
