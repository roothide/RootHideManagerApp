#import "jbroot.h"

// Function to detect the jailbreak root path
NSString* detectJailbreakRoot() {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Check for Roothide jailbreak root (.jbroot-<randomstring>)
    NSString *applicationPath = @"/var/containers/Bundle/Application";
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:applicationPath error:nil];
    NSLog(@"Contents of %@: %@", applicationPath, contents); // Debugging
    
    for (NSString *item in contents) {
        if ([item hasPrefix:@".jbroot-"]) {
            NSString *jbRoot = [applicationPath stringByAppendingPathComponent:item];
            NSLog(@"Detected Roothide jailbreak root: %@", jbRoot);
            return jbRoot;
        }
    }
    
    // Check for traditional jailbreak root (/var/jb)
    NSString *jbPath = @"/var/jb";
    if ([fileManager fileExistsAtPath:jbPath]) {
        NSLog(@"Detected traditional jailbreak root: %@", jbPath);
        return jbPath;
    }
    
    // No jailbreak root found
    NSLog(@"No jailbreak root found. Using default root: /");
    return @"/";
}

// NSString* version of jbroot
NSString* __attribute__((overloadable)) jbroot(NSString* path) {
    // Get the jailbreak root path
    NSString *jbRoot = detectJailbreakRoot();
    
    if (jbRoot) {
        // If a jailbreak root is found, prepend it to the path
        return [jbRoot stringByAppendingPathComponent:path];
    }
    
    // If no jailbreak root is found, return the original path (which already includes /var)
    return path;
}

// const char* version of jbroot
const char* __attribute__((overloadable)) jbroot(const char* path) {
    // Convert the C string to an NSString
    NSString *nsPath = [NSString stringWithUTF8String:path];
    
    // Call the NSString* version of jbroot
    NSString *resolvedPath = jbroot(nsPath);
    
    // Return a dynamically allocated C string (caller must free this memory)
    return strdup([resolvedPath UTF8String]);
}
