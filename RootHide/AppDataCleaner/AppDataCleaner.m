#include <Foundation/Foundation.h>
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <sqlite3.h>

#import "AppDelegate.h"
#import "AppInfo.h"

#ifndef DEBUG
#define NSLog(...)
#endif

int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

static void killAllForExecutable(const char* path, int signal)
{
    NSLog(@"killExecutable %s, %d", path, signal);
    
    static int maxArgumentSize = 0;
    if (maxArgumentSize == 0) {
        size_t size = sizeof(maxArgumentSize);
        if (sysctl((int[]){ CTL_KERN, KERN_ARGMAX }, 2, &maxArgumentSize, &size, NULL, 0) == -1) {
            perror("sysctl argument size");
            maxArgumentSize = 4096; // Default
        }
    }

    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    size_t count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        size_t size = maxArgumentSize;
        char* buffer = (char *)malloc(size);
        if (sysctl((int[]){ CTL_KERN, KERN_PROCARGS2, pid }, 3, buffer, &size, NULL, 0) == 0) {
            char* executablePath = buffer + sizeof(int);
            if (strcmp(executablePath, path)==0) {
                NSLog(@"kill pid=%d path=%s\n", pid, executablePath);
                kill(pid, SIGKILL);
            }
        }
        free(buffer);
    }
    free(info);
}

typedef struct __SecCode const *SecStaticCodeRef;

typedef CF_OPTIONS(uint32_t, SecCSFlags) {
    kSecCSDefaultFlags = 0
};
#define kSecCSRequirementInformation 1 << 2
#define kSecCSSigningInformation 1 << 1

OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef *staticCode);
OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef *information);
CFDataRef SecCertificateCopyExtensionValue(SecCertificateRef certificate, CFTypeRef extensionOID, bool *isCritical);
void SecPolicySetOptionsValue(SecPolicyRef policy, CFStringRef key, CFTypeRef value);

extern CFStringRef kSecCodeInfoEntitlementsDict;
extern CFStringRef kSecCodeInfoCertificates;
extern CFStringRef kSecPolicyAppleiPhoneApplicationSigning;
extern CFStringRef kSecPolicyAppleiPhoneProfileApplicationSigning;
extern CFStringRef kSecPolicyLeafMarkerOid;

static SecStaticCodeRef getStaticCodeRef(NSString *binaryPath) {
    if (binaryPath == nil) {
        return NULL;
    }
    
    CFURLRef binaryURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)binaryPath, kCFURLPOSIXPathStyle, false);
    if (binaryURL == NULL) {
        return NULL;
    }
    
    SecStaticCodeRef codeRef = NULL;
    OSStatus result;
    
    result = SecStaticCodeCreateWithPathAndAttributes(binaryURL, kSecCSDefaultFlags, NULL, &codeRef);
    
    CFRelease(binaryURL);
    
    if (result != errSecSuccess) {
        return NULL;
    }
        
    return codeRef;
}

static NSDictionary *dumpEntitlements(SecStaticCodeRef codeRef) {
    if (codeRef == NULL) {
        return nil;
    }
    
    CFDictionaryRef signingInfo = NULL;
    OSStatus result;
    
    result = SecCodeCopySigningInformation(codeRef, kSecCSRequirementInformation, &signingInfo);
    
    if (result != errSecSuccess) {
        return nil;
    }
    
    NSDictionary *entitlementsNSDict = nil;
    
    CFDictionaryRef entitlements = CFDictionaryGetValue(signingInfo, kSecCodeInfoEntitlementsDict);
    if (entitlements) {
        if (CFGetTypeID(entitlements) == CFDictionaryGetTypeID()) {
            entitlementsNSDict = (__bridge NSDictionary *)(entitlements);
        }
    }
    CFRelease(signingInfo);
    return entitlementsNSDict;
}

static NSDictionary *dumpEntitlementsFromBinaryAtPath(NSString *binaryPath) {
    if (binaryPath == nil) {
        return nil;
    }
    
    SecStaticCodeRef codeRef = getStaticCodeRef(binaryPath);
    if (codeRef == NULL) {
        return nil;
    }
    
    NSDictionary *entitlements = dumpEntitlements(codeRef);
    CFRelease(codeRef);

    return entitlements;
}

static BOOL isUUIDPathOf(NSString* path, NSString* parent)
{
    if(!path || !parent) return NO;

    const char* _path = path.UTF8String;
    const char* _parent = parent.UTF8String;
    
    char rp[PATH_MAX];
    if(!realpath(_path, rp)) return NO;
    
    char rpp[PATH_MAX+1];
    if(!realpath(_parent, rpp)) return NO;
    
    size_t rpplen = strlen(rpp);
    
    if(rpp[rpplen] != '/') {
        strcat(rpp, "/");
        rpplen++;
    }

    if(strncmp(rp, rpp, rpplen) != 0)
        return NO;

    char* p1 = rp + rpplen;
    char* p2 = strchr(p1, '/');
    if(!p2) p2 = rp + strlen(rp);

    //is normal app or jailbroken app/daemon?
    if((p2 - p1) != (sizeof("xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx")-1))
        return NO;

    return YES;
}

static NSArray* AppContainerDefault = @[
    @".com.apple.mobile_container_manager.metadata.plist",
    @"Documents",
    @"Library",
    @"Library/Caches",
    @"Library/SplashBoard",
    @"Library/SplashBoard/Snapshots",
    @"Library/Preferences",
    @"SystemData",
    @"StoreKit",
    @"StoreKit/receipt",
    @"tmp",
];

static NSArray* PluginContainerDefault = @[
    @".com.apple.mobile_container_manager.metadata.plist",
    @"Documents",
    @"Library",
    @"Library/Caches",
    @"Library/Preferences",
    @"SystemData",
    @"StoreKit",
    @"StoreKit/receipt",
    @"tmp",
];

static NSArray* GroupContainerDefault = @[
    @".com.apple.mobile_container_manager.metadata.plist",
    @"Library",
    @"Library/Caches",
];

static BOOL clearContainer(NSString* dir, NSArray* ignoreFiles, NSError** perror)
{
    NSArray* subPaths = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:dir error:perror];
    if(!subPaths) return NO;
    
    NSLog(@"subPaths = %@", subPaths);

    for (NSString* subpath in subPaths)
    {
        @autoreleasepool
        {
            NSString* fullpath = [dir stringByAppendingPathComponent:subpath];
            
            if([ignoreFiles containsObject:subpath]) {
                NSLog(@"skip %@", fullpath);
                continue;
            }
            
            if(![NSFileManager.defaultManager fileExistsAtPath:fullpath]) {
                NSLog(@"already removed? %@", fullpath);
                continue;
            }
            
            if(![NSFileManager.defaultManager removeItemAtPath:fullpath error:perror]) {
                NSLog(@"remove %@", fullpath);
                return NO;
            }
        }
    }
    
    return YES;
}

NSString* clearAppData(RHMInstalledAppInfo* app)
{
    __block char* perror=NULL;
    __block sqlite3* ppDb=NULL;
    
    uid_t olduid=getuid();
    gid_t oldgid=getgid();
    uid_t oldeuid=geteuid();
    gid_t oldegid=getegid();
    
    setreuid(0, 0);
    setregid(0, 0);
    
    NSLog(@"new: uid=%d euid=%d gid=%d egid=%d", getuid(), geteuid(), getgid(), getegid());
    
// sqlite supports multi-process reading and writing?
// and this may cause the system to hang forever on some devices
//    killExecutable("/usr/libexec/securityd", SIGSTOP);
    
    __block NSString* erret = nil;
    do {
        
        NSLog(@"app teamID=%@ bundleIdentifier=%@", app.teamID, app.bundleIdentifier);
        
        /*
         SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND sql LIKE '%agrp%'
         */
        NSArray* tables = @[
            (NSString*)kSecClassInternetPassword,
            (NSString*)kSecClassGenericPassword,
            (NSString*)kSecClassCertificate,
            (NSString*)kSecClassKey,
            //(NSString*)kSecClassIdentity, //also in kSecClassCertificate table
        ];
        
        int retcode = sqlite3_open("/var/Keychains/keychain-2.db", &ppDb);
        if(retcode != SQLITE_OK)
        {
            erret = [NSString stringWithFormat:Localized(@"Failed to open db, error %d"),retcode];
            break;
        }
        
        for(NSString* tbl in tables)
        {
            NSString* sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE agrp='%@.%@'", tbl, app.teamID, app.bundleIdentifier];
            retcode = sqlite3_exec(ppDb,sql.UTF8String,nil,nil,&perror);
            
            if(retcode != SQLITE_OK) {
                erret = [NSString stringWithFormat:Localized(@"Failed to exec %@, error %d,%s"),sql, retcode, perror];
                break;
            }
        }
        if(erret) break;
        
        
        NSString* (^clearGroupData)(LSBundleProxy*) = ^NSString*(LSBundleProxy* proxy)
        {
            [proxy.groupContainerURLs enumerateKeysAndObjectsUsingBlock:^(NSString* groupId, NSURL* groupURL, BOOL* stop)
             {
                NSLog(@"app.groupContainerURLs %@=%@", groupId, groupURL);
                
                NSError* error=nil;
                if(groupURL
                   && isUUIDPathOf(groupURL.path, @"/private/var/mobile/Containers/Shared/AppGroup/")
                   &&[NSFileManager.defaultManager fileExistsAtPath:groupURL.path])
                {
                    if(clearContainer(groupURL.path, GroupContainerDefault, &error)) {
                        NSLog(@"removed %@", groupURL);
                    } else {
                        erret = [NSString stringWithFormat:Localized(@"Failed to remove app group container:\n%@"),error];
                        *stop = YES;
                    }
                }
                
                char* perror=NULL;
                NSString* sql = [NSString stringWithFormat:@"DELETE FROM genp WHERE agrp='%@'", groupId];
                int retcode = sqlite3_exec(ppDb,sql.UTF8String,nil,nil,&perror);
                
                if(retcode != SQLITE_OK) {
                    erret = [NSString stringWithFormat:Localized(@"Failed to exec %@, error %d,%s"),sql, retcode, perror];
                    *stop = YES;
                }
            }];
            if(erret) return erret;
            
            NSString* executablePath = [proxy.bundleURL.path stringByAppendingPathComponent:proxy.bundleExecutable];
            NSDictionary* entitlements = dumpEntitlementsFromBinaryAtPath(executablePath);
            if(entitlements) {
                NSArray* keychainGroups = entitlements[@"keychain-access-groups"];
                if(keychainGroups) for(NSString* groupId in keychainGroups) {
                    NSLog(@"keychainGroups: %@", groupId);
                    
                    for(NSString* tbl in tables)
                    {
                        NSString* sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE agrp='%@'", tbl, groupId];
                        int retcode = sqlite3_exec(ppDb,sql.UTF8String,nil,nil,&perror);
                        
                        if(retcode != SQLITE_OK) {
                            erret = [NSString stringWithFormat:Localized(@"Failed to exec %@, error %d,%s"),sql, retcode, perror];
                            break;
                        }
                    }
                    if(erret) break;
                }
            }
            if(erret) return erret;
            
            return nil;
        };
        
        NSLog(@"app.containerURL=%@", app.containerURL);

        if(app.containerURL
           && isUUIDPathOf(app.containerURL.path, @"/private/var/mobile/Containers/Data/Application/")
           && [NSFileManager.defaultManager fileExistsAtPath:app.containerURL.path])
        {
            NSError* error=nil;
           if(clearContainer(app.containerURL.path, AppContainerDefault, &error)) {
               NSLog(@"removed %@", app.containerURL);
           } else {
               erret = [NSString stringWithFormat:Localized(@"Failed to remove app data container:\n%@"),error];
               break;
           }
        }
        if(erret) break;
        
        for(LSPlugInKitProxy* appPlugin in app.plugInKitPlugins)
        {
            NSLog(@"app.plugInKitPlugins %@=%@", appPlugin.bundleIdentifier, appPlugin.dataContainerURL);
            
            NSError* error=nil;
            if(appPlugin.dataContainerURL
               && isUUIDPathOf(appPlugin.dataContainerURL.path, @"/private/var/mobile/Containers/Data/PluginKitPlugin/")
               &&[NSFileManager.defaultManager fileExistsAtPath:appPlugin.dataContainerURL.path])
            {
                if(clearContainer(appPlugin.dataContainerURL.path, PluginContainerDefault, &error)) {
                    NSLog(@"removed %@", appPlugin.dataContainerURL);
                    
                    erret = clearGroupData(appPlugin);
                    if(erret) break;
                    
                } else {
                    erret = [NSString stringWithFormat:Localized(@"Failed to remove app plugin container:\n%@"),error];
                    break;
                }
            }
        }
        if(erret) break;
        
        erret = clearGroupData(app.applicationProxy);
        if(erret) break;
                
    } while(0);
    
    if(ppDb) sqlite3_close(ppDb);
    
    killAllForExecutable("/usr/libexec/securityd", SIGKILL);
    
    //reset app preferences
    killAllForExecutable("/usr/sbin/cfprefsd", SIGKILL);
    
    /*
     /var/mobile/Library/Caches/com.apple.Pasteboard
     killExecutable("/usr/sbin/pasted", SIGKILL);
     */
    
    setreuid(olduid, oldeuid);
    setregid(oldgid, oldegid);
    
    NSLog(@"resotre: uid=%d euid=%d gid=%d egid=%d", getuid(), geteuid(), getgid(), getegid());

    return erret;
}
