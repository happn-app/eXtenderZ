/*
 * NSObject+Swizzling.h
 * Happn
 *
 * Thank you http://stackoverflow.com/questions/5339276/what-are-the-dangers-of-method-swizzling-in-objective-c
 * I had to enhance though (+load of categories is not always called after +load
 * of superclass's categories).
 *
 * Created by François Lamboley on 2/25/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "HCUtils.h" /* Stringification */



typedef IMP *IMPPointer;

@interface NSObject (Swizzling)
/* WARNING: None of these methods are thread-safe! */

/* TODO: Extensive testing of these methods. */

/* How to method-swizzle? Explanation by example:
 *
 * @implementation NSView (MyViewAdditions)
 *
 * static void MySetFrame(id self, SEL _cmd, CGRect frame);
 * static void (*OriginalSetFrame)(id self, SEL _cmd, CGRect frame);
 *
 * static void MySetFrame(id self, SEL _cmd, CGRect frame) {
 *    // ***** CUSTOM WORK HERE *****
 *    OriginalSetFrame(self, _cmd, frame);
 *    // ***** OR HERE *****
 * }
 *
 * + (void)load
 * {
 *    CHECKED_SWIZZLE(NSView, setFrame:, MySetFrame, OriginalSetFrame);
 * }
 *
 * @end
 */

/* Fixes parent swizzling by default */
+ (BOOL)hc_swizzle:(SEL)original with:(IMP)replacement store:(IMPPointer)store;
/* Calls hc_swizzleOrAdd:with:store:typesSelector:didAdd:fixChildrenSwizzling:
 * with fixChildrenSwizzling set to YES */
+ (BOOL)hc_swizzleOrAdd:(SEL)original with:(IMP)replacement store:(IMPPointer)store
			 typesSelector:(SEL)backupSelector didAdd:(BOOL *)didAddPtr;

/* Tries to swizzle the original selector with the given replacement, setting
 * store to the original implementation. On success, returns YES, and set
 * *didAddPtr to NO.
 * If the original selector does not exist in the class, will try to add the
 * implementation to the class using the typesSelector if it is not NULL. On
 * success, *store is set to NULL, *didAddPtr is set to YES.
 *
 * About fixChildrenSwizzling:
 *    * Let say you swizzle UIButton's setBackgroundColor: method. UIButton does
 *      not have an implementation of setBackgroundColor: of its own (up to my
 *      knowing; anyway let's say it does not). Thus, an implementation of the
 *      selector will be added to UIButton, and the store will be set to the
 *      original implementation of UIView's setBackgroundColor: (first superview
 *      to implement it).
 *    * Then, let say you swizzle UIView's setBackgroundColor:. It will work; no
 *      problem.
 *    * Now, let's call setBackgroundColor: on an instance of UIButton. As you
 *      know a thing or two about swizzling, you call the original
 *      implementation of setBackgroundColor: in your custom implementation. As
 *      you swizzled UIView's implementation of the selector, you would expect
 *      to be called in you custom implementation of UIView's
 *      setBackgroundColor:. But you won't: as the method was not swizzled when
 *      you swizzled UIButton, the actual original implementation of UIView will
 *      be called.
 *    * fixChildrenSwizzling, if set to YES will fix this problem for you: Each
 *      time a selector is swizzled, the store will be kept along with the class
 *      on which the swizzling was made. When a superclass swizzled a method a
 *      child swizzled, the store of the child will be updated to point to the
 *      new original implementation.
 *      This also works if there was no original implementation (store set to
 *      NULL) and a superclass adds one.
 *
 * Note: If store is non-NULL, it must always point to a valid memory location
 *       while the application is launched (unless you don't plan on fixing
 *       children swizzling).
 *       It is highly recommended that you keep a reference to the original
 *       implementation of the method using the store variable: when you swizzle
 *       a method, you practically always have to call the original method.
 *       (Giving a NULL store will print a warning in the logs.)
 */
+ (BOOL)hc_swizzleOrAdd:(SEL)original with:(IMP)replacement store:(IMPPointer)store
			 typesSelector:(SEL)typesSelector didAdd:(BOOL *)didAddPtr
	fixChildrenSwizzling:(BOOL)fixChildrenSwizzling;

/* Returns NO if the method was not added (it is already in the class, or there
 * is an error getting the types to add the method).
 * Calls hc_addOnlyIfNotExist:with:typesSelector:store: with store set to NULL.
 */
+ (BOOL)hc_addOnlyIfNotExist:(SEL)added with:(IMP)implementation typesSelector:(SEL)typesSelector;

/* If store is NULL, if an implementation of the added selector is added to a
 * superclass or the class after this method is called, an exception will be
 * thrown. Else, *store will be set to the new original implementation.
 * If this method returns YES, *store will always be NULL when going out of the
 * method.
 *
 * Note: If store is non-NULL, it must always point to a valid memory location
 *       while the application is launched (unless you don't plan on fixing
 *       children swizzling).
 *       (Same rule as the hc_swizzleOrAdd:... method.)
 */
+ (BOOL)hc_addOnlyIfNotExist:(SEL)added with:(IMP)implementation typesSelector:(SEL)typesSelector
							  store:(IMPPointer)store;

/* Any further swizzling (by methods from this category) of the given selector
 * on any superclass of the calling class or the calling class will throw an
 * exception after this method is called. */
+ (void)hc_lockSwizzlingOfSelector:(SEL)sel;

@end


/* *** Commodities *** */
/* Use these if you want to automatically throw an exception if there was an
 * error swizzling/adding methods */

#define CHECKED_SWIZZLE(theClass, theSelector, IMPFuncName, IMPPointerName) \
	if (![theClass hc_swizzle:@selector(theSelector) with:(IMP)IMPFuncName store:(IMPPointer)&IMPPointerName]) \
		[NSException raise:@"Cannot swizzle a method" format:@"Tried to swizzle \""S(theSelector)"\" in class \""S(theClass)"\" with my version, but it failed."]; \
	if (IMPPointerName == NULL) [NSException raise:@"Swizzled a method, but original function pointer is NULL" format:@"Swizzled \""S(theSelector)"\", but "S(IMPPointerName)" is NULL"]

#define CHECKED_SWIZZLE_OR_ADD(theClass, theSelector, IMPFuncName, IMPPointerName, backupSelector) \
	if (![theClass hc_swizzleOrAdd:@selector(theSelector) with:(IMP)IMPFuncName store:(IMPPointer)&IMPPointerName typesSelector:@selector(backupSelector)]) \
		[NSException raise:@"Cannot swizzle or add a method" format:@"Tried to swizzle or add \""S(theSelector)"\" in class \""S(theClass)"\", but it failed."]

#define CHECKED_ADD_ONLY_IF_NOT_EXIST(theClass, theSelector, IMPFuncName, theTypesSelector) \
	if (![theClass hc_addOnlyIfNotExist:@selector(theSelector) with:(IMP)IMPFuncName typesSelector:@selector(theTypesSelector)]) \
		[NSException raise:@"Cannot add method only if not exist" format:@"Tried to add \""S(theSelector)"\" only if does not exist in class \""S(theClass)"\", but it failed. Maybe it does exist?"]
