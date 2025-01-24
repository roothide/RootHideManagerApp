#ifndef JBROOT_H
#define JBROOT_H

#import <Foundation/Foundation.h>

// Function to resolve paths relative to the jailbreak root (NSString* version)
NSString* _Nonnull __attribute__((overloadable)) jbroot(NSString* _Nonnull path);

// Function to resolve paths relative to the jailbreak root (const char* version)
const char* __attribute__((overloadable)) jbroot(const char* path);

#endif /* JBROOT_H */
