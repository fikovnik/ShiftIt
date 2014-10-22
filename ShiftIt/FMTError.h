//
// Created by Filip Krikava on 21/05/2014.
//

#import <Foundation/Foundation.h>
#import "FMT.h"

NSError* FMTCreateError(NSString *errorDomain, NSInteger errorCode, NSString *fmt, ...);
NSError* FMTCreateErrorWithCause(NSString *errorDomain, NSInteger errorCode, NSError *cause, NSString *fmt, ...);