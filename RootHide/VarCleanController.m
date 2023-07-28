#import "VarCleanController.h"
#import "ZFCheckbox.h"
#include "jbroot.h"

@interface VarCleanController () {
    NSMutableArray *menuData;
}

@end

@implementation VarCleanController

+ (instancetype)sharedInstance {
    static VarCleanController* sharedInstance = nil;
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

    
    [self setTitle:@"VarClean"];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Clean" style:UIBarButtonItemStylePlain target:self action:@selector(varClean)];
    self.navigationItem.rightBarButtonItem = button;
    
    UIBarButtonItem *button2 = [[UIBarButtonItem alloc] initWithTitle:@"SeleteAll" style:UIBarButtonItemStylePlain target:self action:@selector(batchSelect)];
    self.navigationItem.leftBarButtonItem = button2;
    
    menuData = [[NSMutableArray alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(startRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    [self updateData];
}

- (void)batchSelect {
    int selected = 0;
    for(NSDictionary* group in menuData) {
        for(NSMutableDictionary* item in group[@"items"]) {
            if(![item[@"checked"] boolValue]) {
                item[@"checked"] = @YES;
                selected++;
            }
        }
    }
    if(selected==0) for(NSDictionary* group in menuData) {
        for(NSMutableDictionary* item in group[@"items"]) {
            if([item[@"checked"] boolValue]) {
                item[@"checked"] = @NO;
            }
        }
    }
    [self.tableView reloadData];
}

- (void)startRefresh {
    [self.tableView.refreshControl beginRefreshing];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self updateData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.tableView.refreshControl endRefreshing];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView.refreshControl beginRefreshing];
    [self.tableView.refreshControl endRefreshing];
}

- (void)updateForRules:(NSDictionary*)rules customed:(NSMutableDictionary*)customedRules {
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
            if([self checkFileInList:file List:whiteList])
                continue;
            
            if([self checkFileInList:file List:customedWhiteList])
                continue;
            
            NSString *filePath = [path stringByAppendingPathComponent:file];
            
            BOOL isDirectory = NO;
            BOOL exists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
            BOOL isFolder = exists && isDirectory;
            
            NSDictionary *tableItem = @{
                @"name": file,
                @"path": filePath,
                @"isFolder": @(isFolder),
                @"checked": @([self checkFileInList:file List:blackList] || [self checkFileInList:file List:customedBlackList])
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
        [menuData addObject:tableGroup];
    }
}

- (void)updateData {
    menuData = [[NSMutableArray alloc] init];
    
    NSString *rulesFilePath = jbroot(@"/var/mobile/Library/RootHide/VarCleanRules.plist");
    NSDictionary *rules = [NSDictionary dictionaryWithContentsOfFile:rulesFilePath];
    
    NSString *customedRulesFilePath = jbroot(@"/var/mobile/Library/RootHide/VarCleanRules-custom.plist");
    NSMutableDictionary *customedRules = [NSMutableDictionary dictionaryWithContentsOfFile:customedRulesFilePath];
    
    [self updateForRules:rules customed:customedRules];
    [self updateForRules:customedRules customed:nil];

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
    NSLog(@"menuData=%@", menuData);
    
    [self.tableView.refreshControl beginRefreshing];
    
    for(NSDictionary* group in [menuData copy]) {
        for(NSDictionary* item in [group[@"items"] copy])
        {
            if(![item[@"checked"] boolValue]) continue;
            
            NSLog(@"clean %@", item[@"path"]);
            
//            NSError* err;
//            if(![NSFileManager.defaultManager removeItemAtPath:item[@"path"] error:&err]) {
//                NSLog(@"clean failed=%@", err);
//                continue;
//            }
            
            
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[group[@"items"] indexOfObject:item]
                                                        inSection:[menuData indexOfObject:group] ];
            
            [group[@"items"] removeObject:item]; //delete source data first
            
            NSLog(@"indexPath=%@", indexPath);
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        }
    }
    
    [self.tableView.refreshControl endRefreshing];
    
//    [self updateData];
//    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSLog(@"numberOfRowsInSection=%ld", menuData.count);
    return menuData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *groupData = menuData[section];
    NSArray *items = groupData[@"items"];
    NSLog(@"numberOfRowsInSection=%ld %ld", (long)section, items.count);
    return items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *groupData = menuData[section];
    return groupData[@"group"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"cellForRowAtIndexPath=%@", indexPath);
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    NSDictionary *groupData = menuData[indexPath.section];
    NSArray *items = groupData[@"items"];
    
    NSDictionary *item = items[indexPath.row];
    cell.textLabel.text =  [NSString stringWithFormat:@"%@ %@",[item[@"isFolder"] boolValue] ? @"📁" : @"📃", item[@"name"]];
    ZFCheckbox *checkbox = [[ZFCheckbox alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [checkbox setSelected:[item[@"checked"] boolValue]];
    cell.accessoryView = checkbox;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    ZFCheckbox *checkbox = (ZFCheckbox*)cell.accessoryView;
    [checkbox setSelected:!checkbox.selected animated:YES];
    
    NSDictionary *groupData = menuData[indexPath.section];
    NSArray *items = groupData[@"items"];
    NSMutableDictionary *item = items[indexPath.row];
    NSLog(@"select=%@", item);
    item[@"checked"] = @(checkbox.selected);
}
@end
