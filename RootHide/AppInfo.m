// https://github.com/wujianguo/iOSAppsInfo
// modified by Shadow-

#import "AppInfo.h"
#import <dlfcn.h>

@interface UIImage ()
+ (id)_iconForResourceProxy:(id)arg1 variant:(int)arg2 variantsScale:(float)arg3;
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(double)arg3;
@end

#pragma mark -

@implementation RHMInstalledAppInfo
{
    UIImage* _icon;
    LSApplicationProxy* _applicationProxy;
}

- (LSApplicationProxy*)applicationProxy
{
    return _applicationProxy;
}

- (NSString*)name
{
    return _applicationProxy.localizedName ?: _applicationProxy.localizedShortName;
}

- (NSString*)bundleIdentifier
{
    return [_applicationProxy bundleIdentifier];
}

- (NSString*)bundleExecutable
{
    return [_applicationProxy bundleExecutable];
}

- (UIImage*)icon
{
    if(nil == _icon)
    {
        _icon = [UIImage _applicationIconImageForBundleIdentifier:self.bundleIdentifier format:10 scale:UIScreen.mainScreen.scale];
    }
    
    return _icon;
}

- (NSURL*)bundleURL
{
    return _applicationProxy.bundleURL;
}
- (NSURL*)containerURL
{
    return _applicationProxy.containerURL;
}

- (NSString*)applicationType
{
    return _applicationProxy.applicationType;
}

- (NSDictionary*)groupContainerURLs
{
    return _applicationProxy.groupContainerURLs;
}

- (NSString*)teamID
{
    return _applicationProxy.teamID;
}

- (NSArray<LSPlugInKitProxy *> *) plugInKitPlugins
{
    return _applicationProxy.plugInKitPlugins;
}

- (BOOL)isHiddenApp
{
    return [[_applicationProxy appTags] indexOfObject:@"hidden"] != NSNotFound;
}

- (id)initWithPrivateProxy:(id)privateProxy
{
    self = [super init];
    if(self != nil)
    {
        _applicationProxy = (LSApplicationProxy*)privateProxy;
    }
    
    return self;
}

- (instancetype)initWithBundleIdentifier:(NSString*)bundleIdentifier
{
    self = [super init];
    if(self != nil)
    {
        _applicationProxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:bundleIdentifier];
    }
    
    return self;
}

+ (instancetype)appWithPrivateProxy:(id)privateProxy
{
    return [[self alloc] initWithPrivateProxy:privateProxy];
}

+ (instancetype)appWithBundleIdentifier:(NSString*)bundleIdentifier
{
    return [[self alloc] initWithBundleIdentifier:bundleIdentifier];
}

@end
