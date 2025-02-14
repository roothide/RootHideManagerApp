// JailbreakDetectorViewController.h

#import <UIKit/UIKit.h>

@interface JailbreakDetectorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *detectionMethods;

+ (BOOL)anyJailbreakChecksDetected;

@end
