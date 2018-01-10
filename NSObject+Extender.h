/*
 * NSObject+Extender.h
 * happn
 *
 * Created by François Lamboley on 4/26/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import <Foundation/Foundation.h>



@protocol HCExtender <NSObject>
@required

/* Called when the extender is added to the extended object. Can be called more
 * than once on an extender instance if the extender is added on more than one
 * object, or is added then removed then re-added to/from/to an object.
 * Must return NO if the extender cannot be added to the object. */
- (BOOL)prepareObjectForExtender:(NSObject *)object;
/* Called, when the extender is removed from the extended object */
- (void)prepareObjectForRemovalOfExtender:(NSObject *)object;

@end



/* Use HELPTENDER_CALL_SUPER_* macros (see HCHelptenderUtils.h) to call super in
 * a helptender. Do *NOT* call [super method]. Ever. */

@protocol HCHelptender <NSObject>
@required

/* Called the first time a runtime-generated helptender class replaces the
 * runtime class of an object.
 * This is a good place to init the helptender. */
+ (void)hc_helptenderHasBeenAdded:(NSObject <HCHelptender> *)helptender;
/* Called when the helptender will be removed from an extended object (because
 * no more extenders are using the helptender).
 * This is the place to remove everything your helptender used in the object.
 * This will *always* be called _before_ the actual object reaches dealloc. */
+ (void)hc_helptenderWillBeRemoved:(NSObject <HCHelptender> *)helptender;

@end



/* WARNING: Adding/removing an extender is *not* thread-safe. */
@interface NSObject (Extender)

/* Must be called in the +load method of any extender helper (helptender) class.
 * protocol must conform to protocol HCExtender, the registered class must
 * respond to protocol HCHelptender. */
+ (BOOL)hc_registerClass:(Class)c asHelptenderForProtocol:(Protocol *)protocol;



- (BOOL)hc_isExtended;
/* Returns all of the extenders that have been added to the object in the order
 * they have been added.
 * Might return nil if there were no extenders added to the object. */
- (NSArray *)hc_extenders;
- (NSArray *)hc_extendersConformingToProtocol:(Protocol *)p; /* Cached, don't worry about performance. */
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
 *                 overriding hc_prepareDeallocationOfExtendedObject. You must
 *                 call super when overriding this method. It is called when the
 *                 object is being dealloced, _before_ the extenders are removed
 *                 from the object.
 *
 * This method should not be overridden (it might be called twice for the same
 * extender). If you want to be called when an extender is added to an object,
 * see hc_prepareForExtender: */
- (BOOL)hc_addExtender:(NSObject <HCExtender> *)extender;
/* Removes given extender. Returns YES if found (and removed), NO if not.
 * This method cannot fail.
 * It shouldn't be overridden (override hc_removeExtender:atIndex: instead). */
- (BOOL)hc_removeExtender:(NSObject <HCExtender> *)extender;
/* Removes the extenders in the given array, returns the number of extenders
 * actually removed. */
- (NSUInteger)hc_removeExtenders:(NSArray *)extenders;
/* Removes all extenders with a given class from the extended object. Returns
 * the number of extenders removed.
 * It shouldn't be overridden (override hc_removeExtender:atIndex:). */
- (NSUInteger)hc_removeExtendersOfClass:(Class <HCExtender>)extenderClass;
/* Removes all of the extenders of the object. Returns the number of extenders
 * removed (always equal to the number of extenders there was on the object). */
- (NSUInteger)hc_removeAllExtenders;

/* Called in hc_addExtender:, _after_ the helptender(s) have been added to the
 * object. Returns YES if the preparation was successful, NO otherwise (in which
 * case the addition of the extender is cancelled).
 *
 * Do NOT call this method directly.
 * However, you can override the method. You must check whether calling super
 * (don't forget to use HELPTENDER_CALL_SUPER_* methods to call super) returns
 * YES or NO. If it returns NO, you must return NO right away. */
- (BOOL)hc_prepareForExtender:(NSObject <HCExtender> *)extender;

/* Remove the given extender at the given index. Throw an exception if the index
 * is out of bounds. The given extender is checked to be equal to the extender
 * at the given index. This method should not be used in general. Use one of the
 * alternatives above.
 * This is the override point if you want to act just before or after an
 * extender is removed. */
- (void)hc_removeExtender:(NSObject <HCExtender> *)extender atIndex:(NSUInteger)idx;

- (NSObject <HCExtender> *)hc_firstExtenderOfClass:(Class <HCExtender>)extenderClass;

/* Returns YES if the extender was added to the object, else NO. */
- (BOOL)hc_isExtenderAdded:(NSObject <HCExtender> *)extender;

/* Called when the object is being dealloced, just _before_ the extenders are
 * removed from the object.
 * WARNING: This method is NOT called when a non-extended object is dealloced! */
- (void)hc_prepareDeallocationOfExtendedObject;

@end

/** Variant for the CHECKED_ADD_EXTENDER preprocessor macro (created for Swift). */
void HCCheckedAddExtender(id receiver, NSObject <HCExtender> *extender);
#define CHECKED_ADD_EXTENDER(receiver, extender) \
	{ \
		id receiverVar = (receiver); \
		id extenderVar = (extender); \
		if ((receiverVar != nil) && ![receiverVar hc_addExtender:extenderVar]) \
			[NSException raise:@"Cannot add extender" format:@"Tried to add extender %@ to %@, but it failed.", extenderVar, receiverVar]; \
	}
