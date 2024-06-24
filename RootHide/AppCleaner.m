#include <Foundation/Foundation.h>

#import "AppDelegate.h"
#import "AppInfo.h"

#ifndef DEBUG
#define NSLog(...)
#endif

BOOL isUUIDPathOf(NSString* path, NSString* parent);

NSString* clearAppData(AppInfo* app)
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
