#ifndef DETECTION_H
#define DETECTION_H

#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <pthread.h>
#include <dirent.h>
#include <dlfcn.h>

extern char **environ;

// Function declarations now use BOOL (YES/NO)
BOOL detect_rootlessJB(void);
BOOL detect_kernBypass(void);
BOOL detect_chroot(void);
BOOL detect_mount_fs(void);
BOOL detect_bootstraps(void);
BOOL detect_trollStoredFilza(void);
BOOL detect_jailbreakd(void);
BOOL detect_proc_flags(void);
BOOL detect_jb_payload(void);
BOOL detect_exception_port(void);
BOOL detect_jb_preboot(void);
BOOL detect_jailbroken_apps(void);
BOOL detect_removed_varjb(void);
BOOL detect_fugu15Max(void);
BOOL detect_url_schemes(void);
BOOL detect_jbapp_plugins(void);
BOOL detect_jailbreak_sigs(void);
BOOL detect_jailbreak_port(void);
BOOL detect_launchd_jbserver(void);
BOOL detect_trollstore_app(void);
BOOL detect_passcode_status(void);

// Aggregator helper function
BOOL isJailbroken(void);



// Helper function declarations
kern_return_t bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t *sp);

int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

#endif /* DETECTION_H */
