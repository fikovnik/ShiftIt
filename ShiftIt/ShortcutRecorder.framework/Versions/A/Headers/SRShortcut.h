//
//  Copyright 2018 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRKeyCodeTransformer.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 @enum SRShortcutKey

 @discussion Keys of the dictionary that represents shortcut.
 */
typedef NSString *SRShortcutKey NS_TYPED_EXTENSIBLE_ENUM NS_SWIFT_NAME(ShortcutKey);

/*!
 @seealso SRShortcut/code
 */
extern SRShortcutKey const SRShortcutKeyKeyCode;

/*!
 @seealso SRShortcut/modifierFlags
 */
extern SRShortcutKey const SRShortcutKeyModifierFlags;

/*!
 @seealso SRShortcut/characters
 */
extern SRShortcutKey const SRShortcutKeyCharacters;

/*!
 @seealso SRShortcut/charactersIgnoringModifiers
 */
extern SRShortcutKey const SRShortcutKeyCharactersIgnoringModifiers;


/*!
 Combination of a key code, modifier flags and optionally their characters
 representation at the time of recording.

 @note KVC access is compatible with ShortcutRecorder 2

 @note Two shortcuts are considered equal if their code and modifier flags match.
 */
NS_SWIFT_NAME(Shortcut)
@interface SRShortcut : NSObject <NSCopying, NSSecureCoding>

/*!
 @seealso SRShortcut/initWithCode:modifierFlags:characters:charactersIgnoringModifiers:
 */
+ (instancetype)shortcutWithCode:(SRKeyCode)aKeyCode
                   modifierFlags:(NSEventModifierFlags)aModifierFlags
                      characters:(nullable NSString *)aCharacters
     charactersIgnoringModifiers:(nullable NSString *)aCharactersIgnoringModifiers;

/*!
 Initialize the shortcut with a keyboard event.

 @seealso SRShortcut/shortcutWithEvent:ignoringCharacters:
 */
+ (nullable instancetype)shortcutWithEvent:(NSEvent *)aKeyboardEvent;

/*!
 Initialize the shortcut with a keyboard event without wasting resources to generate characters.

 @discussion
 AppKit generates characters upon first request which is a waste of resources
 when you know exactly that they are not needed, e.g. when used together with SRShortcutAction.

 In addition, AppKit currently throws an exception if the characters property is accessed
 outside of the main thread.
 */
+ (nullable instancetype)shortcutWithEvent:(NSEvent *)aKeyboardEvent ignoringCharacters:(BOOL)aShouldIgnoreCharacters;

/*!
 Initialize the shortcut with a dictionary.

 @note Compatible with Shortcut Recorder 2 shortcuts.

 @seealso SRShortcutKey
 */
+ (nullable instancetype)shortcutWithDictionary:(NSDictionary *)aDictionary;

/*!
 Initialize the shortcut from a left-to-right ASCII key code and symbolic modifier flags e.g. @"⇧⌘A".
 */
+ (nullable instancetype)shortcutWithKeyEquivalent:(NSString *)aKeyEquivalent;

/*!
 Initialize the shortcut from a Cocoa Text system key binding.

 @seealso https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TextDefaultsBindings/TextDefaultsBindings.html
 */
+ (nullable instancetype)shortcutWithKeyBinding:(NSString *)aKeyBinding;

+ (instancetype)new NS_UNAVAILABLE;

/*!
 Designated initializer.

 @param aKeyCode A key code such as 0 ('a').

 @param aModifierFlags Modifier flags such as NSEventModifierFlagCommand.

 @param aCharacters Representation of the key code with modifier flags.

 @param aCharactersIgnoringModifiers Representation of the key code without modifier flags.

 @discussion
 If aCharacters is nil, an attempt is made to translate the given key code and modifier flags
 using SRASCIISymbolicKeyCodeTransformer. Similarly for aCharactersIgnoringModifiers.
 */
- (instancetype)initWithCode:(SRKeyCode)aKeyCode
               modifierFlags:(NSEventModifierFlags)aModifierFlags
                  characters:(nullable NSString *)aCharacters
 charactersIgnoringModifiers:(nullable NSString *)aCharactersIgnoringModifiers NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/*!
 A key code such as 0 ('a').
 */
@property (readonly) SRKeyCode keyCode;

/*!
 Modifier flags such as NSEventModifierFlagCommand | NSEventModifierFlagOption.
 */
@property (readonly) NSEventModifierFlags modifierFlags;

/*!
 Representation of the key code with modifier flags.

 @discussion
 Returned value depends on system's locale and the active input source
 at the time when the shortcut was initialized:

 - A non-empty string that was either specified by the user or recovered from keyCode and modifierFlags

 - An empty string that was either specified by the user or if keyCode equals SRKeyCodeNone

 - nil if it was impossible to recover charaters for keyCode and modifierFlags with system's locale
   and active input source

 @note Does not participate in the equality test.
 */
@property (nullable, readonly) NSString *characters;

/*!
 Representation of the key code without modifier flags.

 @discussion
 Returned value depends on system's locale and the active input source
 at the time when the shortcut was initialized:

 - A non-empty string that was either specified by the user or recovered from the keyCode and modifierFlags

 - An empty string that was either specified by the user or if keyCode equals SRKeyCodeNone

 - nil if it was impossible to recover charaters for keyCode and modifierFlags with system's locale
   and active input source

 @note Does not participate in the equality test.
 */
@property (nullable, readonly) NSString *charactersIgnoringModifiers;

/*!
 Dictionary representation of the shortcut. Compatible with ShortcutRecorer 2

 @seealso SRShortcutKey
 */
@property (readonly) NSDictionary<SRShortcutKey, id> *dictionaryRepresentation;

/*!
 Return readable representation of the shortcut for user dialogs or accessibility.

 @param isASCII Same key code can refer to different characters depending on the input source.
                If isASCII is NO then the active input source is used. If it's YES ASCII input source is used.
                Pass YES for consistent results.
 */
- (NSString *)readableStringRepresentation:(BOOL)isASCII NS_SWIFT_NAME(readableStringRepresentation(isASCII:));

/*!
 Compare the shortcut to another shortcut.

 @discussion Override to compare properties of the receiver against another shortcut only.
 */
- (BOOL)isEqualToShortcut:(SRShortcut *)aShortcut;

/*!
 Compare the shortcut to a dictionary representation.

 @seealso dictionaryRepresentation
 */
- (BOOL)isEqualToDictionary:(NSDictionary<SRShortcutKey, id> *)aDictionary NS_SWIFT_NAME(isEqual(dictionary:));

/*!
 Compare the shortcut to Cocoa's key equivalent and modifier flags using the current input source.
 */
- (BOOL)isEqualToKeyEquivalent:(nullable NSString *)aKeyEquivalent
             withModifierFlags:(NSEventModifierFlags)aModifierFlags NS_SWIFT_NAME(isEqual(keyEquivalent:modifierFlags:));

/*!
 Compare the shortcut to Cocoa's key equivalent and modifier flags using the given key code transformer.
 */
- (BOOL)isEqualToKeyEquivalent:(NSString *)aKeyEquivalent
             withModifierFlags:(NSEventModifierFlags)aModifierFlags
              usingTransformer:(SRKeyCodeTransformer *)aTransformer NS_SWIFT_NAME(isEqual(keyEquivalent:modifierFlags:transformer:));


/*!
 Dictionary-like access to properties.

 @seealso SRShortcutKey
 */
- (nullable id)objectForKeyedSubscript:(SRShortcutKey)aKey;

@end


/*!
 Carbon versions of key code and modifier flags.
 */
@interface SRShortcut (Carbon)

@property (readonly) UInt32 carbonKeyCode;

@property (readonly) UInt32 carbonModifierFlags;

@end

NS_ASSUME_NONNULL_END
