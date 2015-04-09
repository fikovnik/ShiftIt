/*
 Copyright (c) 2010-2011 Filip Krikava

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

// following assertions were taken from: GMTDefines.h from the google-mac-toolbox:
// http://code.google.com/p/google-toolbox-for-mac/

#import <Foundation/Foundation.h>
#import "GTMLogger.h"

// collections
#define FMT_A(...) [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define FMT_D(...) [NSDictionary dictionaryWithObjectsAndKeys:__VA_ARGS__, nil]

// logging
#define FMTLogDebug(...)  \
[[GTMLogger sharedLogger] logFuncDebug:__func__ msg:__VA_ARGS__]
#define FMTLogInfo(...)   \
[[GTMLogger sharedLogger] logFuncInfo:__func__ msg:__VA_ARGS__]
#define FMTLogError(...)  \
[[GTMLogger sharedLogger] logFuncError:__func__ msg:__VA_ARGS__]
#define FMTLogAssert(...) \
[[GTMLogger sharedLogger] logFuncAssert:__func__ msg:__VA_ARGS__]

// strings
static inline NSString* FMTStr(NSString *fmt, ...) {
    NSString *s;
    va_list args;

    va_start(args, fmt);
	s = [[[NSString alloc] initWithFormat:fmt arguments:args] autorelease];
    va_end(args);

    return s;
}

#define FMTStrc(cstr) [NSString stringWithCString:(cstr) encoding:NSUTF8StringEncoding]

// debug blocks
typedef void (^FMTDebugBlock)(void);
static inline void FMTInDebugOnly(FMTDebugBlock block) {
#ifndef NDEBUG
  block();
#endif
}

#ifndef FMTAssert
  #if !defined(NS_BLOCK_ASSERTIONS)
    #define FMTAssert(condition, ...)                                       \
      do {                                                                      \
        if (!(condition)) {                                                     \
          [[NSAssertionHandler currentHandler]                                  \
              handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
                                 file:[NSString stringWithUTF8String:__FILE__]  \
                           lineNumber:__LINE__                                  \
                          description:__VA_ARGS__];                             \
        }                                                                       \
      } while(0)
  #else // !defined(NS_BLOCK_ASSERTIONS)
    #define FMTAssert(condition, ...) do { } while (0)
  #endif // !defined(NS_BLOCK_ASSERTIONS)
#endif // FMTAssert

#ifndef FMTFail
  #define FMTFail(...) FMTAssert(NO,##__VA_ARGS__)
#endif // FMTFail

#ifndef FMTAssertNotNil
  #define FMTAssertNotNil(var) FMTAssert(var != nil, @"Variable %@ must not be nil", @#var);
#endif // FMTAssertNotNil

/// This macro implements the various methods needed to make a safe singleton.
///
/// This Singleton pattern was taken from:
/// http://developer.apple.com/documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaObjects/chapter_3_section_10.html
///
/// Sample usage:
///
/// SINGLETON_BOILERPLATE(SomeUsefulManager, sharedSomeUsefulManager)
/// (with no trailing semicolon)
///
/// This code here is based on Foundation/GTMObjectSingleton.h from google-toolbox-for-mac
///

#ifndef SINGLETON_BOILERPLATE

#define SINGLETON_BOILERPLATE(_object_name_, _shared_obj_name_) SINGLETON_BOILERPLATE_FULL(_object_name_, _shared_obj_name_, init)

#endif // SINGLETON_BOILERPLATE

#ifndef SINGLETON_BOILERPLATE_FULL

#define SINGLETON_BOILERPLATE_FULL(_object_name_, _shared_obj_name_, _init_) \
static _object_name_ *z##_shared_obj_name_ = nil;  \
+ (_object_name_ *)_shared_obj_name_ {             \
@synchronized(self) {                            \
if (z##_shared_obj_name_ == nil) {             \
/* Note that 'self' may not be the same as _object_name_ */                               \
/* first assignment done in allocWithZone but we must reassign in case init fails */      \
z##_shared_obj_name_ = [[self alloc] _init_];                                               \
FMTAssert((z##_shared_obj_name_ != nil), @"didn't catch singleton allocation");       \
}                                              \
}                                                \
return z##_shared_obj_name_;                     \
}                                                  \
+ (id)allocWithZone:(NSZone *)zone {               \
@synchronized(self) {                            \
if (z##_shared_obj_name_ == nil) {             \
z##_shared_obj_name_ = [super allocWithZone:zone]; \
return z##_shared_obj_name_;                 \
}                                              \
}                                                \
\
/* We can't return the shared instance, because it's been init'd */ \
FMTAssert(NO, @"use the singleton API, not alloc+init");        \
return nil;                                      \
}                                                  \
- (id)retain {                                     \
return self;                                     \
}                                                  \
- (NSUInteger)retainCount {                        \
return NSUIntegerMax;                            \
}                                                  \
- (id)autorelease {                                \
return self;                                     \
}                                                  \
- (id)copyWithZone:(NSZone *) __unused zone { \
return self;                                     \
}                                                  \

#endif // SINGLETON_BOILERPLATE_FULL
