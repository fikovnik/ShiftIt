/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Filip Krikava
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */

#import <Foundation/Foundation.h>

#define HANDLE_WM_ERROR_LONG(error,localError,errCode,description) \
if ((localError)) { \
*(error) = CreateError((errCode), (description), (localError)); \
return NO; \
}

#define HANDLE_WM_ERROR(error,localError) \
if ((localError)) { \
*(error) = (localError); \
return NO; \
}

#define GET_FOCUSED_WINDOW(focusedWindowm, windowManager, error, localError) \
[(windowManager) focusedWindow:&(focusedWindow) error:&(localError)]; \
HANDLE_WM_ERROR((error), (localError)); \
if (!(focusedWindow)) { \
return NO; \
} \

@class WindowManager;

@protocol ShiftItActionDelegate

@required
- (BOOL) executeWithWindowManager:(WindowManager *)windowManager error:(NSError **)error;

@end


@interface ShiftItAction : NSObject {
 @private
	NSString *identifier_;
	NSString *label_;
	NSInteger uiTag_;
	NSObject<ShiftItActionDelegate> *delegate_;
}

@property (readonly) NSString *identifier;
@property (readonly) NSString *label;
@property (readonly) NSInteger uiTag;
@property (readonly) NSObject<ShiftItActionDelegate> *delegate;

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag delegate:(NSObject<ShiftItActionDelegate> *)delegate;

@end
