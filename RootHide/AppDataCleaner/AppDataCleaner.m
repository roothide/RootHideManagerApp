#include <Foundation/Foundation.h>

#import "AppDelegate.h"
#import "AppInfo.h"

#ifndef DEBUG
#define NSLog(...)
#endif

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

NSString* clearAppData(RHMInstalledAppInfo* app)
{
    NSString* error = nil;
    NSLog(@"app.containerURL=%@", app.containerURL);
    
    if(app.containerURL
       && isUUIDPathOf(app.containerURL.path, @"/private/var/mobile/Containers/Data/Application/")
       && [NSFileManager.defaultManager fileExistsAtPath:app.containerURL.path])
    {
        if([NSFileManager.defaultManager removeItemAtURL:app.containerURL error:&error]) {
            NSLog(@"removed %@", app.containerURL);
        } else {
            error = [NSString stringWithFormat:Localized(@"Failed to remove app data container:\n%@"),error];
        }
    }
    return error;
}
