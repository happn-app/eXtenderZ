/*
 * NSObject+Swizzling.m
 * Happn
 *
 * Created by François Lamboley on 2/25/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import "NSObject+Swizzling.h"

#import <objc/runtime.h>



@interface HCSwizzlingInfo : NSObject

@property(nonatomic, retain) Class classOfOrigin;

/* Pointer whose value is the original implementation of the swizzle. If
 * swizzling/adding implementation of method to superclass, this store must be
 * modified. */
@property(nonatomic, assign) IMPPointer store;

/* Whether the swizzle is locked. Can only be a hc_addOnlyIfNotExist:...
 * swizzle.
 * If a swizzle is locked, if trying to add/swizzle a method of a superclass
 * with the same selector, an exception must be thrown. */
@property(nonatomic, assign, getter = isLocked) BOOL locked;

+ (instancetype)swizzlingInfosWithClassOfOrigin:(Class)c store:(IMPPointer)store;
+ (instancetype)swizzlingInfosWithClassOfOrigin:(Class)c store:(IMPPointer)store locked:(BOOL)locked;

@end

@implementation HCSwizzlingInfo

+ (instancetype)swizzlingInfosWithClassOfOrigin:(Class)c store:(IMPPointer)store
{
	return [self swizzlingInfosWithClassOfOrigin:c store:store locked:NO];
}

+ (instancetype)swizzlingInfosWithClassOfOrigin:(Class)c store:(IMPPointer)store locked:(BOOL)locked
{
	HCSwizzlingInfo *ret = [HCSwizzlingInfo new];
	ret.store = store;
	ret.locked = locked;
	ret.classOfOrigin = c;
	return [ret autorelease];
}

- (NSString *)description
{
	return [[super description] stringByAppendingFormat:@" store = %p, *store = %p, locked = %d, class of origin = %@", self.store, (self.store? *(self.store): NULL), self.locked, NSStringFromClass(self.classOfOrigin)];
}

- (void)dealloc
{
	self.classOfOrigin = Nil;
	[super dealloc];
}

@end



typedef struct s_retained_SEL {
	NSUInteger retainCount;
	SEL sel;
} t_retained_SEL;

static inline t_retained_SEL *rSELCreateWithSEL(SEL sel) {
	t_retained_SEL *ret = malloc(sizeof(t_retained_SEL));
	ret->sel = sel;
	ret->retainCount = 1;
	return ret;
}

static const void *rSELRetain(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	++(((t_retained_SEL*)value)->retainCount);
	return value;
}

static void rSELRelease(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	t_retained_SEL *ret_SEL = (t_retained_SEL*)value;
	if (--(ret_SEL->retainCount) == 0)
		free(ret_SEL);
}

static CFStringRef rSELCopyDescription(const void *value) {
	const char *selName = sel_getName(((t_retained_SEL*)value)->sel);
	return CFStringCreateWithCString(kCFAllocatorDefault, selName, kCFStringEncodingASCII);
}

static Boolean rSELEqual(const void *value1, const void *value2) {
	return sel_isEqual(((t_retained_SEL*)value1)->sel, ((t_retained_SEL*)value2)->sel);
}

static CFHashCode rSELHash(const void *value) {
	const char *selName = sel_getName(((t_retained_SEL*)value)->sel);
	
	CFHashCode hash = 7;
	unsigned long len = strlen(selName);
	for (size_t i = 0; i < len; ++i)
		hash = hash*31 + selName[i];
	
	return hash;
}


static CFMutableDictionaryRef swizzlingInfos = NULL;

@implementation NSObject (Swizzling)

+ (CFMutableDictionaryRef)swizzlingInfos
{
	if (swizzlingInfos != NULL) return swizzlingInfos;
	CFDictionaryKeyCallBacks keyCallBacks = {
		0 /* Version */,
		&rSELRetain /* Retain */,
		&rSELRelease /* Release */,
		&rSELCopyDescription,
		&rSELEqual,
		&rSELHash
	};
	swizzlingInfos = CFDictionaryCreateMutable(kCFAllocatorDefault, 0 /* Capacity */,
															 &keyCallBacks /* Keys are t_retained_SEL* */,
															 &kCFTypeDictionaryValueCallBacks /* Values are CFMutableArrayRef of HCSwizzlingInfo */);
	return swizzlingInfos;
}

+ (CFMutableArrayRef)swizzlingInfosForSelector:(SEL)sel
{
	const t_retained_SEL rSEL = {0, sel};
	CFMutableArrayRef ret = (/* no const */CFMutableArrayRef)CFDictionaryGetValue(self.swizzlingInfos, &rSEL);
	if (ret != NULL) return ret;
	
	t_retained_SEL *prSEL = rSELCreateWithSEL(sel);
	ret = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	CFDictionarySetValue(self.swizzlingInfos, prSEL, ret);
	rSELRelease(kCFAllocatorDefault, prSEL);
	return ret;
}

+ (void)enumerateSwizzlingInfosOfSubclasses:(CFArrayRef)infos includeMyClass:(BOOL)includeMyClass withBlock:(void (^)(HCSwizzlingInfo *info))block
{
	CFIndex n = CFArrayGetCount(infos);
	for (CFIndex i = 0; i < n; ++i) {
		HCSwizzlingInfo *info = CFArrayGetValueAtIndex(infos, i);
		if ([info.classOfOrigin isSubclassOfClass:self] && (includeMyClass || info.classOfOrigin != self))
			block(info);
	}
}

+ (BOOL)hc_swizzle:(SEL)original with:(IMP)replacement store:(IMPPointer)store
{
	return [self hc_swizzleOrAdd:original with:replacement store:store typesSelector:NULL didAdd:NULL fixChildrenSwizzling:YES];
}

+ (BOOL)hc_swizzleOrAdd:(SEL)original with:(IMP)replacement store:(IMPPointer)store typesSelector:(SEL)backupSelector didAdd:(BOOL *)didAddPtr
{
	return [self hc_swizzleOrAdd:original with:replacement store:store typesSelector:backupSelector didAdd:didAddPtr fixChildrenSwizzling:YES];
}

+ (BOOL)hc_swizzleOrAdd:(SEL)original with:(IMP)replacement store:(IMPPointer)store
			 typesSelector:(SEL)backupSelector didAdd:(BOOL *)didAddPtr
	fixChildrenSwizzling:(BOOL)fixChildrenSwizzling
{
	IMP imp;
	BOOL didAdd = NO;
	if (store != NULL) *store = NULL;
	else {
		static BOOL shownWarning = NO;
		if (!shownWarning) {
			NSLog(@"*** Warning: Dangerous call to %@ from class %@ with a NULL store pointer.", NSStringFromSelector(_cmd), NSStringFromClass(self));
			NSLog(@"             Method-swizzling is by essence dangerous. Not calling the original");
			NSLog(@"             implementation of the swizzled method is practically suicide.");
			NSLog(@"             You have been warned, you won't be warned again. Good luck.");
			shownWarning = YES;
		}
	}
	
	CFMutableArrayRef swizzlingInfos = [self swizzlingInfosForSelector:original];
	[self enumerateSwizzlingInfosOfSubclasses:swizzlingInfos includeMyClass:YES withBlock:^(HCSwizzlingInfo *info) {
		if (info.isLocked) [NSException raise:@"Cannot Swizzle an Added Exclusive Method" format:@"Trying to add an implementation of selector %@ in class %@, but class %@ locked the implementation.", NSStringFromSelector(original), NSStringFromClass(self), NSStringFromClass(info.classOfOrigin)];
	}];
	
	Method method = class_getInstanceMethod(self, original);
	if (method == NULL && backupSelector != NULL) {didAdd = YES; method = class_getInstanceMethod(self, backupSelector);}
	if (method == NULL) {
		NSLog(@"*** Warning: Can't swizzle%@ selector \"%@\": no original or backup method found.", (backupSelector != NULL? @" or add": @""), NSStringFromSelector(original));
		return NO;
	}
	
	const char *types = method_getTypeEncoding(method);
	if (types == NULL) {
		NSLog(@"*** Warning: Can't swizzle%@ selector \"%@\": no types found for original method.", (backupSelector != NULL? @" or add": @""), NSStringFromSelector(original));
		return NO;
	}
	
	imp = class_replaceMethod(self, original, replacement, types);
	if (!didAdd && imp == NULL) imp = method_getImplementation(method);
	if (didAddPtr != NULL) *didAddPtr = didAdd;
	if (store != NULL) *store = imp;
	
	NSDLog(@"Swizzled selector %@ of %@ with replacement implementation %p", NSStringFromSelector(original), NSStringFromClass(self), replacement);
	if (fixChildrenSwizzling) {
		[self enumerateSwizzlingInfosOfSubclasses:swizzlingInfos includeMyClass:NO withBlock:^(HCSwizzlingInfo *info) {
			if (info.store == NULL) return;
			
			if (*(info.store) == imp) {
				NSDLog(@"Updating store of subclass %@", NSStringFromClass(info.classOfOrigin));
				*(info.store) = replacement;
			}
		}];
	}
	CFArrayAppendValue(swizzlingInfos, [HCSwizzlingInfo swizzlingInfosWithClassOfOrigin:self store:store]);
	
	return YES;
}

+ (BOOL)hc_addOnlyIfNotExist:(SEL)added with:(IMP)implementation typesSelector:(SEL)typesSelector
{
	return [self hc_addOnlyIfNotExist:added with:implementation typesSelector:typesSelector store:NULL];
}

+ (BOOL)hc_addOnlyIfNotExist:(SEL)added with:(IMP)implementation typesSelector:(SEL)typesSelector
							  store:(IMPPointer)store
{
	if (store != NULL) *store = NULL;
	
	CFMutableArrayRef swizzlingInfos = [self swizzlingInfosForSelector:added];
	[self enumerateSwizzlingInfosOfSubclasses:swizzlingInfos includeMyClass:YES withBlock:^(HCSwizzlingInfo *info) {
		if (info.isLocked) [NSException raise:@"Cannot Add an Exclusive Method" format:@"Trying to add an implementation of selector %@ in class %@, but class %@ locked the implementation.", NSStringFromSelector(added), NSStringFromClass(self), NSStringFromClass(info.classOfOrigin)];
	}];
	
	Method method = class_getInstanceMethod(self, typesSelector);
	if (method == NULL) {
		NSLog(@"*** Warning: Can't add selector \"%@\" to class %@: I can't get the method for the types selector (\"%@\")", NSStringFromSelector(added), NSStringFromClass(self), NSStringFromSelector(typesSelector));
		return NO;
	}
	
	const char *types = method_getTypeEncoding(method);
	if (types == NULL) {
		NSLog(@"*** Warning: Can't add selector \"%@\" to class %@: I can't get the types of the method of the types selector (\"%@\")", NSStringFromSelector(added), NSStringFromClass(self), NSStringFromSelector(typesSelector));
		return NO;
	}
	
	if (!class_addMethod(self, added, implementation, types)) {
		NSLog(@"*** Warning: Can't add selector \"%@\" to class %@: class_addMethod failed.", NSStringFromSelector(added), NSStringFromClass(self));
		return NO;
	}
	
	CFArrayAppendValue(swizzlingInfos, [HCSwizzlingInfo swizzlingInfosWithClassOfOrigin:self store:store locked:(store == NULL)]);
	return YES;
}

+ (void)hc_lockSwizzlingOfSelector:(SEL)sel
{
	CFMutableArrayRef swizzlingInfos = [self swizzlingInfosForSelector:sel];
	CFArrayAppendValue(swizzlingInfos, [HCSwizzlingInfo swizzlingInfosWithClassOfOrigin:self store:NULL locked:YES]);
}

@end
