#import <UIKit/UIKit.h>
#include "roothide.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (id)getDefaultsForKey:(NSString*)value;
+ (void)setDefaults:(NSObject*)value forKey:(NSString*)key;

@end

#define Localized(x) NSLocalizedString(x,nil)

