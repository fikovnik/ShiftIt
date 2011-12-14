//
//  Created by krikava on 14/12/11.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import "SIScreen.h"

@protocol SIWindow <NSObject>

@required

/**
 * @param geometry a pointer to a NSRect where the current geometry of a window will be stored. It can be nil in which case no information will be stored.
 * @param screen a pointer to a SIScreen where the current screen of a window will be stored. It can be nil in which case no information will be stored.
 * @param shall there be a problem obtaining the window geometry information the cause will be stored in this pointer if it is not nil.
 *
 * @returns YES on success, NO otherwise while setting the error parameter
 */
- (BOOL) getGeometry:(NSRect *)geometry screen:(SIScreen **)screen error:(NSError **)error;
- (BOOL) setGeometry:(NSRect)geometry screen:(SIScreen *)screen error:(NSError **)error;
- (BOOL) canMove:(BOOL *)flag error:(NSError **)error;
- (BOOL) canResize:(BOOL *)flag error:(NSError **)error;
- (BOOL) canZoom:(BOOL *)flag error:(NSError **)error;
- (BOOL) canEnterFullScreen:(BOOL *)flag error:(NSError **)error;

@optional
- (BOOL) getWindowRect:(NSRect *)windowRect screen:(SIScreen **)screen drawersRect:(NSRect *)drawersRect error:(NSError **)error;
- (BOOL) getFullScreen:(BOOL *)flag error:(NSError **)error;
- (BOOL) toggleFullScreen:(NSError **)error;
- (BOOL) toggleZoom:(NSError **)error;

@end