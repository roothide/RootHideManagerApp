#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppListTableViewController : UITableViewController <UISearchBarDelegate>

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
