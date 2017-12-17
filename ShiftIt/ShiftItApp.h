/*
 ShiftIt: Window Organizer for OSX
 Copyright (c) 2010-2011 Filip Krikava
 
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

#import "FMT.h"
#import "ShiftIt.h"

extern NSString *const kShiftItAppBundleId;

// indexed using the ShiftItAction identifier
extern NSDictionary *allShiftActions;

extern NSString *const kShiftItUserDefaults;

extern NSString *const kKeyCodePrefKeySuffix;
extern NSString *const kModifiersPrefKeySuffix;

// preferences keys
extern NSString *const kHasStartedBeforePrefKey;
extern NSString *const kShowMenuPrefKey;
extern NSString *const kSizeDeltaTypePrefKey;
extern NSString *const kFixedSizeWidthDeltaPrefKey;
extern NSString *const kFixedSizeHeightDeltaPrefKey;
extern NSString *const kWindowSizeDeltaPrefKey;
extern NSString *const kScreenSizeDeltaPrefKey;
extern NSString *const kAXIncludeDrawersPrefKey;
extern NSString *const kAXDriverConvergePrefKey;
extern NSString *const kMutipleActionsCycleWindowSizes;

typedef enum {
	kFixedSizeDeltaType = 3001,
	kWindowSizeDeltaType = 3002,
	kScreenSizeDeltaType = 3003
} SizeDeltaType;

// distributed notifications
extern NSString *const kShowPreferencesRequestNotification;

// local notifications
extern NSString *const kDidFinishEditingHotKeysPrefNotification;
extern NSString *const kDidStartEditingHotKeysPrefNotification;
extern NSString *const kHotKeyChangedNotification;

// kHotKeyChangedNotification userInfo keys
extern NSString *const kActionIdentifierKey;
extern NSString *const kHotKeyKeyCodeKey;
extern NSString *const kHotKeyModifiersKey;

extern NSInteger const kSIMenuUITagPrefix;
extern NSInteger const kSISRUITagPrefix;

extern NSString *const kSIIconName;
extern NSString *const kSIIconType;
extern NSString *const kSIMenuItemTitle;

extern NSString *const SIAErrorDomain;

@interface ShiftItAction : NSObject {
 @private
	NSString *identifier_;
	NSString *label_;
	NSInteger uiTag_;
    id<SIActionDelegate> delegate_;
}

@property (readonly) NSString *identifier;
@property (readonly) NSString *label;
@property (readonly) NSInteger uiTag;
@property (readonly) id<SIActionDelegate> delegate;

- (id) initWithIdentifier:(NSString *)identifier label:(NSString *)label uiTag:(NSInteger)uiTag delegate:(id <SIActionDelegate>)delegate;

@end

#define KeyCodePrefKey(identifier) FMTStr(@"%@%@", (identifier), kKeyCodePrefKeySuffix)
#define ModifiersPrefKey(identifier) FMTStr(@"%@%@", (identifier), kModifiersPrefKeySuffix)

#define SIACreateError(errorCode, fmt, ...) FMTCreateError(SIAErrorDomain, errorCode, fmt, __VA_ARGS__)
#define SIACreateErrorWithCause(errorCode, cause, fmt, ...) FMTCreateErrorWithCause(SIAErrorDomain, errorCode, cause, fmt, __VA_ARGS__)
