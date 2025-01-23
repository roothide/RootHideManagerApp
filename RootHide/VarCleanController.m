#import "varCleanController.h"
#include "AppDelegate.h"
#import "ZFCheckbox.h"

@interface varCleanController ()
@property (nonatomic, retain) NSMutableArray* tableData;

// Declare the method with the correct signature
- (void)updateForRules:(NSDictionary*)rules
              customed:(NSMutableDictionary*)customedRules
               newData:(NSMutableArray*)newData
             keepState:(BOOL)keepState;

@end

@implementation varCleanController

+ (instancetype)sharedInstance {
    static varCleanController* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.clearsSelectionOnViewWillAppear = NO;
    
    [self setTitle:Localized(@"varClean")];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:Localized(@"Clean") style:UIBarButtonItemStylePlain target:self action:@selector(varClean)];
    self.navigationItem.rightBarButtonItem = button;
    
    UIBarButtonItem *button2 = [[UIBarButtonItem alloc] initWithTitle:Localized(@"SelectAll") style:UIBarButtonItemStylePlain target:self action:@selector(batchSelect)];
    self.navigationItem.leftBarButtonItem = button2;
    
    self.tableData = [[NSMutableArray alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(manualRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    self.tableData = [self updateData:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoRefresh)
                                          name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)batchSelect {
    int selected = 0;
    for(NSDictionary* group in self.tableData) {
        for(NSMutableDictionary* item in group[@"items"]) {
            if(![item[@"checked"] boolValue]) {
                item[@"checked"] = @YES;
                selected++;
            }
        }
    }
    if(selected==0) for(NSDictionary* group in self.tableData) {
        for(NSMutableDictionary* item in group[@"items"]) {
            if([item[@"checked"] boolValue]) {
                item[@"checked"] = @NO;
            }
        }
    }
    [self.tableView reloadData];
}

- (void)startRefresh:(BOOL)keepState {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray* newData = [self updateData:keepState];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.tableData = newData;
            [self.tableView reloadData];
            [self.tableView.refreshControl endRefreshing];
        });
    });
}

- (void)manualRefresh {
    [self startRefresh:NO];
}

- (void)autoRefresh {
    [self startRefresh:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl endRefreshing];
}

- (void)updateForRules:(NSDictionary*)rules
              customed:(NSMutableDictionary*)customedRules
               newData:(NSMutableArray*)newData
             keepState:(BOOL)keepState {
    for (NSString* path in rules) {
        NSMutableArray *folders = [[NSMutableArray alloc] init];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        
        NSDictionary* ruleItem = [rules objectForKey:path];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
        
        NSArray *whiteList = ruleItem[@"whitelist"];
        NSArray *blackList = ruleItem[@"blacklist"];
        
        NSDictionary* customedRuleItem = customedRules[path];
        NSArray* customedWhiteList = customedRuleItem[@"whitelist"];
        NSArray* customedBlackList = customedRuleItem[@"blacklist"];
        [customedRules removeObjectForKey:path];
        
        NSMutableDictionary *tableGroup = @{
            @"group": path,
            @"items": @[]
        }.mutableCopy;
        
        for (NSString *file in contents) {
            
            BOOL checked = NO;
            
            // Custom default priority
            NSString* _default = customedRuleItem[@"default"];
            if(!_default) _default = ruleItem[@"default"];
            
            // Blacklist priority: items in blacklist should be checked
            if ([self checkFileInList:file List:blackList] || [self checkFileInList:file List:customedBlackList]) {
                checked = YES;
            }
            // Whitelist priority: items explicitly in the whitelist should not be shown (skip them)
            else if ([self checkFileInList:file List:whiteList] || [self checkFileInList:file List:customedWhiteList]) {
                continue;  // Skip the explicitly whitelisted items
            }
            // Default behavior for blacklisted items: show them and checked
            else if (_default && [_default isEqualToString:@"blacklist"]) {
                checked = YES;
            }
            // Default behavior for whitelisted items: show them but unchecked
            else if (_default && [_default isEqualToString:@"whitelist"]) {
                checked = NO;  // Keep unchecked but still show the item
            }
            else
            {
                checked = NO;
            }
            
            // If keepState is YES, preserve the checked state from the existing data
            if (keepState) {
                for (NSDictionary* group in self.tableData) {
                    if ([group[@"group"] isEqualToString:path]) {
                        for (NSDictionary* item in group[@"items"]) {
                            if ([item[@"name"] isEqualToString:file]) {
                                checked = [item[@"checked"] boolValue];
                                break;
                            }
                        }
                        break;
                    }
                }
            }
            
            NSString *filePath = [path stringByAppendingPathComponent:file];
            
            BOOL isDirectory = NO;
            BOOL exists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
            BOOL isFolder = exists && isDirectory;
            
            NSMutableDictionary *tableItem = @{
                @"name": file,
                @"path": filePath,
                @"isFolder": @(isFolder),
                @"checked": @(checked)
            }.mutableCopy;
            
            if(isFolder) {
                [folders addObject:tableItem];
            } else {
                [files addObject:tableItem];
            }
        }
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortedFolders = [folders sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSArray *sortedFiles = [files sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        tableGroup[@"items"] = [[sortedFolders arrayByAddingObjectsFromArray:sortedFiles] mutableCopy];
        [newData addObject:tableGroup];
    }
}

- (NSMutableArray*)updateData:(BOOL)keepState {
    NSLog(@"updateData...");
    NSMutableArray* newData = [[NSMutableArray alloc] init];
    
    NSString *rulesFilePath = @"/var/mobile/Library/RootHide/varCleanRules.plist";
    NSDictionary *rules = [NSDictionary dictionaryWithContentsOfFile:rulesFilePath];
    
    NSString *customedRulesFilePath = @"/var/mobile/Library/RootHide/varCleanRules-custom.plist";
    NSMutableDictionary *customedRules = [NSMutableDictionary dictionaryWithContentsOfFile:customedRulesFilePath];
    
    // Call the updated method with the correct parameters
    [self updateForRules:rules customed:customedRules newData:newData keepState:keepState];
    [self updateForRules:customedRules customed:nil newData:newData keepState:keepState];

    NSComparator sorter = ^NSComparisonResult(NSDictionary* a, NSDictionary* b)
    {
        if([a[@"items"] count]!=0 && [b[@"items"] count]==0) return NSOrderedAscending;
        if([a[@"items"] count]==0 && [b[@"items"] count]!=0) return NSOrderedDescending;
        
        return [a[@"group"] compare:b[@"group"]];
    };
    [newData sortUsingComparator:sorter];
    
    return newData;
}

- (BOOL)checkFileInList:(NSString *)fileName List:(NSArray*)list {
    for (NSObject* item in list) {
        if([item isKindOfClass:NSString.class]) {
            if ([fileName isEqualToString:(NSString*)item]) {
                return YES;
            }
        } else if([item isKindOfClass:NSDictionary.class]) {
            NSDictionary* condition = (NSDictionary*)item;
            NSString *name = condition[@"name"];
            NSString *match = condition[@"match"];
            
            if ([match isEqualToString:@"include"]) {
                if ([fileName rangeOfString:name].location != NSNotFound) {
                    return YES;
                }
            } else if ([match isEqualToString:@"regexp"]) {
                NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:name options:0 error:nil];
                NSUInteger result = [regex numberOfMatchesInString:fileName options:0 range:NSMakeRange(0, fileName.length)];
                if(result != 0) return YES;
            }
        }
    }
    return NO;
}

- (void)varClean {
    // Collect all the files marked for deletion
    NSMutableArray *filesToDelete = [NSMutableArray array];
    for (NSDictionary* group in self.tableData) {
        for (NSDictionary* item in group[@"items"]) {
            if ([item[@"checked"] boolValue]) {
                [filesToDelete addObject:item[@"path"]];
            }
        }
    }
    
    // If no files are selected, show an alert and return
    if (filesToDelete.count == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:Localized(@"No Files Selected")
                                                                       message:Localized(@"Please select files to clean.")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:Localized(@"OK")
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Create a string listing all the files to delete
    NSMutableString *fileList = [NSMutableString string];
    for (NSString *filePath in filesToDelete) {
        [fileList appendFormat:@"%@\n", filePath];
    }
    
    // Show a confirmation popup with the list of files
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:Localized(@"Confirm Deletion")
                                                                             message:[NSString stringWithFormat:Localized(@"You are about to delete the following files:\n\n%@"), fileList]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    // Add a "Confirm" button
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:Localized(@"Confirm")
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull action) {
        // Perform the deletion
        [self performDeletion];
    }];
    
    // Add a "Cancel" button
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:Localized(@"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    // Add the actions to the alert controller
    [alertController addAction:confirmAction];
    [alertController addAction:cancelAction];
    
    // Present the alert controller
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)performDeletion {
    [self.tableView.refreshControl beginRefreshing];
    
    for (NSDictionary* group in [self.tableData copy]) {
        for (NSDictionary* item in [group[@"items"] copy]) {
            if (![item[@"checked"] boolValue]) continue;
            
            NSLog(@"Deleting: %@", item[@"path"]);
            
            NSError *err;
            if (![NSFileManager.defaultManager removeItemAtPath:item[@"path"] error:&err]) {
                NSLog(@"Deletion failed: %@", err);
                
                // Fallback to root user deletion if necessary
                if (geteuid() != 0 || getegid() != 0) {
                    NSLog(@"Trying RootUserRemoveItemAtPath: %@", item[@"path"]);
                    BOOL RootUserRemoveItemAtPath(NSString* path);
                    BOOL __ret = RootUserRemoveItemAtPath(item[@"path"]);
                }
                
                continue;
            }
            
            // Remove the item from the table data
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[group[@"items"] indexOfObject:item]
                                                        inSection:[self.tableData indexOfObject:group]];
            [group[@"items"] removeObject:item];
            
            // Remove the row from the table view
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
    }
    
    [self.tableView.refreshControl endRefreshing];
    
    // Refresh the data
    self.tableData = [self updateData:NO];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"numberOfRowsInSection=%ld", self.tableData.count);
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *groupData = self.tableData[section];
    NSArray *items = groupData[@"items"];
    NSLog(@"numberOfRowsInSection=%ld %ld", (long)section, items.count);
    return items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *groupData = self.tableData[section];
    return groupData[@"group"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cellForRowAtIndexPath=%@", indexPath);
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    NSDictionary *groupData = self.tableData[indexPath.section];
    NSArray *items = groupData[@"items"];
    
    NSDictionary *item = items[indexPath.row];
    cell.textLabel.text =  [NSString stringWithFormat:@"%@ %@",[item[@"isFolder"] boolValue] ? @"🗂️" : @"📄", item[@"name"]];
    ZFCheckbox *checkbox = [[ZFCheckbox alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    checkbox.userInteractionEnabled = FALSE; //passthrough to didSelectRowAtIndexPath
    [checkbox setSelected:[item[@"checked"] boolValue]];
    cell.accessoryView = checkbox;
    
    UILongPressGestureRecognizer *gest = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(cellLongPress:)];
    [cell.contentView addGestureRecognizer:gest];
    gest.view.tag = indexPath.row | indexPath.section<<32;
    gest.minimumPressDuration = 1;
    
    return cell;
}

- (void)cellLongPress:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        long tag = recognizer.view.tag;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:tag&0xFFFFFFFF inSection:tag>>32];
        
        NSDictionary *groupData = self.tableData[indexPath.section];
        NSArray *items = groupData[@"items"];
        NSMutableDictionary *item = items[indexPath.row];
        NSLog(@"open item %@", item);
        NSURL* url = [NSURL URLWithString:[@"filza://view" stringByAppendingString:
                                           [item[@"path"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] ];
        
        NSLog(@"open url %@", url);
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    ZFCheckbox *checkbox = (ZFCheckbox*)cell.accessoryView;
    
    BOOL newstate = !checkbox.selected;
    
    [checkbox setSelected:newstate animated:YES];
    
    NSDictionary *groupData = self.tableData[indexPath.section];
    NSArray *items = groupData[@"items"];
    NSMutableDictionary *item = items[indexPath.row];
    item[@"checked"] = @(newstate);
    NSLog(@"select=%@", item);
}
@end
