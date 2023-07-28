#import "VarCleanController.h"
#import "ZFCheckbox.h"

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
    
    [self setTitle:@"VarClean"];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Clean" style:UIBarButtonItemStylePlain target:self action:@selector(varClean)];
    self.navigationItem.rightBarButtonItem = button;
    
    NSArray *rules = @[
        @{
            @"path": @"/var",
            @"whitelist": @[
                @{
                    @"name": @"asl",
                    @"match": @"equal"
                },
                @{
                    @"name": @"alf",
                    @"match": @"include"
                },
                @{
                    @"name": @".+log$",
                    @"match": @"regexp"
                }
            ],
            @"blacklist": @[
                @{
                    @"name": @"mobile2",
                    @"match": @"include",
                },
                @{
                    @"name": @"^wifi.+log$",
                    @"match": @"regexp",
                }
            ]
        },
        @{
            @"path": @"/var/log",
            @"whitelist": @[
                @{
                    @"name": @"asl",
                    @"match": @"equal"
                },
                @{
                    @"name": @"alf",
                    @"match": @"include"
                },
                @{
                    @"name": @".+log$",
                    @"match": @"regexp"
                }
            ],
            @"blacklist": @[
                @{
                    @"name": @"mobile2",
                    @"match": @"include",
                },
                @{
                    @"name": @"^wifi.+log$",
                    @"match": @"regexp",
                }
            ]
        },
    ];
    
    NSString *rulesFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"rules.plist"];
    [rules writeToFile:rulesFilePath atomically:YES];
    
    menuData = [[NSMutableArray alloc] init];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor grayColor];
    [refreshControl addTarget:self action:@selector(startRefresh) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refreshControl;
    
    [self updateData];
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

- (void)updateData {
    menuData = [[NSMutableArray alloc] init];
    
    NSString *rulesFilePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"rules.plist"];
    NSArray *rules = [NSArray arrayWithContentsOfFile:rulesFilePath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSDictionary *ruleItem in rules) {
        NSMutableArray *folders = [[NSMutableArray alloc] init];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:ruleItem[@"path"] error:nil];
        
        NSArray *whiteList = ruleItem[@"whitelist"];
        NSArray *blackList = ruleItem[@"blacklist"];
        
        NSMutableDictionary *tableGroup = @{
            @"group": ruleItem[@"path"],
            @"items": @[]
        }.mutableCopy;
        
        for (NSString *file in contents) {
            if([self checkFileInList:file List:whiteList])
                continue;
            
            NSString *filePath = [ruleItem[@"path"] stringByAppendingPathComponent:file];
            
            BOOL isDirectory = NO;
            BOOL exists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
            BOOL isFolder = exists && isDirectory;
            
            NSDictionary *tableItem = @{
                @"name": file,
                @"path": filePath,
                @"isFolder": @(isFolder),
                @"isCheck": @([self checkFileInList:file List:blackList])
            };
            
            if(isFolder) {
                [folders addObject:tableItem];
            } else {
                [files addObject:tableItem];
            }
        }
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortedFolders = [folders sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSArray *sortedFiles = [files sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        tableGroup[@"items"] = [sortedFolders arrayByAddingObjectsFromArray:sortedFiles];
        [menuData addObject:tableGroup];
    }
}

- (BOOL)checkFileInList:(NSString *)fileName List:(NSArray*)list {
    for (NSDictionary *condition in list) {
        NSString *name = condition[@"name"];
        NSString *match = condition[@"match"];
        
        if ([match isEqualToString:@"equal"]) {
            if ([fileName isEqualToString:name]) {
                return YES;
            }
        } else if ([match isEqualToString:@"include"]) {
            if ([fileName rangeOfString:name].location != NSNotFound) {
                return YES;
            }
        } else if ([match isEqualToString:@"regexp"]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", name];
            if ([predicate evaluateWithObject:fileName]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)varClean {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return menuData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSDictionary *groupData = menuData[section];
    NSArray *items = groupData[@"items"];
    return items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSDictionary *groupData = menuData[section];
    return groupData[@"group"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    NSDictionary *groupData = menuData[indexPath.section];
    NSArray *items = groupData[@"items"];
    
    NSDictionary *item = items[indexPath.row];
    cell.textLabel.text =  [NSString stringWithFormat:@"%@ %@",[item[@"isFolder"] boolValue] ? @"📁" : @"📃", item[@"name"]];
    ZFCheckbox *checkbox = [[ZFCheckbox alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [checkbox setSelected:[item[@"isCheck"] boolValue]];
    cell.accessoryView = checkbox;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];//取消选中效果
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    ZFCheckbox *checkbox = (ZFCheckbox*)cell.accessoryView;
    [checkbox setSelected:!checkbox.selected animated:YES];
}
@end
