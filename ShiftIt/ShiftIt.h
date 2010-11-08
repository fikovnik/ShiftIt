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

extern NSString *const kShiftItAppBundleId;

// indexed using the ShiftItAction identifier
extern NSDictionary *allShiftActions;

extern NSString *const kShiftItUserDefaults;

extern NSString *const kKeyCodePrefKeySuffix;
extern NSString *const kModifiersPrefKeySuffix;

// preferences keys
extern NSString *const kHasStartedBeforePrefKey;
extern NSString *const kShowMenuPrefKey;

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

extern NSString *const SIErrorDomain;
extern NSInteger const kUnableToGetActiveWindowErrorCode;
extern NSInteger const kUnableToChangeWindowPositionErrorCode;
extern NSInteger const kUnableToGetWindowGeometryErrorCode;
extern NSInteger const kUnableToChangeWindowSizeErrorCode;

#define KeyCodePrefKey(identifier) FMTStr(@"%@%@", (identifier), kKeyCodePrefKeySuffix)
#define ModifiersPrefKey(identifier) FMTStr(@"%@%@", (identifier), kModifiersPrefKeySuffix)

extern NSError* SICreateError(NSString *localizedDescription, NSInteger errorCode);