#import <dlfcn.h>
#import <spawn.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "AppInfo.h"

#ifndef DEBUG
#define NSLog(...)
#endif

extern const char** environ;

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

int spawn(const char* path, const char** argv, const char** envp, void(^std_out)(char*,int), void(^std_err)(char*,int))
{
    NSLog(@"spawn %s", path);
    
    __block pid_t pid=0;
    posix_spawnattr_t attr;
    posix_spawnattr_init(&attr);
    
    posix_spawnattr_set_persona_np(&attr, 99, POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE);
    posix_spawnattr_set_persona_uid_np(&attr, 0);
    posix_spawnattr_set_persona_gid_np(&attr, 0);

    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);

    int outPipe[2] = {0};
    assert(pipe(outPipe) == 0);
    posix_spawn_file_actions_addclose(&action, outPipe[0]);
    posix_spawn_file_actions_adddup2(&action, outPipe[1], STDOUT_FILENO);
    posix_spawn_file_actions_addclose(&action, outPipe[1]);
    
    int errPipe[2] = {0};
    assert(pipe(errPipe) == 0);
    posix_spawn_file_actions_addclose(&action, errPipe[0]);
    posix_spawn_file_actions_adddup2(&action, errPipe[1], STDERR_FILENO);
    posix_spawn_file_actions_addclose(&action, errPipe[1]);

    
    dispatch_semaphore_t lock = dispatch_semaphore_create(0);
    
    dispatch_queue_t queue = dispatch_queue_create("spawnPipeQueue", DISPATCH_QUEUE_CONCURRENT);
    
    dispatch_source_t stdOutSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, outPipe[0], 0, queue);
    dispatch_source_t stdErrSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, errPipe[0], 0, queue);
    
    int outFD = outPipe[0];
    int errFD = errPipe[0];
    
    dispatch_source_set_cancel_handler(stdOutSource, ^{
        close(outFD);
        dispatch_semaphore_signal(lock);
        NSLog(@"stdout canceled [%d]", pid);
    });
    dispatch_source_set_cancel_handler(stdErrSource, ^{
        close(errFD);
        dispatch_semaphore_signal(lock);
        NSLog(@"stderr canceled [%d]", pid);
    });
    
    dispatch_source_set_event_handler(stdOutSource, ^{
        char buffer[BUFSIZ]={0};
        ssize_t bytes = read(outFD, buffer, sizeof(buffer)-1);
        if (bytes <= 0) {
            dispatch_source_cancel(stdOutSource);
            return;
        }
        NSLog(@"spawn[%d] stdout: %s", pid, buffer);
        if(std_out) std_out(buffer,bytes);
    });
    dispatch_source_set_event_handler(stdErrSource, ^{
        char buffer[BUFSIZ]={0};
        ssize_t bytes = read(errFD, buffer, sizeof(buffer)-1);
        if (bytes <= 0) {
            dispatch_source_cancel(stdErrSource);
            return;
        }
        NSLog(@"spawn[%d] stderr: %s", pid, buffer);
        if(std_err) std_err(buffer,bytes);
    });
    
    dispatch_resume(stdOutSource);
    dispatch_resume(stdErrSource);
    
    int spawnError = posix_spawn(&pid, path, &action, &attr, argv, envp);
    NSLog(@"spawn ret=%d, pid=%d", spawnError, pid);
    
    posix_spawnattr_destroy(&attr);
    posix_spawn_file_actions_destroy(&action);
    
    close(outPipe[1]);
    close(errPipe[1]);
    
    if(spawnError != 0)
    {
        NSLog(@"posix_spawn error %d:%s\n", spawnError, strerror(spawnError));
        dispatch_source_cancel(stdOutSource);
        dispatch_source_cancel(stdErrSource);
        return spawnError;
    }
    
    //wait stdout
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    //wait stderr
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    
    int status=0;
    while(waitpid(pid, &status, 0) != -1)
    {
        if (WIFSIGNALED(status)) {
            return 128 + WTERMSIG(status);
        } else if (WIFEXITED(status)) {
            return WEXITSTATUS(status);
        }
        //keep waiting?return status;
    };
    return -1;
}

int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr)
{
    NSLog(@"spawnRoot %@ with %@", path, args);
    
    NSMutableArray* argsM = args.mutableCopy ?: [NSMutableArray new];
    [argsM insertObject:path atIndex:0];
    
    NSUInteger argCount = [argsM count];
    char **argsC = (char **)malloc((argCount + 1) * sizeof(char*));

    for (NSUInteger i = 0; i < argCount; i++)
    {
        argsC[i] = strdup([[argsM objectAtIndex:i] UTF8String]);
    }
    argsC[argCount] = NULL;

    
    __block NSMutableString* outString=nil;
    __block NSMutableString* errString=nil;
    
    if(stdOut) outString = [NSMutableString new];
    if(stdErr) errString = [NSMutableString new];
    
    int retval = spawn(path.fileSystemRepresentation, argsC, environ, ^(char* outstr, int length){
        NSString *str = [[NSString alloc] initWithBytes:outstr length:length encoding:NSASCIIStringEncoding];
        if(stdOut) [outString appendString:str];
    }, ^(char* errstr, int length){
        NSString *str = [[NSString alloc] initWithBytes:errstr length:length encoding:NSASCIIStringEncoding];
        if(stdErr) [errString appendString:str];
    });
    
    if(stdOut) *stdOut = outString.copy;
    if(stdErr) *stdErr = errString.copy;
    
    for (NSUInteger i = 0; i < argCount; i++)
    {
        free(argsC[i]);
    }
    free(argsC);
    
    return retval;
}

char* getAppUUIDPath(const char* path)
{
    if(!path) return NULL;

    char abspath[PATH_MAX];
    if(!realpath(path, abspath)) return NULL;

#define APP_PATH_PREFIX "/private/var/containers/Bundle/Application/"
    if(strncmp(abspath, APP_PATH_PREFIX, sizeof(APP_PATH_PREFIX)-1) != 0)
        return NULL;

    char* p1 = abspath + sizeof(APP_PATH_PREFIX)-1;
    char* p2 = strchr(p1, '/');
    if(!p2) return NULL;

    //is normal app or jailbroken app/daemon?
    if((p2 - p1) != (sizeof("xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx")-1))
        return NULL;
    
    *p2 = '\0';

    return strdup(abspath);
}

bool isRemovableBundlePath(const char* path)
{
    const char* uuidpath = getAppUUIDPath(path);
    if(!uuidpath) return false;
    free((void*)uuidpath);
    return true;
}

bool hasTrollstoreMarker(const char* path)
{
    char* uuidpath = getAppUUIDPath(path);
    if(!uuidpath) return false;

    char* markerpath=NULL;
    asprintf(&markerpath, "%s/_TrollStore", uuidpath);

    int ret = access(markerpath, F_OK);
    if(ret != 0) {
        free((void*)markerpath); markerpath = NULL;
        asprintf(&markerpath, "%s/_TrollStoreLite", uuidpath);
        ret = access(markerpath, F_OK);
    }

    free((void*)markerpath);
    free((void*)uuidpath);

    return ret==0;
}

#include <sys/sysctl.h>

int proc_pidpath(int pid, void * buffer, uint32_t  buffersize);

void killAllForBundle(const char* bundlePath)
{
    NSLog(@"killAllForBundle: %s", bundlePath);
    
    char realBundlePath[PATH_MAX+1];
    if(!realpath(bundlePath, realBundlePath))
        return;
    
    size_t realBundlePathLen = strlen(realBundlePath);
    if(realBundlePath[realBundlePathLen] != '/') {
        strcat(realBundlePath, "/");
        realBundlePathLen++;
    }

    int mib[3] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL};
    struct kinfo_proc *info;
    size_t length;
    size_t count;
    
    if (sysctl(mib, 3, NULL, &length, NULL, 0) < 0)
        return;
    if (!(info = malloc(length)))
        return;
    if (sysctl(mib, 3, info, &length, NULL, 0) < 0) {
        free(info);
        return;
    }
    count = length / sizeof(struct kinfo_proc);
    for (int i = 0; i < count; i++) {
        pid_t pid = info[i].kp_proc.p_pid;
        if (pid == 0) {
            continue;
        }
        
        char executablePath[PATH_MAX];
        if(proc_pidpath(pid, executablePath, sizeof(executablePath)) > 0) {
//            NSLog(@"executablePath [%d] %s", pid, executablePath);
            char realExecutablePath[PATH_MAX];
            if (realpath(executablePath, realExecutablePath)
                && strncmp(realExecutablePath, realBundlePath, realBundlePathLen) == 0) {
                int ret = kill(pid, SIGKILL);
                NSLog(@"killAllForBundle %s -> %d", realExecutablePath, ret);
            }
        }
    }
    free(info);
}

NSString* RootUserClearAppData(RHMInstalledAppInfo* app) {
    NSString* error=nil;
    NSString* result=nil;
    int ret = spawnRoot(NSBundle.mainBundle.executablePath, @[@"clearAppData", app.bundleIdentifier], &result, &error);
    if(ret != 0) {
        NSLog(@"removeItemAtPath failed: %@", error);
        return error;
    }
    return nil;
}

BOOL RootUserRemoveItemAtPath(NSString* path)
{
    NSString* error=nil;
    NSString* result=nil;
    int ret = spawnRoot(NSBundle.mainBundle.executablePath, @[@"removeItemAtPath", path], &result, &error);
    if(ret != 0) {
        NSLog(@"removeItemAtPath failed: %@", error);
        return NO;
    }
    return YES;
}

BOOL RootUserGetDirectoryContents(NSString* path, NSString* cacheFile)
{
    NSString* error=nil;
    NSString* result=nil;
    int ret = spawnRoot(NSBundle.mainBundle.executablePath, @[@"getDirectoryContents", path, cacheFile], &result, &error);
    if(ret != 0) {
        NSLog(@"getDirectoryContents failed: %@", error);
        return NO;
    }
    return YES;
}

BOOL RootUserRemountPreboot(void)
{
    NSString* error=nil;
    NSString* result=nil;
    int ret = spawnRoot(NSBundle.mainBundle.executablePath, @[@"remountPreboot"], &result, &error);
    if(ret != 0) {
        NSLog(@"remountPreboot failed: %@", error);
        return NO;
    }
    return YES;
}

static int getsvugid(uid_t* svuid, gid_t* svgid)
{
    uid_t uid = -1;
    gid_t gid = -1;
    struct kinfo_proc kinfo;
    u_int miblen = 4;
    size_t  len;
    int mib[miblen];
    int ret;
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    len = sizeof(struct kinfo_proc);
    ret = sysctl(mib, miblen, &kinfo, &len, NULL, 0);
    if (ret != 0) {
        uid = -1;
    } else {
        uid = kinfo.kp_eproc.e_pcred.p_svuid;
        gid = kinfo.kp_eproc.e_pcred.p_svgid;
    }
    if(svuid) *svuid = uid;
    if(svgid) *svgid = gid;
    return 0;
}
uid_t getsvuid() {
    uid_t uid = -1;
    getsvugid(&uid, NULL);
    return uid;
}
gid_t getsvgid(void) {
    gid_t gid = -1;
    getsvugid(NULL, &gid);
    return gid;
}

int main(int argc, char * argv[])
{
    NSLog(@"uid=%d euid=%d svuid=%d gid=%d egid=%d svgid=%d issetugid=%d", getuid(), geteuid(), getsvuid(), getgid(), getegid(), getsvgid(), issetugid());
    
    if(argc >= 2)
    {
        if(argc==3 && strcmp(argv[1], "removeItemAtPath")==0) {
            assert(geteuid()==0 && getegid()==0);
        
            NSError* err=nil;
            if(![NSFileManager.defaultManager removeItemAtPath:@(argv[2]) error:&err]) {
                fprintf(stderr, "%s", err.description.UTF8String);
                return -1;
            }
            return 0;
        }
        if(argc==4 && strcmp(argv[1], "getDirectoryContents")==0) {
            assert(geteuid()==0 && getegid()==0);
        
            NSArray* GetDirectoryContents(NSString* path);
            NSArray* contents = GetDirectoryContents(@(argv[2]));
            if(!contents) {
                return -1;
            }
            if(![contents writeToFile:@(argv[3]) atomically:YES]) {
                return -2;
            }
            return 0;
        }
        if(argc==3 && strcmp(argv[1], "clearAppData")==0) {
            assert(geteuid()==0 && getegid()==0);
        
            RHMInstalledAppInfo* app = [RHMInstalledAppInfo appWithBundleIdentifier:@(argv[2])];
            NSString* clearAppData(RHMInstalledAppInfo* app);
            NSString* error = clearAppData(app);
            if(error) {
                fprintf(stderr, "%s", error.UTF8String);
                return -1;
            }
            return 0;
        }
        if(argc==2 && strcmp(argv[1], "remountPreboot")==0) {
            assert(geteuid()==0 && getegid()==0);
        
            pid_t pid=0;
            char* args[] = {"/sbin/mount", "-u", "-w", "/private/preboot", NULL};
            posix_spawn(&pid, args[0], NULL, NULL, args, NULL);
            if(pid > 0) {
                int status=0;
                waitpid(pid, &status, 0);
            }
            return 0;
        }
    }
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
