#import "jbroot.h"

// Function to detect the TrollStore jailbreak root
NSString* trollStoreJailbreakRoot() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *containersPath = @"/var/containers/Bundle";
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:containersPath error:nil];
    
    for (NSString *item in contents) {
        if ([item hasPrefix:@".jbroot-"]) {
            return [containersPath stringByAppendingPathComponent:item];
        }
    }
    
    return nil; // No jailbreak root found
}

// Function to resolve paths relative to the jailbreak root
NSString* jbroot(NSString* path) {
    // Get the TrollStore jailbreak root
    NSString *jbRoot = trollStoreJailbreakRoot();
    if (!jbRoot) {
        // If no jailbreak root is found, return the original path
        return path;
    }
    
    // Resolve the path relative to the jailbreak root
    return [jbRoot stringByAppendingPathComponent:path];
}
