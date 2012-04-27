 #import <IOKit/graphics/IOGraphicsLib.h>
 #import "NSScreen+DisplayName.h"
 
 @implementation NSScreen (DisplayName)
 
 - (NSString *)displayName {
     NSString *screenName = nil;
 
     io_service_t framebuffer = CGDisplayIOServicePort([[[self deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue]);
     NSDictionary *deviceInfo = (NSDictionary *)IODisplayCreateInfoDictionary(framebuffer, kIODisplayOnlyPreferredName);
     NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
 
     if ([localizedNames count] > 0) {
         screenName = [[localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]] retain];
     }
     else {
         screenName = @"Unknown";
     }
 
     [deviceInfo release];
     return [screenName autorelease];    
 }
 
 @end