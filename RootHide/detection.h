#ifndef DETECTION_H
#define DETECTION_H

#import <UIKit/UIKit.h>
#include <mach/mach.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <pthread.h>
#include <dirent.h>
#include <dlfcn.h>

extern char** environ;

// Macro for logging
#define LOG(...) printf(__VA_ARGS__)

// Function declarations
void detect_rootlessJB(void);
void detect_kernBypass(void);
void detect_chroot(void);
void detect_mount_fs(void);
void detect_bootstraps(void);
void detect_trollStoredFilza(void);
void detect_jailbreakd(void);
void detect_proc_flags(void);
void detect_jb_payload(void);
void detect_exception_port(void);
void detect_jb_preboot(void);
void detect_jailbroken_apps(void);
void detect_removed_varjb(void);
void detect_fugu15Max(void);
void detect_url_schemes(void);
void detect_jbapp_plugins(void);
void detect_jailbreak_sigs(void);
void detect_jailbreak_port(void);
void detect_launchd_jbserver(void);
BOOL detect_trollstpre_app();
void detect_passcode_status(void);

// Helper function declarations
kern_return_t bootstrap_look_up(mach_port_t bp, const char* service_name, mach_port_t *sp);
mach_port_t connect_mach_service(const char *name);
int csops(pid_t pid, unsigned int ops, void * useraddr, size_t usersize);

#endif /* DETECTION_H */
