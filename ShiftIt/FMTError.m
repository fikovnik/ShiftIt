//
// Created by Filip Krikava on 21/05/2014.
//

#import "FMTError.h"

NSError* FMTCreateErrorWithCause_(NSString *errorDomain, NSInteger errorCode, NSError *cause, NSString *fmt, va_list args);

inline NSError* FMTCreateError(NSString *errorDomain, NSInteger errorCode, NSString *fmt, ...) {
    NSError *error;
    va_list args;

    va_start(args, fmt);
    error = FMTCreateErrorWithCause_(errorDomain, errorCode, nil, fmt, args);
    va_end(args);

    return error;
}

inline NSError* FMTCreateErrorWithCause(NSString *errorDomain, NSInteger errorCode, NSError *cause, NSString *fmt, ...) {
    NSError *error;
    va_list args;

    va_start(args, fmt);
    error = FMTCreateErrorWithCause_(errorDomain, errorCode, cause, fmt, args);
    va_end(args);

    return error;
}

inline NSError* FMTCreateErrorWithCause_(NSString *errorDomain, NSInteger errorCode, NSError *cause, NSString *fmt, va_list args) {
    FMTAssertNotNil(fmt);

    NSString *msg = [[[NSString alloc] initWithFormat:fmt arguments:args] autorelease];

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
    [userInfo setObject:msg forKey:NSLocalizedDescriptionKey];
    if (cause != nil) {
        [userInfo setObject:cause forKey:NSUnderlyingErrorKey];
    }

    NSError *error = [NSError errorWithDomain:errorDomain code:errorCode userInfo:userInfo];
    return error;
}