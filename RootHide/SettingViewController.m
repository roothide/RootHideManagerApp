#import "SettingViewController.h"
#import "jbroot.h"
#include "AppDelegate.h"
#include <sys/mount.h>
#include <spawn.h>
#import "detection.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreLocation/CoreLocation.h>

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
            @{ @"description": @"361 Multi Account Manager", @"scheme": @"com.paypal.ppclient.touch.v1://, com.paypal.ppclient.touch.v2://, org-appextension-feature-password-management://, RST://, 361://, cn.tinyapps.rst.payments://" },
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
            @{ @"description": @"Fake GPS Pro", @"scheme": @"xgpspro://, cn.tinyapps.xgpspro.payments://, com.paypal.ppclient.touch.v1://, com.paypal.ppclient.touch.v2://, org-appextension-feature-password-management://" },
            @{ @"description": @"Fake Picture", @"scheme": @"giantalipayfpp://, net.joebruce.FakePicture.braintree://, joebruce.FakePicture://" },
            @{ @"description": @"Filza", @"scheme": @"filza://, db-lmvo0l08204d0a0://, boxsdk-810yk37nbrpwaee5907xc4iz8c1ay3my://, com.googleusercontent.apps.802910049260-0hf6uv6nsj21itl94v66tphcqnfl172r://" },
            @{ @"description": @"FilzaPlus", @"scheme": @"filzaplus://" },
            @{ @"description": @"Flex", @"scheme": @"twitterkit-kfv4SvicaOSX8UxbItMCaVcNM://, com.flex://, flex://" },
            @{ @"description": @"Flex3", @"scheme": @"flex3://" },
            @{ @"description": @"Frida", @"scheme": @"frida://" },
            @{ @"description": @"GDB Debugger", @"scheme": @"gdb://" },
            @{ @"description": @"GPS Manager", @"scheme": @"giantalipaygmm://, jb.accs.GpsManager.payments://, acc.GpsManager://" },
            @{ @"description": @"GPS Master", @"scheme": @"alipaygiantgn://, net.joebruce.GpsMaster.payments://, joebruce.GpsMaster://" },
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
            @{ @"description": @"NetFence", @"scheme": @"netfenceapp://" },
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
    
    // Proxy check
    BOOL proxyDetected = isProxyEnabled(NO); // Set to YES to include VPN check
    BOOL vpnDetected = isProxyEnabled(YES);

    NSMutableArray *proxyCheckItems = [NSMutableArray array];
    [proxyCheckItems addObject:@{
        @"textLabel": @"Proxy Detection",
        @"detailTextLabel": proxyDetected ? @"Proxy Detected" : @"No Proxy",
        @"type": @"info",
        @"isInstalled": @(proxyDetected)  // Use BOOL as NSNumber for checkmark handling
    }];

    [proxyCheckItems addObject:@{
        @"textLabel": @"VPN Detection",
        @"detailTextLabel": vpnDetected ? @"VPN Detected" : @"No VPN",
        @"type": @"info",
        @"isInstalled": @(vpnDetected)  // Use BOOL as NSNumber for checkmark handling
    }];

    // Location Spoofing Check (iOS 15+)
    BOOL locationSpoofingDetected = NO;
    BOOL locationProducedByAccessory = NO;
    if (@available(iOS 15.0, *)) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        [locationManager requestWhenInUseAuthorization];
        [locationManager startUpdatingLocation];
        CLLocation *location = locationManager.location;
        
        if (location.sourceInformation) {
                if (location.sourceInformation.isSimulatedBySoftware) {
                    locationSpoofingDetected = YES;
                    NSLog(@"Location spoofing detected via software!");
                }
                
                if (location.sourceInformation.isProducedByAccessory) {
                    locationProducedByAccessory = YES;
                    NSLog(@"Location produced by accessory!");
                }
            }
    }
    
    NSMutableArray *locationSpoofingItems = [NSMutableArray array];
        [locationSpoofingItems addObject:@{
            @"textLabel": @"Location Spoofing",
            @"detailTextLabel": locationSpoofingDetected ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(locationSpoofingDetected)
        }];
    
    [locationSpoofingItems addObject:@{
        @"textLabel": @"Location Produced by Accessory",
        @"detailTextLabel": locationProducedByAccessory ? @"Detected" : @"Not Detected",
        @"type": @"info",
        @"isInstalled": @(locationProducedByAccessory)
    }];
    
    // Jailbreak Checks
    // Get the detected jailbreak root path using jbroot("/")
    NSString *jailbreakRootPath = jbroot(@"/");
    
    NSMutableArray *jailbreakCheckItems = [NSMutableArray array];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Jailbreak Path",
            @"detailTextLabel": jailbreakRootPath,
            @"type": @"url",
            @"isInstalled": @YES,
        }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Rootless JB",
            @"detailTextLabel": detect_rootlessJB() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_rootlessJB()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Kernel Bypass",
            @"detailTextLabel": detect_kernBypass() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_kernBypass()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Chroot",
            @"detailTextLabel": detect_chroot() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_chroot()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Mount FS",
            @"detailTextLabel": detect_mount_fs() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_mount_fs()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Bootstraps",
            @"detailTextLabel": detect_bootstraps() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_bootstraps()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"TrollStored Filza",
            @"detailTextLabel": detect_trollStoredFilza() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_trollStoredFilza()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Jailbreakd",
            @"detailTextLabel": detect_jailbreakd() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jailbreakd()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Proc Flags",
            @"detailTextLabel": detect_proc_flags() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_proc_flags()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"JB Payload",
            @"detailTextLabel": detect_jb_payload() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jb_payload()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Exception Port",
            @"detailTextLabel": detect_exception_port() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_exception_port()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"JB Preboot",
            @"detailTextLabel": detect_jb_preboot() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jb_preboot()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Jailbroken Apps",
            @"detailTextLabel": detect_jailbroken_apps() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jailbroken_apps()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Removed /var/jb",
            @"detailTextLabel": detect_removed_varjb() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_removed_varjb()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Fugu15 Max",
            @"detailTextLabel": detect_fugu15Max() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_fugu15Max()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"URL Schemes",
            @"detailTextLabel": detect_url_schemes() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_url_schemes()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"JB App Plugins",
            @"detailTextLabel": detect_jbapp_plugins() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jbapp_plugins()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"JB Sigs",
            @"detailTextLabel": detect_jailbreak_sigs() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jailbreak_sigs()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"JB Port",
            @"detailTextLabel": detect_jailbreak_port() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_jailbreak_port()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Launchd JBserver",
            @"detailTextLabel": detect_launchd_jbserver() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_launchd_jbserver()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"TrollStore",
            @"detailTextLabel": detect_trollstore_app() ? @"Detected" : @"Not Detected",
            @"type": @"info",
            @"isInstalled": @(detect_trollstore_app()) }];
    [jailbreakCheckItems addObject:@{
            @"textLabel": @"Passcode Status",
            @"detailTextLabel": detect_passcode_status() ? @"Passcode Set" : @"No Passcode",
            @"type": @"info",
            @"isInstalled": @(detect_passcode_status()) }];
    
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
            @"groupTitle": @"Network Security",
            @"items": proxyCheckItems
        },
        @{
            @"groupTitle": Localized(@"Location Security"),
            @"items": locationSpoofingItems,
        },
        @{
                    @"groupTitle": @"Jailbreak Checks",
                    @"items": jailbreakCheckItems
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
    
    if ([item[@"type"] isEqualToString:@"url"] || [item[@"type"] isEqualToString:@"info"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // Show checkmark for installed apps or detected proxies/VPNs
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

BOOL isProxyEnabled(BOOL considerVPN) {
    CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();
    if (!proxySettings) {
        return NO;
    }

    NSDictionary *settings = (__bridge_transfer NSDictionary *)proxySettings;
    
    if (considerVPN) {
        NSDictionary *scopedDict = settings[@"__SCOPED__"];
        if (scopedDict) {
            NSArray *vpnInterfaces = @[@"tap", @"tun", @"ppp", @"ipsec", @"utun"];
            for (NSString *interface in scopedDict.allKeys) {
                for (NSString *vpnPrefix in vpnInterfaces) {
                    if ([interface containsString:vpnPrefix]) {
                        NSLog(@"VPN detected: %@", interface);
                        return YES;
                    }
                }
            }
        }
    }

    return (settings[@"HTTPProxy"] != nil || settings[@"HTTPSProxy"] != nil);
}

@end
