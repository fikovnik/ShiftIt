/*
 Copyright (c) 2010 Filip Krikava
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this sofFMTare and associated documentation files (the "SofFMTare"), to deal
 in the SofFMTare without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the SofFMTare, and to permit persons to whom the SofFMTare is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the SofFMTare.
 
 THE SOFFMTARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFFMTARE OR THE USE OR OTHER DEALINGS IN
 THE SOFFMTARE.
 */

// following assertions were taken from: GMTDefines.h from the google-mac-toolbox:
// http://code.google.com/p/google-toolbox-for-mac/

#ifndef FMTDevLog

#ifndef NDEBUG
#define FMTDevLog(...) NSLog(__VA_ARGS__)
#else
#define FMTDevLog(...) do { } while (0)
#endif // NDEBUG

#endif // FMTDevLog

// TODO: rename to NSStr
#ifndef FMTStr
#define FMTStr(fmt,...) [NSString stringWithFormat:fmt,##__VA_ARGS__]
#endif // FMTStr

#define FMTStrc(cstr) [NSString stringWithCString:(cstr) encoding:NSUTF8StringEncoding] 

#ifndef FMTTraceLog

#ifndef NTRACE
#define FMTTraceLog(...) NSLog(@"%@: %@",FMTStr(@"[\%s:\%s:\%d]",__PRETTY_FUNCTION__,__FILE__,__LINE__),FMTStr(__VA_ARGS__))
#define FMTTrace() NSLog(@"[\%s:\%s:\%d]",__PRETTY_FUNCTION__,__FILE__,__LINE__)
#endif // NTRACE

#endif // FMTTraceLog

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

#define FMTAssertNotNil(var) FMTAssert(var != nil, FMTStr(@"Variabe %@ must not be nil", @#var));

#else // !defined(NS_BLOCK_ASSERTIONS)
#define FMTAssert(condition, ...) do { } while (0)
#endif // !defined(NS_BLOCK_ASSERTIONS)

#endif // FMTAssert

#ifndef FMTFail

#define FMTFail(...) FMTAssert(NO,##__VA_ARGS__)

#endif // FMTFail


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
- (void)release {                                  \
}                                                  \
- (id)autorelease {                                \
return self;                                     \
}                                                  \
- (id)copyWithZone:(NSZone *) __unused zone { \
return self;                                     \
}                                                  \

#endif // SINGLETON_BOILERPLATE_FULL

#ifndef FMTGetErrorDescription
#define FMTGetErrorDescription(error)	[[(error) userInfo] objectForKey:NSLocalizedDescriptionKey]
#endif // FMTGetErrorDescription
