#import "SIWindow.h"

@protocol SIWindowContext <NSObject>

@required
- (BOOL) getFocusedWindow:(id<SIWindow> *)window error:(NSError **)error;
- (BOOL) anchorWindow:(id<SIWindow>)window error:(NSError **)error;
- (void) getAnchorMargins:(int *)leftMargin topMargin:(int *)topMargin bottomMargin:(int *)bottomMargin rightMargin:(int *)rightMargin;
@end