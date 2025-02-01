#import "detection.h"
#import <stdio.h>
#import <stdlib.h>
#import <limits.h>
#import <fcntl.h>
#import <assert.h>
#import <mach/mach.h>
#import <sys/stat.h>
#import <sys/mount.h>
#import <unistd.h>
#import <dirent.h>
#import <dlfcn.h>
#import <Security/Security.h>
#import <LocalAuthentication/LocalAuthentication.h>
#import "headers/xpc/xpc.h"
#import "headers/xpc_private.h"
#import "jbroot.h"

#pragma mark - Detection Functions

BOOL detect_rootlessJB(void)
{
    BOOL detected = NO;
    
    if (access("/var/jb", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/private/preboot/jb", F_OK) == 0) {
        detected = YES;
    }
    
    char *xinafiles[] = {
        "/var/containers/Bundle/dylib",
        "/var/containers/Bundle/xina",
        "/var/mobile/Library/Preferences/com.xina.blacklist.plist",
    };
    
    for (int i = 0; i < sizeof(xinafiles) / sizeof(xinafiles[0]); i++) {
        if (access(xinafiles[i], F_OK) == 0) {
            detected = YES;
        }
    }
    
    char *varfiles[] = {
        "apt", "bin", "bzip2", "cache", "dpkg", "etc", "gzip",
        "lib", "Lib", "libexec", "Library", "LIY", "Liy", "newuser",
        "profile", "sbin", "sh", "share", "ssh", "sudo_logsrvd.conf",
        "suid_profile", "sy", "usr", "zlogin", "zlogout", "zprofile",
        "zshenv", "zshrc", "master.passwd"
    };
    
    for (int i = 0; i < sizeof(varfiles) / sizeof(varfiles[0]); i++) {
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "/var/%s", varfiles[i]);
        if (access(path, F_OK) == 0) {
            detected = YES;
        }
    }
    return detected;
}

BOOL detect_kernBypass(void)
{
    if (access("/private/var/MobileSoftwareUpdate/mnt1/dev/null", F_OK) == 0) {
        return YES;
    }
    return NO;
}

BOOL detect_chroot(void)
{
    struct statfs s = {0};
    statfs("/", &s);
    if (strcmp("/", s.f_mntonname) != 0) {
        return YES;
    }
    return NO;
}

BOOL detect_mount_fs(void)
{
    BOOL detected = NO;
    struct statfs *ss = NULL;
    int n = getmntinfo(&ss, 0);
    
    for (int i = 0; i < n; i++) {
        if (strcmp("/", ss[i].f_mntonname) != 0 &&
            strcmp(ss[i].f_fstypename, "apfs") == 0 &&
            strstr(ss[i].f_mntfromname, "@") != NULL)
        {
            detected = YES;
        }
        
        for (int j = 0; j < i; j++) {
            if (strcmp(ss[i].f_mntfromname, ss[j].f_mntfromname) == 0) {
                detected = YES;
            }
        }
    }
    return detected;
}

BOOL detect_bootstraps(void)
{
    BOOL detected = NO;
    
    if (access("/var/log/apt", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/log/dpkg", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/lib/dpkg", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/lib", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/lib/apt", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/lib/cydia", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/lib/undecimus", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/mobile/Library/Sileo", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/mobile/Library/Application Support/xyz.willy.Zebra", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/mobile/.eksafemode", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/private/var/mobile/.ekenablelogging", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/private/var/mobile/log.txt", F_OK) == 0) {
        detected = YES;
    }
    
    return detected;
}

BOOL detect_trollStoredFilza(void)
{
    if (access("/var/lib/filza", F_OK) == 0) return YES;
    if (access("/var/mobile/Library/Filza", F_OK) == 0) return YES;
    if (access("/var/mobile/Library/Preferences/com.tigisoftware.Filza.plist", F_OK) == 0) return YES;
    return NO;
}

BOOL detect_jailbreakd(void) {
    return NO;
}
//BOOL detect_jailbreakd(void)
//{
//    if (connect_mach_service("cy:com.saurik.substrated") != MACH_PORT_NULL) return YES;
//    if (connect_mach_service("org.coolstar.jailbreakd") != MACH_PORT_NULL) return YES;
//    if (connect_mach_service("jailbreakd") != MACH_PORT_NULL) return YES;
//    return NO;
//}

BOOL detect_proc_flags(void)
{
    uint32_t flags = 0;
    csops(getpid(), 0, &flags, 0);
    if (flags & 0x00000004) return YES;
    if (flags & 0x04000000) return YES;
    if (flags & 0x00000008) return YES;
    if (!(flags & 0x00000300)) return YES;
    if (flags & 0x00004000) return YES;
    return NO;
}

BOOL detect_jb_payload(void)
{
    mach_port_t object_name;
    mach_vm_size_t region_size = 0;
    mach_vm_address_t region_base = (uint64_t)vm_region_64;
    
    vm_region_basic_info_data_64_t info = {0};
    mach_msg_type_number_t info_cnt = VM_REGION_BASIC_INFO_COUNT_64;
    
    vm_region_64(mach_task_self(),
                 (vm_address_t *)&region_base,
                 (vm_size_t *)&region_size,
                 VM_REGION_BASIC_INFO_64,
                 (vm_region_info_t)&info,
                 &info_cnt,
                 &object_name);
    
    if (info.protection != VM_PROT_READ) {
        return YES;
    }
    return NO;
}

BOOL detect_exception_port(void)
{
    BOOL detected = NO;
    exception_mask_t masks[EXC_TYPES_COUNT];
    mach_port_t ports[EXC_TYPES_COUNT];
    exception_behavior_t behaviors[EXC_TYPES_COUNT];
    thread_state_flavor_t flavors[EXC_TYPES_COUNT];
    mach_msg_type_number_t count = 0;
    
    mach_port_t task = mach_task_self();
    task_get_exception_ports(task, EXC_MASK_ALL, masks, &count, ports, behaviors, flavors);
    
    if (count != 1) {
        detected = YES;
    }
    
    for (int i = 0; i < count; i++) {
        if (ports[i] || behaviors[i] || flavors[i]) {
            detected = YES;
        }
    }
    
    return detected;
}

BOOL detect_jb_preboot(void)
{
    BOOL detected = NO;
    struct statfs s = {0};
    statfs("/", &s);
    
    const char *p = strstr(s.f_mntfromname, "@");
    if (!p) {
        // If there is no snapshot (i.e. “@” not found) we do not flag it here.
        return NO;
    }
    
    size_t prefixlen = sizeof("com.apple.os.update-") - 1;
    char boothash[255] = {0};
    strncpy(boothash, s.f_mntfromname + prefixlen, p - (s.f_mntfromname + prefixlen));
    
    char path[PATH_MAX];
    snprintf(path, sizeof(path), "/private/preboot/%s/procursus", s.f_mntfromname);
    if (access(path, F_OK) == 0) {
        detected = YES;
    }
    
    if (@available(iOS 16.0, *)) {
        // Do nothing for iOS 16 and above
    } else {
        statfs("/private/preboot", &s);
        if (!(s.f_flags & MNT_RDONLY)) {
            detected = YES;
        }
    }
    return detected;
}

BOOL detect_jailbroken_apps(void)
{
    BOOL detected = NO;
    char *appids[] = {
        "com.xina.jailbreak",
        "com.opa334.Dopamine",
        "com.tigisoftware.Filza",
        "org.coolstar.SileoStore",
        "ws.hbang.Terminal",
        "xyz.willy.Zebra",
        "shshd",
    };
    
    char *paths[][3] = {
        {"", "Library/Preferences", ".plist"},
        {"", "Library/Application Support/Containers", ""},
        {"", "Library/SplashBoard/Snapshots", ""},
        {"", "Library/Caches", ""},
        {"", "Library/Saved Application State", ".savedState"},
        {"", "Library/WebKit", ""},
        {"", "Library/Cookies", ".binarycookies"},
        {"", "Library/HTTPStorages", ""},
    };
    
    for (int i = 0; i < sizeof(paths) / sizeof(paths[0]); i++) {
        for (int j = 0; j < sizeof(appids) / sizeof(appids[0]); j++) {
            char mobile[PATH_MAX];
            snprintf(mobile, sizeof(mobile), "/var/mobile/%s/%s%s%s",
                     paths[i][1], appids[j], paths[i][0], paths[i][2]);
            if (access(mobile, F_OK) == 0) {
                detected = YES;
            }
            char root[PATH_MAX];
            snprintf(root, sizeof(root), "/var/root/%s/%s%s%s",
                     paths[i][1], appids[j], paths[i][0], paths[i][2]);
            if (access(root, F_OK) == 0) {
                detected = YES;
            }
        }
    }
    return detected;
}

BOOL detect_removed_varjb(void)
{
    BOOL detected = NO;
    char buf[PATH_MAX] = {0};
    
    if (readlink("/var/jb", buf, sizeof(buf)) > 0) {
        // If the symlink exists and its target exists, we flag it.
        if (access(buf, F_OK) == 0) {
            detected = YES;
        }
    }
    return detected;
}

BOOL detect_fugu15Max(void)
{
    BOOL detected = NO;
    
    if (access("/usr/lib/systemhook.dylib", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/usr/lib/sandbox.plist", F_OK) == 0) {
        detected = YES;
    }
    
    if (access("/var/log/launchdhook.log", F_OK) == 0) {
        detected = YES;
    }
    
    struct statfs s = {0};
    statfs("/usr/lib", &s);
    if (strcmp("/", s.f_mntonname) != 0) {
        detected = YES;
    }
    return detected;
}

BOOL detect_url_schemes(void)
{
    BOOL detected = NO;
    static char *schemes[] = {
        "sileo",
        "zbra",
        "cydia",
        "installer",
        "apt-repo",
        "filza",
    };
    
    for (int i = 0; i < sizeof(schemes) / sizeof(schemes[0]); i++) {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%s://", schemes[i]]];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            detected = YES;
        }
    }
    return detected;
}

BOOL detect_jbapp_plugins(void)
{
    BOOL detected = NO;
    NSArray *pluginIDs = @[
        @0xed9a7d2e20b489c1,
        @0xa17028497f7ef4e2,
    ];
    
    id workspace = [NSClassFromString(@"LSApplicationWorkspace") performSelector:@selector(defaultWorkspace)];
    NSArray *plugins = [workspace performSelector:@selector(installedPlugins)];
    
    for (id plugin in plugins) {
        NSString *pluginIdentifier = [plugin performSelector:@selector(pluginIdentifier)];
        if ([pluginIDs containsObject:@(pluginIdentifier.hash)]) {
            detected = YES;
        }
    }
    return detected;
}

BOOL detect_jailbreak_sigs(void)
{
    BOOL detected = NO;
    // This example assumes you have the appropriate jbsigs header and macros defined.
#define JBSIGS(l,h,x) assert(l == sizeof(x)); uint8_t sig_##h[] = x;
#include "headers/jbsigs.h"
    
    struct { char *tag; size_t size; void *data; } jbsigs[] = {
#define JBSIGS(l,h,x) { #h, l, sig_##h },
#include "headers/jbsigs.h"
    };
    
    for (int i = 0; i < sizeof(jbsigs) / sizeof(jbsigs[0]); i++) {
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/tmp/%lx", getenv("HOME"), arc4random());
        
        int fd = open(path, O_RDWR | O_CREAT, 0755);
        assert(fd >= 0);
        
        fsignatures_t sigreg;
        sigreg.fs_file_start = 0;
        sigreg.fs_blob_start = jbsigs[i].data;
        sigreg.fs_blob_size  = jbsigs[i].size;
        
        if (fcntl(fd, F_ADDSIGS, &sigreg) == 0) {
            struct fgetsigsinfo siginfo = {0, GETSIGSINFO_PLATFORM_BINARY, 0};
            assert(fcntl(fd, F_GETSIGSINFO, &siginfo) == 0);
            
            if (siginfo.fg_sig_is_platform) {
                detected = YES;
            }
        }
        close(fd);
        unlink(path);
    }
    return detected;
}

BOOL detect_jailbreak_port(void)
{
    BOOL detected = NO;
    char *ports[] = {
        "cy:com.saurik.substrated",
        "cy:com.opa334.jailbreakd",
        "lh:com.opa334.jailbreakd"
    };
    
    for (int i = 0; i < sizeof(ports) / sizeof(ports[0]); i++) {
        mach_port_t port = MACH_PORT_NULL;
        kern_return_t kr = bootstrap_look_up(bootstrap_port, ports[i], &port);
        if (kr == 0 || kr == 1102) {
            detected = YES;
        }
    }
    return detected;
}

BOOL detect_launchd_jbserver(void) {
    return NO;
}
//BOOL detect_launchd_jbserver(void)
//{
//    BOOL detected = NO;
//    struct xpc_global_data *globalData = NULL;
//
//    if (_os_alloc_once_table[1].once == -1) {
//        globalData = _os_alloc_once_table[1].ptr;
//    } else {
//        globalData = _os_alloc_once(&_os_alloc_once_table[1], 472, NULL);
//        if (!globalData)
//            _os_alloc_once_table[1].once = -1;
//    }
//
//    if (!globalData) {
//        return NO;
//    }
//
//    if (!globalData->xpc_bootstrap_pipe) {
//        mach_port_t *initPorts;
//        mach_msg_type_number_t initPortsCount = 0;
//        if (mach_ports_lookup(mach_task_self(), &initPorts, &initPortsCount) == 0) {
//            globalData->task_bootstrap_port = initPorts[0];
//            globalData->xpc_bootstrap_pipe = xpc_pipe_create_from_port(globalData->task_bootstrap_port, 0);
//        }
//    }
//
//    if (!globalData->xpc_bootstrap_pipe) {
//        return NO;
//    }
//
//    xpc_object_t xpipe = globalData->xpc_bootstrap_pipe;
//    xpc_object_t xdict = xpc_dictionary_create_empty();
//
//    xpc_dictionary_set_uint64(xdict, "jb-domain", JBS_DOMAIN_SYSTEMWIDE);
//    xpc_dictionary_set_uint64(xdict, "action", JBS_SYSTEMWIDE_GET_JBROOT);
//
//    xpc_object_t xreply = NULL;
//    int err = xpc_pipe_routine_with_flags(xpipe, xdict, &xreply, 0);
//
//    if (err != 0) {
//        return NO;
//    }
//
//    if (xreply) {
//        const char *replyRootPath = xpc_dictionary_get_string(xreply, "root-path");
//        if (replyRootPath && strlen(replyRootPath) > 0) {
//            detected = YES;
//        }
//    }
//
//    return detected;
//}

BOOL detect_trollstore_app(void)
{
    // 1. Check via Mach Service (jailbreak-friendly)
    xpc_connection_t connection = xpc_connection_create_mach_service("com.apple.nehelper", nil, 2);
    xpc_connection_set_event_handler(connection, ^(xpc_object_t object){});
    xpc_connection_resume(connection);
    
    xpc_object_t xdict = xpc_dictionary_create(nil, nil, 0);
    xpc_dictionary_set_uint64(xdict, "delegate-class-id", 1);
    xpc_dictionary_set_uint64(xdict, "cache-command", 3);
    xpc_dictionary_set_string(xdict, "cache-signing-identifier", "com.opa334.TrollStore");
    
    xpc_object_t reply = xpc_connection_send_message_with_reply_sync(connection, xdict);
    xpc_object_t resultData = xpc_dictionary_get_value(reply, "result-data");
    
    if (xpc_dictionary_get_value(resultData, "cache-app-uuid") != nil) {
        return YES;
    }
    
    // 2. Check via URL Scheme
    NSURL *url = [NSURL URLWithString:@"trollstore://"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        return YES;
    }
    
    // 3. Check for TrollStore-related files (jailbreak-friendly)
    NSArray *knownTrollStorePaths = @[
        jbroot(@"/var/mobile/Library/TrollStore"),
        jbroot(@"/private/var/containers/Bundle/Application/TrollStore.app"),
        jbroot(@"/var/db/TrollStore.plist"),
        jbroot(@"/var/containers/Bundle/Application/Tips.app/TrollStore"),
        jbroot(@"/var/mobile/Library/Preferences/com.opa334.trollstore.plist")
    ];
    
    for (NSString *path in knownTrollStorePaths) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return YES;
        }
    }
    
    // 4. Check for environment variables
    NSDictionary *env = [[NSProcessInfo processInfo] environment];
    if (env[@"TSINSTALLER"]) {
        return YES;
    }
    
    // 5. Check via NSUserDefaults
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"TrollStoreInstalled"]) {
        return YES;
    }
    
    return NO;
}

BOOL detect_passcode_status(void)
{
    BOOL passcodeSet = NO;
    
    // Check using LocalAuthentication framework
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
        passcodeSet = YES;
    } else {
        passcodeSet = NO;
    }
    
    // Check using SecItemAdd
    NSDictionary *attributes = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"LocalDeviceServices",
        (__bridge id)kSecAttrAccount: @"NoAccount",
        (__bridge id)kSecValueData: [@"Device has passcode set?" dataUsingEncoding:NSUTF8StringEncoding],
        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
    };
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if (status == errSecSuccess) {
        passcodeSet = YES;
        SecItemDelete((__bridge CFDictionaryRef)attributes);
    } else {
        passcodeSet = NO;
    }
    
    // Check using SecureEnclave
    CFErrorRef sacError = NULL;
    SecAccessControlRef sacObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                                    kNilOptions,
                                                                    &sacError);
    
    NSDictionary *params = @{
        (__bridge id)kSecAttrTokenID: (__bridge id)kSecAttrTokenIDSecureEnclave,
        (__bridge id)kSecAttrKeyType: (__bridge id)kSecAttrKeyTypeEC,
        (__bridge id)kSecAttrKeySizeInBits: @256,
        (__bridge id)kSecPrivateKeyAttrs: @{
            (__bridge id)kSecAttrAccessControl: (__bridge_transfer id)sacObject,
            (__bridge id)kSecAttrIsPermanent: @YES,
            (__bridge id)kSecAttrLabel: @"TestKey",
        },
    };
    
    CFErrorRef error = nil;
    SecKeyRef SEKey = SecKeyCreateRandomKey((__bridge CFDictionaryRef)params, &error);
    if (SEKey) {
        passcodeSet = YES;
        CFRelease(SEKey);
    } else {
        passcodeSet = NO;
    }
    
    // Check via MobileKeyBag (if it returns kMobileKeyBagDisabled, then passcode is not set)
    void *MobileKeyBag = dlopen("/System/Library/PrivateFrameworks/MobileKeyBag.framework/MobileKeyBag", RTLD_NOW);
    int (*MKBGetDeviceLockState)(CFDictionaryRef options) = dlsym(MobileKeyBag, "MKBGetDeviceLockState");
    if (MKBGetDeviceLockState != NULL && MKBGetDeviceLockState(NULL) == 3) { // 3 means kMobileKeyBagDisabled
        passcodeSet = NO;
    }
    
    return passcodeSet;
}

#pragma mark - Aggregator

BOOL isJailbroken(void)
{
    return (detect_rootlessJB()     ||
            detect_kernBypass()      ||
            detect_chroot()          ||
            detect_mount_fs()        ||
            detect_bootstraps()      ||
            detect_trollStoredFilza()||
            detect_jailbreakd()      ||
            detect_proc_flags()      ||
            detect_jb_payload()      ||
            detect_exception_port()  ||
            detect_jb_preboot()      ||
            detect_jailbroken_apps() ||
            detect_removed_varjb()   ||
            detect_fugu15Max()       ||
            detect_url_schemes()     ||
            detect_jbapp_plugins()   ||
            detect_jailbreak_sigs()  ||
            detect_jailbreak_port()  ||
            detect_launchd_jbserver()||
            detect_trollstore_app());
}
