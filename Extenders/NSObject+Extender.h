/*
 * NSObject+Extender.h
 * Happn
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



/* WARNING: Adding/removing an extender is *not* thread-safe.
 * Most of the methods here only work in object that are extended by at least
 * one extender. Methods that are safe to use on any objects are:
 *    * +hc_registerClass:asHelptenderForProtocol:
 *    * -hc_isExtended
 *    * -hc_extenders
 *    * -hc_addExtender:
 * Other methods should not be called on objects whose method hc_isExtended
 * returns NO. */
@interface NSObject (Extender)

/* Must be called in the +load method of any extender helper (helptender) class.
 * protocol must conform to protocol HCExtender, the registered class must
 * respond to protocol HCHelptender. */
+ (BOOL)hc_registerClass:(Class)c asHelptenderForProtocol:(Protocol *)protocol;



- (BOOL)hc_isExtended;
/* Returns all of the extenders that have been added to the object in the order
 * they have been added.
 * Might return nil if there is no extenders added to the object. */
- (NSArray *)hc_extenders;
- (NSArray *)hc_extendersConformingToProtocol:(Protocol *)p; /* Cached. */
/* This method can safely be subclassed, as long as super is called at the
 * beginning of the override (the result of the call to super should be checked
 * too).
 * This method is the only way to add an extender to an object. It returns YES
 * if the extender was added, NO if it was not (the extender refused to be added
 * or it was already added to the object).
 *
 * IMPORTANT NOTE: All added extenders are removed from the object just the
 *                 moment _before_ dealloc is called. Do *not* try to access
 *                 extensions properties or call extensions methods in dealloc!
 */
/* The protocols to which the extender responds to will determine which
 * helptenders will be added to the object. */
- (BOOL)hc_addExtender:(NSObject <HCExtender> *)extender;
/* Removes given extender. Returns YES if found (and removed), NO if not.
 * This method cannot fail.
 * It shouldn't be overridden (override hc_removeObjectExtender:atIndex: instead). */
- (BOOL)hc_removeExtender:(NSObject <HCExtender> *)extender;
/* Removes all extenders with a given class from the extended object. Returns
 * the number of extenders removed.
 * It shouldn't be overridden (override hc_removeObjectExtender:atIndex:). */
- (NSUInteger)hc_removeExtendersOfClass:(Class <HCExtender>)extenderClass;

/* Remove the given extender at the given index. Throw an exception if the index
 * is out of bounds. The given extender is checked to be equal to the extender
 * at the given index. This method should not be used in general. Use one of the
 * alternatives above.
 * This is the override point if you want to act just before or after an
 * extender is removed. */
- (void)hc_removeExtender:(NSObject <HCExtender> *)extender atIndex:(NSUInteger)idx;

- (id <HCExtender>)hc_firstExtenderOfClass:(Class <HCExtender>)extenderClass;

/* Returns YES if the extender was added to the object, else NO. */
- (BOOL)hc_isExtenderAdded:(NSObject <HCExtender> *)extender;

@end
