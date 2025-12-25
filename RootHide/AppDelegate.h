#import <UIKit/UIKit.h>
#include "roothide.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (id)getDefaultsForKey:(NSString*)value;
+ (void)setDefaults:(NSObject*)value forKey:(NSString*)key;

+ (void)showAlert:(UIAlertController*)alert;
+ (void)showMessage:(NSString*)msg title:(NSString*)title;

@end

#define Localized(x) NSLocalizedString(x,nil)

