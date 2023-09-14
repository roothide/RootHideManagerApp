#ifndef ROOTHIDE_H
#define ROOTHIDE_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
#include <string>
#endif

#ifdef __OBJC__
#import <Foundation/NSString.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

const char* rootfs_alloc(const char* path);  /* free after use */
const char* jbroot_alloc(const char* path); /* free after use */
const char* jbrootat_alloc(int fd, const char* path); /* free after use */

//

/* get the system-wide random value of current jailbreak state */
unsigned long long jbrand();

/* convert jbroot-based path to rootfs-based path (auto cache) */
const char* jbroot(const char* path);

/* convert rootfs-based path to jbroot-based path (auto cache) */
const char* rootfs(const char* path);

#ifdef __OBJC__
NSString* __attribute__((overloadable)) jbroot(NSString* path);
NSString* __attribute__((overloadable)) rootfs(NSString* path);
#endif

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
std::string jbroot(std::string path);
std::string rootfs(std::string path);
#endif

#endif /* ROOTHIDE_H */
