/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

@import Foundation;



@protocol HPNExtender <NSObject>
@required

/* Called when the extender is added to the extended object. Can be called more
 * than once on an extender instance if the extender is added on more than one
 * object, or is added then removed then re-added to/from/to an object.
 * Must return NO if the extender cannot be added to the object. */
- (BOOL)prepareObjectForExtender:(NSObject *)object;
/* Called, when the extender is removed from the extended object */
- (void)prepareObjectForRemovalOfExtender:(NSObject *)object;

@end



/* Use HELPTENDER_CALL_SUPER_* macros (see HPNHelptenderUtils.h) to call super
 * in a helptender. Do *NOT* call [super method]. Ever. */

@protocol HPNHelptender <NSObject>
@required

/* Called the first time a runtime-generated helptender class replaces the
 * runtime class of an object.
 * This is a good place to init the helptender. */
+ (void)hpn_helptenderHasBeenAdded:(NSObject <HPNHelptender> *)helptender;
/* Called when the helptender will be removed from an extended object (because
 * no more extenders are using the helptender).
 * This is the place to remove everything your helptender used in the object.
 * This will *always* be called _before_ the actual object reaches dealloc. */
+ (void)hpn_helptenderWillBeRemoved:(NSObject <HPNHelptender> *)helptender;

@end



/* WARNING: Adding/removing an extender is *not* thread-safe. */
@interface NSObject (eXtenderZ)

/* Must be called in the +load method of any extender helper (helptender) class.
 * protocol must conform to protocol HPNExtender, the registered class must
 * respond to protocol HPNHelptender. */
+ (BOOL)hpn_registerClass:(Class)c asHelptenderForProtocol:(Protocol *)protocol;



- (BOOL)hpn_isExtended;
/* Returns all of the extenders that have been added to the object in the order
 * they have been added.
 * Might return nil if there were no extenders added to the object. */
- (NSArray *)hpn_extenders;
- (NSArray *)hpn_extendersConformingToProtocol:(Protocol *)p; /* Cached, don't worry about performance. */
/* This method is the only way to add an extender to an object. It returns YES
 * if the extender was added, NO if it was not (the extender refused to be added
 * or it was already added to the object).
 *
 * The protocols to which the extender responds to will determine which
 * helptenders will be added to the object.
 *
 * IMPORTANT NOTE: All added extenders are removed from the object just the
 *                 moment _before_ dealloc is called. Do *not* try to access
 *                 extensions properties or call extensions methods in dealloc!
 *                 You can however _prepare_ the deallocation of said object by
 *                 overriding hpn_prepareDeallocationOfExtendedObject. You must
 *                 call super when overriding this method. It is called when the
 *                 object is being dealloced, _before_ the extenders are removed
 *                 from the object.
 *
 * This method should not be overridden (it might be called twice for the same
 * extender). If you want to be called when an extender is added to an object,
 * see hpn_prepareForExtender: */
- (BOOL)hpn_addExtender:(NSObject <HPNExtender> *)extender;
/* Removes given extender. Returns YES if found (and removed), NO if not.
 * This method cannot fail.
 * It shouldn't be overridden (override hpn_removeExtender:atIndex: instead). */
- (BOOL)hpn_removeExtender:(NSObject <HPNExtender> *)extender;
/* Removes the extenders in the given array, returns the number of extenders
 * actually removed. */
- (NSUInteger)hpn_removeExtenders:(NSArray *)extenders;
/* Removes all extenders with a given class from the extended object. Returns
 * the number of extenders removed.
 * It shouldn't be overridden (override hpn_removeExtender:atIndex:). */
- (NSUInteger)hpn_removeExtendersOfClass:(Class <HPNExtender>)extenderClass;
/* Removes all of the extenders of the object. Returns the number of extenders
 * removed (always equal to the number of extenders there was on the object). */
- (NSUInteger)hpn_removeAllExtenders;

/* Called in hpn_addExtender:, _after_ the helptender(s) have been added to the
 * object. Returns YES if the preparation was successful, NO otherwise (in which
 * case the addition of the extender is cancelled).
 *
 * Do NOT call this method directly.
 * However, you can override the method. You must check whether calling super
 * (don't forget to use HELPTENDER_CALL_SUPER_* methods to call super) returns
 * YES or NO. If it returns NO, you must return NO right away. */
- (BOOL)hpn_prepareForExtender:(NSObject <HPNExtender> *)extender;

/* Remove the given extender at the given index. Throw an exception if the index
 * is out of bounds. The given extender is checked to be equal to the extender
 * at the given index. This method should not be used in general. Use one of the
 * alternatives above.
 * This is the override point if you want to act just before or after an
 * extender is removed. */
- (void)hpn_removeExtender:(NSObject <HPNExtender> *)extender atIndex:(NSUInteger)idx;

- (NSObject <HPNExtender> *)hpn_firstExtenderOfClass:(Class <HPNExtender>)extenderClass;

/* Returns YES if the extender was added to the object, else NO. */
- (BOOL)hpn_isExtenderAdded:(NSObject <HPNExtender> *)extender;

/* Called when the object is being dealloced, just _before_ the extenders are
 * removed from the object.
 * WARNING: This method is NOT called when a non-extended object is dealloced! */
- (void)hpn_prepareDeallocationOfExtendedObject;

@end

/** Variant of the CHECKED_ADD_EXTENDER preprocessor macro (created for Swift). */
void HPNCheckedAddExtender(id receiver, NSObject <HPNExtender> *extender);
#define CHECKED_ADD_EXTENDER(receiver, extender) \
	{ \
		id receiverVar = (receiver); \
		id extenderVar = (extender); \
		if ((receiverVar != nil) && ![receiverVar hpn_addExtender:extenderVar]) \
			[NSException raise:@"Cannot add extender" format:@"Tried to add extender %@ to %@, but it failed.", extenderVar, receiverVar]; \
	}
