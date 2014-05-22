#import "FMT.h"
#import "ShiftItConstants.h"

NSString *const mktrustedId = @"org.shiftitapp.mktrustedId";

BOOL mktrusted(NSError **error);

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSError *error = nil;
        if (!mktrusted(&error)) {
            NSLog(@"mktrusted: %@", error);
            return 1;
        }

    }

    return 0;
    
}

BOOL mktrusted(NSError **error) {
    if (geteuid() != 0) {
        *error = FMTCreateError(mktrustedId, 1, @"Not running as root");
        return NO;
    }

    NSString *sqlite = @"/usr/bin/sqlite3";
    // http://stackoverflow.com/questions/17693408/enable-access-for-assistive-devices-programmatically-on-10-9/18121292#18121292
    NSString *sql = FMTStr(@"INSERT or REPLACE INTO access values ('kTCCServiceAccessibility', '%@', 1, 1, 1, NULL);", kShiftItAppBundleId);
    NSArray *args = @[@"/Library/Application Support/com.apple.TCC/TCC.db", sql];
    NSTask *task = [NSTask launchedTaskWithLaunchPath:sqlite arguments:args];

    [task waitUntilExit];

    if ([task terminationStatus] != 0) {
        *error = FMTCreateError(mktrustedId, 1, @"Unable to execute: %@ %@", sqlite, args);
        return NO;
    }

    NSLog(@"mktrusted: Updated ShiftIt permissions");
    return YES;
}
