#import <UIKit/UIKit.h>

@interface LSBundleProxy : NSObject
@property (nonatomic,readonly) NSURL* bundleURL;
@property (nonatomic,readonly) NSURL* containerURL; 
@property (nonatomic,readonly) NSURL* dataContainerURL; //override by LSPlugInKitProxy and LSApplicationProxy
@property (nonatomic,readonly) NSURL* bundleContainerURL;
@property (nonatomic,readonly) NSString* bundleIdentifier;
@property (nonatomic,readonly) NSString* bundleExecutable;
@property (nonatomic,readonly) NSDictionary* groupContainerURLs;
@end

@interface LSPlugInKitProxy : LSBundleProxy
@property (nonatomic,readonly) NSString* teamID;
@end

@interface LSApplicationProxy : LSBundleProxy
+ (instancetype)applicationProxyForIdentifier:(NSString*)identifier;

@property (nonatomic,readonly) NSString* teamID;
@property (nonatomic,readonly) NSArray * appTags;
@property (nonatomic,readonly) NSString* localizedName;
@property (nonatomic,readonly) NSString* localizedShortName;

@property (nonatomic,readonly) NSString* applicationType;

@property (nonatomic,readonly) NSArray<LSPlugInKitProxy*>* plugInKitPlugins;

@end


@interface RHMInstalledAppInfo : NSObject

@property (nonatomic,readonly) UIImage* icon;
@property (nonatomic,readonly) NSString* name;
@property (nonatomic,readonly) NSString* teamID;

@property (nonatomic,readonly) BOOL isHiddenApp;

@property (nonatomic,readonly) NSURL* bundleURL;
@property (nonatomic,readonly) NSURL* containerURL;
@property (nonatomic,readonly) NSString* applicationType;
@property (nonatomic,readonly) NSString* bundleExecutable;
@property (nonatomic,readonly) NSString* bundleIdentifier;

@property (nonatomic,readonly) NSDictionary* groupContainerURLs;

@property (nonatomic,readonly) NSArray<LSPlugInKitProxy*>* plugInKitPlugins;

@property (nonatomic,readonly) LSApplicationProxy* applicationProxy;

+ (instancetype)appWithPrivateProxy:(id)privateProxy;
+ (instancetype)appWithBundleIdentifier:(NSString*)bundleIdentifier;

@end
