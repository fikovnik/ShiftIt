//
//  Copyright 2012 ShortcutRecorder Contributors
//  CC BY 4.0
//

#import <Cocoa/Cocoa.h>
#import <ShortcutRecorder/SRCommon.h>


NS_ASSUME_NONNULL_BEGIN

/*!
 Don't use directly, use SRLiteralKeyCodeTransformer / SRSymbolicKeyCodeTransformer / SRLiteralKeyCodeTransformer / SRSymbolicKeyCodeTransformer instead.
 */
NS_SWIFT_UNAVAILABLE("use SRLiteralKeyCodeTransformer / SRSymbolicKeyCodeTransformer / SRLiteralKeyCodeTransformer / SRSymbolicKeyCodeTransformer instead")
@interface SRKeyCodeTransformer : NSValueTransformer
/*!
 Shared transformer.

 @discussion
 Shared transformers use autoupdating input source.
 */
@property (class, readonly) SRKeyCodeTransformer *sharedTransformer NS_SWIFT_NAME(shared);

/*!
 List of the known and expected key codes.

 @discussion
 Behavior for unknown key codes may be inconsistent.
 */
@property (class, readonly) NSArray<NSNumber *> *knownKeyCodes;

/*!
 The input source used by the transformer.

 @discussion
 The underlying type is TISInputSourceRef.

 @note Shared transformers autoupdate their input sources to the current, thus returned value may not be persistent.
 */
@property (readonly) id inputSource;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithInputSource:(id)anInputSource NS_DESIGNATED_INITIALIZER;

/*!
 Return literal string for the given key code, modifier flags and layout direction.
 */
- (nullable NSString *)literalForKeyCode:(SRKeyCode)aValue
               withImplicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
                   explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                         layoutDirection:(NSUserInterfaceLayoutDirection)aDirection;

/*!
 Return symbolic string for the given key code, modifier flags and layout direction.
 */
- (nullable NSString *)symbolForKeyCode:(SRKeyCode)aValue
              withImplicitModifierFlags:(NSEventModifierFlags)anImplicitModifierFlags
                  explicitModifierFlags:(NSEventModifierFlags)anExplicitModifierFlags
                        layoutDirection:(NSUserInterfaceLayoutDirection)aDirection;

/*!
 Transfrom the given key code into a symbol or a literal by taking into account modifier flags and layout direction.

 @param aValue The key code.

 @param anImplicitModifierFlags The implicit modifier flags like Option in å in the U.S. English input source.

 @param anExplicitModifierFlags The explicit modifier flags like Shift in Shift-⇥.

 @param aDirection The layout direction to select an appropriate symbol or literal.
 */
- (nullable NSString *)transformedValue:(nullable NSNumber *)aValue
              withImplicitModifierFlags:(nullable NSNumber *)anImplicitModifierFlags
                  explicitModifierFlags:(nullable NSNumber *)anExplicitModifierFlags
                        layoutDirection:(NSUserInterfaceLayoutDirection)aDirection;

- (nullable NSString *)transformedValue:(nullable NSNumber *)aValue;
- (nullable NSNumber *)reverseTransformedValue:(nullable NSString *)aValue;

@end


/*!
 Transformer a key code into a literal in the current input source.
 */
NS_SWIFT_NAME(LiteralKeyCodeTransformer)
@interface SRLiteralKeyCodeTransformer : SRKeyCodeTransformer
@end


/*!
 Transform a key code into a symbol in the current input source.
 */
NS_SWIFT_NAME(SymbolicKeyCodeTransformer)
@interface SRSymbolicKeyCodeTransformer : SRKeyCodeTransformer
@end


/*!
 Transformer a key code into a literal in the current ASCII-capable input source.

 @note Allows reverse transformation.
 */
NS_SWIFT_NAME(ASCIILiteralKeyCodeTransformer)
@interface SRASCIILiteralKeyCodeTransformer : SRKeyCodeTransformer
@end


/*!
 Transform a key code into a symbol in the current ASCII-capable input source.

 @note Allows reverse transformation.
 */
NS_SWIFT_NAME(ASCIISymbolicKeyCodeTransformer)
@interface SRASCIISymbolicKeyCodeTransformer : SRKeyCodeTransformer
@end

NS_ASSUME_NONNULL_END
