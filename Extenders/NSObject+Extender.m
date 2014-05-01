/*
 * NSObject+Extender.m
 * Happn
 *
 * Created by François Lamboley on 4/26/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import "NSObject+Extender.h"

#import <objc/runtime.h>

#import "HCUtils.h"
#import "NSObject+HCUtils.h"
#import "HCHelptenderUtils.h"

static char EXTENDERS_KEY; /* Global 0 initialization is fine here. No need to
									 * change it since the value of the variable is not
									 * used; only its address. */
static char EXTENDERS_BY_PROTOCOL_KEY;

static CFMutableDictionaryRef sharedHelptendersByProtocol(void);
static CFMutableDictionaryRef sharedRuntimeHelptendersByHierarchy(void);
static CFMutableDictionaryRef sharedOriginalHelptendersFromRuntimeHelptender(void);
static Class classForObjectExtendedWith(NSObject *object, NSArray *extenders);
static Class changeClassOfObjectNotifyingHelptenders(NSObject *object, Class newClass);

/* Returns a concatenation of str, str2 and str3. str3 can be NULL (not the others).
 * The returned string should be free'd using free()
 * The implementation is not optimized. This function is intended to be used in
 * addMethodForPropertyNamed:inClass: to create the selector name and type
 * for the added selector. */
static char *copyStrs(const char * restrict str1, const char * restrict str2, const char * restrict str3);
static char *auto_sprintf(char * restrict buffer, size_t buffer_size, BOOL * restrict has_malloced, const char * restrict format, ...);

static void addToSet(const void *value, void *context);
static void removeFromSet(const void *value, void *context);


/* ************* Utilities ************* */
#pragma mark - Utilities

static char *copyStrs(const char * restrict str1, const char * restrict str2, const char * restrict str3) {
	char *strCopy = NULL;
	size_t l = strlen(str1) + strlen(str2) + (str3 != NULL? strlen(str3): 0);
	strCopy = malloc(sizeof(char) * (l + 1));
	strncpy(strCopy, str1, l);
	strncpy(strCopy + strlen(str1), str2, l - strlen(str1));
	if (str3 != NULL)
		strncpy(strCopy + strlen(str1) + strlen(str2), str3, l - strlen(str1) - strlen(str2));
	strCopy[l] = '\0';
	return strCopy;
}

static char *auto_sprintf(char * restrict buffer, size_t buffer_size, BOOL * restrict has_malloced, const char * restrict format, ...) {
	size_t n;
	va_list ap;
	*has_malloced = NO;
	
	va_start(ap, format);
	n = vsnprintf(buffer, buffer_size, format, ap);
	va_end(ap);
	if (n < buffer_size) return buffer;
	
	char *ret = NULL;
	*has_malloced = YES;
	va_start(ap, format);
	(void)vasprintf(&ret, format, ap);
	va_end(ap);
	
	return ret;
}

static void addToSet(const void *value, void *context) {
	CFSetAddValue(context, value);
}

static void removeFromSet(const void *value, void *context) {
	CFSetRemoveValue(context, value);
}

static CFHashCode classHash(const void *value) {
	CFStringRef strName = CFStringCreateWithCString(kCFAllocatorDefault, class_getName(value), kCFStringEncodingASCII);
	CFHashCode ret = CFHash(strName);
	CFRelease(strName);
	return ret;
}

static Boolean areProtocolEqual(const void *value1, const void *value2) {
	return protocol_isEqual(value1, value2);
}

static CFHashCode protocolHash(const void *value) {
	CFStringRef strName = CFStringCreateWithCString(kCFAllocatorDefault, protocol_getName(value), kCFStringEncodingASCII);
	CFHashCode ret = CFHash(strName);
	CFRelease(strName);
	return ret;
}

/* ************* Helptenders ************* */
#pragma mark - Helptenders

typedef struct s_helptender {
	Class extended;        /* The class the helptender extends */
	Protocol *extender;    /* Protocol recognized by the helptender for extenders */
	Class helptenderClass; /* Extender helper (the class which extends the extended class) */
	
	NSUInteger retainCount; /* Because we are in a dictionary which uses retain/release */
} t_helptender;

static inline t_helptender *createHelptender(Class extendedClass, Protocol *extenderProtocol, Class helptenderClass) {
	size_t size = 1 * sizeof(t_helptender);
	t_helptender *helptender = malloc(size);
	if (helptender == NULL) [NSException raise:@"Cannot allocate memory" format:@"Cannot allocate %lu bytes. Giving up...", size];
	
	helptender->extended = extendedClass;
	helptender->extender = extenderProtocol;
	helptender->helptenderClass = helptenderClass;
	
	helptender->retainCount = 1;
	return helptender;
}

static inline t_helptender *retainHelptender(t_helptender *helptender) {
	++(helptender->retainCount);
	return helptender;
}

static inline void releaseHelptender(t_helptender *helptender) {
	--(helptender->retainCount);
	
	if (helptender->retainCount == 0)
		free(helptender);
}

static const void *retainHelptenderFromDic(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	return retainHelptender((/* no const */void *)value);
}

static void releaseHelptenderFromDic(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	releaseHelptender((/* no const */void *)value);
}

static Boolean areHelptendersEqual(const void *value1, const void *value2) {
	const t_helptender *helptender1 = value1, *helptender2 = value2;
	if (helptender1->extended != helptender2->extended) return false;
	if (helptender1->helptenderClass != helptender2->helptenderClass) return false;
	if (!protocol_isEqual(helptender1->extender, helptender2->extender)) return false;
	return true;
}

static CFHashCode helptenderHash(const void *value) {
	const t_helptender *helptender = value;
	return classHash(helptender->extended) + protocolHash(helptender->extender) + classHash(helptender->helptenderClass);
}

CFComparisonResult compareHelptenders(const void *val1, const void *val2, void *context) {
#pragma unused(context)
	const t_helptender *helptender1 = val1, *helptender2 = val2;
	Class class1 = helptender1->extended, class2 = helptender2->extended;
	
	if ([class1 isSubclassOfClass:class2])
		return kCFCompareGreaterThan;
	
	if ([class2 isSubclassOfClass:class1])
		return kCFCompareLessThan;
	
	if (class1 == class2) {
		int comp = strcmp(class_getName(helptender1->helptenderClass), class_getName(helptender2->helptenderClass));
		if (comp > 0) return kCFCompareGreaterThan;
		if (comp < 0) return kCFCompareLessThan;
		[NSException raise:@"Invalid Argument" format:@"Cannot sort classes %s and %s. Helptenders %s and %s are equal!", class_getName(class1), class_getName(class2), class_getName(helptender1->helptenderClass), class_getName(helptender2->helptenderClass)];
		return kCFCompareEqualTo;
	}
	
	[NSException raise:@"Invalid Argument" format:@"Cannot sort classes %s and %s. Not in the same branch of the class hierarchy!", class_getName(class1), class_getName(class2)];
	return kCFCompareEqualTo;
}

/* ************* Helptenders Hierarchy ************* */
#pragma mark - Helptenders Hierarchy

typedef struct s_helptenders_hierarchy {
	Class baseClass;
	CFMutableSetRef helptenders;
	
	NSUInteger retainCount;
} t_helptenders_hierarchy;

static inline t_helptenders_hierarchy *createHelptendersHierarchyWithBaseClass(Class baseClass) {
	size_t size = 1 * sizeof(t_helptenders_hierarchy);
	t_helptenders_hierarchy *helptenders_hierarchy = malloc(size);
	if (helptenders_hierarchy == NULL) [NSException raise:@"Cannot allocate memory" format:@"Cannot allocate %lu bytes. Giving up...", size];
	
	helptenders_hierarchy->baseClass = baseClass;
	CFSetCallBacks valueCallbacks = {
		.version         = 0,
		.retain          = &retainHelptenderFromDic,
		.release         = &releaseHelptenderFromDic,
		.copyDescription = NULL,
		.equal           = &areHelptendersEqual,
		.hash            = &helptenderHash
	};
	helptenders_hierarchy->helptenders = CFSetCreateMutable(kCFAllocatorDefault, 0, &valueCallbacks);
	
	helptenders_hierarchy->retainCount = 1;
	return helptenders_hierarchy;
}

static inline t_helptenders_hierarchy *retainHelptendersHierarchy(t_helptenders_hierarchy *helptendersHierarchy) {
	++(helptendersHierarchy->retainCount);
	return helptendersHierarchy;
}

static inline void releaseHelptendersHierarchy(t_helptenders_hierarchy *helptendersHierarchy) {
	--(helptendersHierarchy->retainCount);
	
	if (helptendersHierarchy->retainCount == 0)
		free(helptendersHierarchy);
}

static const void *retainHelptendersHierarchyFromDic(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	return retainHelptendersHierarchy((/* no const */void *)value);
}

static void releaseHelptendersHierarchyFromDic(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	releaseHelptendersHierarchy((/* no const */void *)value);
}

static Boolean areHelptendersHierarchiesEqual(const void *value1, const void *value2) {
	const t_helptenders_hierarchy *hh1 = value1, *hh2 = value2;
	if (hh1->baseClass != hh2->baseClass) return false;
	if (!CFEqual(hh1->helptenders, hh2->helptenders)) return false;
	return true;
}

static CFHashCode helptendersHierarchyHash(const void *value) {
	const t_helptenders_hierarchy *hh = value;
	return classHash(hh->baseClass) + CFHash(hh->helptenders);
}

/* ************* Class Pair ************* */
#pragma mark - Class Pair

typedef struct s_class_pair {
	Class class1;
	Class class2;
	
	NSUInteger retainCount;
} t_class_pair;

static inline t_class_pair *createClassPair(Class class1, Class class2) {
	size_t size = 1 * sizeof(t_class_pair);
	t_class_pair *class_pair = malloc(size);
	if (class_pair == NULL) [NSException raise:@"Cannot allocate memory" format:@"Cannot allocate %lu bytes. Giving up...", size];
	
	class_pair->class1 = class1;
	class_pair->class2 = class2;
	
	class_pair->retainCount = 1;
	return class_pair;
}

static inline t_class_pair *retainClassPair(t_class_pair *classPair) {
	++(classPair->retainCount);
	return classPair;
}

static inline void releaseClassPair(t_class_pair *classPair) {
	--(classPair->retainCount);
	
	if (classPair->retainCount == 0)
		free(classPair);
}

static const void *retainClassPairFromDic(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	return retainClassPair((/* no const */void *)value);
}

static void releaseClassPairFromDic(CFAllocatorRef allocator, const void *value) {
#pragma unused(allocator)
	releaseClassPair((/* no const */void *)value);
}

static Boolean areClassPairsEqual(const void *value1, const void *value2) {
	const t_class_pair *cp1 = value1, *cp2 = value2;
	if (cp1->class1 != cp2->class1) return false;
	if (cp1->class2 != cp2->class2) return false;
	return true;
}

static CFHashCode classPairHash(const void *value) {
	const t_class_pair *cp = value;
	return classHash(cp->class1) + CFHash(cp->class2);
}

#pragma mark -

@interface NSObject ()

- (NSMutableArray *)hc_extenders;
- (NSMutableArray *)hc_extendersCreateIfNotExist:(BOOL)createIfNeeded;

- (BOOL)hc_addExtender:(NSObject <HCExtender> *)extender withOriginalClass:(Class)originalClass;

@end

/* ************* Mandatory NSObject Helptender ************* */
#pragma mark - Base NSObject Helptender

@interface HCObjectBaseHelptender : NSObject <HCHelptender>

@end

@implementation HCObjectBaseHelptender

+ (void)load
{
	[NSObject hc_registerClass:self asHelptenderForProtocol:@protocol(HCExtender)];
}

+ (void)hc_helptenderHasBeenAdded:(id <HCHelptender>)helptender
{
#pragma unused(helptender)
	/* Nothing do to here */
}

+ (void)hc_helptenderWillBeRemoved:(id <HCHelptender>)helptender
{
#pragma unused(helptender)
	/* Nothing do to here */
}

- (Class)class
{
	Class curClass;
	CFDictionaryRef d = sharedOriginalHelptendersFromRuntimeHelptender();
	for (curClass = object_getClass(self); curClass != Nil && CFDictionaryGetValue(d, curClass) != NULL; curClass = class_getSuperclass(curClass));
	return curClass;
}

- (void)dealloc
{
	NSUInteger n;
	while ((n = self.hc_extenders.count) > 0)
		[self hc_removeExtender:self.hc_extenders[n-1] atIndex:n-1];
	
	HELPTENDER_CALL_SUPER_NO_ARGS(HCObjectBaseHelptender);
	if (NO) [super dealloc]; /* Happy compiler is happy */
}

- (BOOL)hc_isExtended
{
	return YES;
}

- (NSMutableArray *)hc_extenders
{
	return [self hc_extendersCreateIfNotExist:NO];
}

- (NSMutableArray *)hc_extendersCreateIfNotExist:(BOOL)createIfNeeded
{
	id ret = [self hc_getAssociatedObjectWithKey:&EXTENDERS_KEY createIfNotExistWithBlock:(createIfNeeded? ^id{
		return [[NSMutableArray alloc] initWithCapacity:7];
	}: NULL)];
	
	NSAssert(ret == nil || [ret isKindOfClass:NSMutableArray.class], @"***** INTERNAL ERROR: Got invalid (not of class NSMutableArray) associated object %@ in %@", ret, NSStringFromSelector(_cmd));
	return ret;
}

- (CFMutableDictionaryRef)hc_extendersByProtocolCreateIfNotExist:(BOOL)createIfNeeded
{
	id ret = [self hc_getAssociatedObjectWithKey:&EXTENDERS_BY_PROTOCOL_KEY createIfNotExistWithBlock:(createIfNeeded? ^id{
		CFDictionaryKeyCallBacks keyCallBacks = {
			.version         = 0,
			.retain          = NULL,
			.release         = NULL,
			.copyDescription = NULL,
			.equal           = &areProtocolEqual,
			.hash            = &protocolHash
		};
		return (NSMutableDictionary *)CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &keyCallBacks, &kCFTypeDictionaryValueCallBacks);
	}: NULL)];
	
	NSAssert(ret == nil || [ret isKindOfClass:NSMutableDictionary.class], @"***** INTERNAL ERROR: Got invalid (not of class NSMutableDictionary) associated object %@ in %@", ret, NSStringFromSelector(_cmd));
	return (CFMutableDictionaryRef)ret;
}

- (NSArray *)hc_extendersConformingToProtocol:(Protocol *)p
{
	CFMutableDictionaryRef extendersByProtocol = [self hc_extendersByProtocolCreateIfNotExist:YES];
	NSMutableArray *ret = CFDictionaryGetValue(extendersByProtocol, p);
	if (ret != nil) return (NSArray *)ret;
	
	ret = [NSMutableArray arrayWithCapacity:self.hc_extenders.count];
	for (NSObject <HCExtender> *extender in self.hc_extenders)
		if ([extender conformsToProtocol:p])
			[ret addObject:extender];
	
	CFDictionarySetValue(extendersByProtocol, p, ret);
	return ret;
}

- (BOOL)hc_addExtender:(NSObject <HCExtender> *)extender
{
	Class c = classForObjectExtendedWith(self, (self.hc_extenders? [self.hc_extenders arrayByAddingObject:extender]: @[extender]));
	if (c == Nil) {
		NSLog(@"*** Warning: Can't get the class to extend object %@.", self);
		return NO;
	}
	if (c != object_getClass(self)) {
		Class originalClass = changeClassOfObjectNotifyingHelptenders(self, c);
		return [self hc_addExtender:extender withOriginalClass:originalClass];
	}
	
	if ([self hc_isExtenderAdded:extender]) {
		NSLog(@"*** Warning: Tried to add extender %@ to extended object %@, but this extender is already added to this object", extender, self);
		return NO;
	}
	
	if (![extender prepareObjectForExtender:self]) {
		NSLog(@"*** Warning: Failed to add extender %@ to extended object %@", extender, self);
		return NO;
	}
	
	[[self hc_extendersCreateIfNotExist:YES] addObject:extender];
	objc_setAssociatedObject(self, &EXTENDERS_BY_PROTOCOL_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); /* Clear the extenders by protocol cache */
	NSDLog(@"Added extender %@ to object %@", extender, self);
	
	return YES;
}

- (BOOL)hc_addExtender:(NSObject <HCExtender> *)extender withOriginalClass:(Class)originalClass
{
	if (![self hc_addExtender:extender]) {
		/* We revert the object to its original class. */
		changeClassOfObjectNotifyingHelptenders(self, originalClass);
		return NO;
	}
	
	return YES;
}

- (void)hc_removeExtender:(NSObject <HCExtender> *)extender atIndex:(NSUInteger)idx
{
	NSMutableArray *e = self.hc_extenders;
	NSParameterAssert(e[idx] == extender);
	
	NSDLog(@"Removing extender %@ from object %p <%s>", extender, self, class_getName(self.class));
	[extender prepareObjectForRemovalOfExtender:self];
	[e removeObjectAtIndex:idx];
	objc_setAssociatedObject(self, &EXTENDERS_BY_PROTOCOL_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); /* Clear the extenders by protocol cache */
	if (e.count == 0) {
		objc_setAssociatedObject(self, &EXTENDERS_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		e = nil;
	}
	
	Class c = classForObjectExtendedWith(self, e);
	changeClassOfObjectNotifyingHelptenders(self, c);
}

- (BOOL)hc_removeExtender:(NSObject <HCExtender> *)extender
{
	NSMutableArray *e = self.hc_extenders;
	if (e == nil) return NO;
	
	NSUInteger idx = [e indexOfObjectIdenticalTo:extender];
	if (idx == NSNotFound) return NO;
	
	[self hc_removeExtender:extender atIndex:idx];
	return YES;
}

- (NSUInteger)hc_removeExtendersOfClass:(Class <HCExtender>)extenderClass
{
	NSUInteger nRemoved = 0;
	
	for (NSUInteger i = 0; i < self.hc_extenders.count; ++i) {
		NSObject <HCExtender> *extender = [self.hc_extenders objectAtIndex:i];
		if (![extender isKindOfClass:extenderClass]) continue;
		
		[self hc_removeExtender:extender atIndex:i--];
		++nRemoved;
	}
	
	return nRemoved;
}

- (NSObject <HCExtender> *)hc_firstExtenderOfClass:(Class <HCExtender>)extenderClass
{
	for (NSObject <HCExtender> *extender in self.hc_extenders)
		if ([extender isKindOfClass:extenderClass])
			return extender;
	
	return nil;
}

- (BOOL)hc_isExtenderAdded:(NSObject <HCExtender> *)extender
{
	NSMutableArray *e = self.hc_extenders;
	return (e != nil && [e indexOfObjectIdenticalTo:extender] != NSNotFound);
}

@end



/* ************* Implementation of the extender NSObject category ************* */
#pragma mark - NSObject Category

/* Keys are Protocol*, values are t_helptender*. */
static CFMutableDictionaryRef helptendersByProtocol = NULL;
/* Keys are t_helptenders_hierarchy*, values are Class (the type Class, aka. struct objc_class*, is a pointer). */
static CFMutableDictionaryRef runtimeHelptendersByHierarchy = NULL;
/* Keys are Class, values are CFSetRef, which contains Class */
static CFMutableDictionaryRef originalHelptendersFromRuntimeHelptender = NULL;
/* Keys are t_class_pair*, values are CFNumber */
static CFMutableDictionaryRef classLevelFromOriginalAndRuntimeHelptender = NULL;

static CFMutableDictionaryRef sharedHelptendersByProtocol(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		CFDictionaryKeyCallBacks keyCallbacks = {
			.version         = 0,
			.retain          = NULL,
			.release         = NULL,
			.copyDescription = NULL,
			.equal           = &areProtocolEqual,
			.hash            = &protocolHash
		};
		CFDictionaryValueCallBacks valueCallbacks = {
			.version         = 0,
			.retain          = &retainHelptenderFromDic,
			.release         = &releaseHelptenderFromDic,
			.copyDescription = NULL,
			.equal           = &areHelptendersEqual
		};
		helptendersByProtocol = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &keyCallbacks, &valueCallbacks);
	});
	
	NSCAssert(helptendersByProtocol != NULL, @"Got NULL helptendersByProtocol...");
	return helptendersByProtocol;
}

static CFMutableDictionaryRef sharedRuntimeHelptendersByHierarchy(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		CFDictionaryKeyCallBacks keyCallbacks = {
			.version         = 0,
			.retain          = &retainHelptendersHierarchyFromDic,
			.release         = &releaseHelptendersHierarchyFromDic,
			.copyDescription = NULL,
			.equal           = &areHelptendersHierarchiesEqual,
			.hash            = &helptendersHierarchyHash
		};
		runtimeHelptendersByHierarchy = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &keyCallbacks, NULL /* Values are Class. Class does not need retain/release, and comparison is done by pointer comparison */);
	});
	
	NSCAssert(runtimeHelptendersByHierarchy != NULL, @"Got NULL runtimeHelptendersByHierarchy...");
	return runtimeHelptendersByHierarchy;
}

static CFMutableDictionaryRef sharedOriginalHelptendersFromRuntimeHelptender(void) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		originalHelptendersFromRuntimeHelptender = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL /* Keys are Class */, &kCFTypeDictionaryValueCallBacks);
	});
	
	NSCAssert(originalHelptendersFromRuntimeHelptender != NULL, @"Got NULL originalHelptenderFromRuntimeHelptender...");
	return originalHelptendersFromRuntimeHelptender;
}

static CFMutableDictionaryRef sharedClassLevelFromOriginalAndRuntimeHelptender() {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		CFDictionaryKeyCallBacks keyCallbacks = {
			.version         = 0,
			.retain          = &retainClassPairFromDic,
			.release         = &releaseClassPairFromDic,
			.copyDescription = NULL,
			.equal           = &areClassPairsEqual,
			.hash            = &classPairHash
		};
		classLevelFromOriginalAndRuntimeHelptender = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &keyCallbacks, &kCFTypeDictionaryValueCallBacks);
	});
	
	NSCAssert(classLevelFromOriginalAndRuntimeHelptender != NULL, @"Got NULL originalHelptenderFromRuntimeHelptender...");
	return classLevelFromOriginalAndRuntimeHelptender;
}

/* Returns NO if the baseProtocol conforms to protocol HCExtender, but the
 * helptender is not kind of the class of the ref object. */
static BOOL recAddProtocolsHelptendersToSet(Protocol *baseProtocol, CFMutableSetRef set, NSObject *refObject) {
	if (!protocol_conformsToProtocol(baseProtocol, @protocol(HCExtender)))
		return YES;
	
	const t_helptender *helptender = CFDictionaryGetValue(sharedHelptendersByProtocol(), baseProtocol);
	if (helptender == NULL)
		[NSException raise:@"Invalid Argument" format:@"Got protocol %s, conforming to protocol HCExtender, but not registered.", protocol_getName(baseProtocol)];
	if (![refObject.class isSubclassOfClass:helptender->extended]) {
		NSLog(@"*** Warning: Got helptender class %s for protocol %s, declared to extend %s, but extended object %p (of class %s) is not kind of %s",
				class_getName(helptender->helptenderClass), protocol_getName(baseProtocol), class_getName(helptender->extended), refObject, class_getName(refObject.class), class_getName(helptender->extended));
		return NO;
	}
	CFSetAddValue(set, helptender);
	
	BOOL ok = YES;
	Protocol **protocols = protocol_copyProtocolList(baseProtocol, NULL);
	for (Protocol **curProtocolPtr = protocols; curProtocolPtr != NULL && *curProtocolPtr != NULL; ++curProtocolPtr) {
		if (!recAddProtocolsHelptendersToSet(*curProtocolPtr, set, refObject)) {
			ok = NO;
			goto end;
		}
	}
	
end:
	if (protocols != NULL) free(protocols);
	return ok;
}

/* Compute which helptenders are needed for each extenders given, then get or
 * create the class that will have the correct hierarchy. */
static Class classForObjectExtendedWith(NSObject *object, NSArray *extenders) {
	const char *className = class_getName(object.class);
	
	if (!object.hc_isExtended &&
		 (object_getClass(object) != object.class || strstr(className, "NSCF") != NULL)) {
		/* Small protection to avoid messing around with other mechanism doing ISA-Swizzling (KVO, etc.). */
		NSLog(@"*** Warning: Refusing to create runtime helptender for an object whose NSObject's class method does not return the same value as object_getClass(), or whose class name contains \"NSCF\" (toll-free bridged objects). NSObject's class --> %@; object_getClass() --> %@.", NSStringFromClass(object.class), NSStringFromClass(object_getClass(object)));
		return Nil;
	}
	
	/* General algorithm:
	 *    For each extender, get list of protocols it conforms to.
	 *    For each protocol, if the protocol conforms to protocol HCExtender,
	 *       get the associated helptender, add it to the set of helptenders
	 *       to add to the final class
	 *    Sort the set of helptenders to get a sorted array of helptenders to add
	 *       to the final class. The sorting must be done on the position of the
	 *       extended class of the helptender in the class hierarchy. As there are
	 *       no multiple inheritance allowed in objective-c, and as there can't be
	 *       two extenders from two different branches of the class hierarchy (eg.
	 *       one in the NSNumber branch, the other on the UIView branch), there will
	 *       never be any ambiguity on this order (no classes will be "equal" when
	 *       compared).
	 *    For each classes, create and register the runtime helptender if not
	 *       already registered, else get it. Return the last runtime helptender,
	 *       it will be the new class of the extended object.
	 */
	
	t_helptenders_hierarchy *hh = createHelptendersHierarchyWithBaseClass(object.class);
	for (NSObject <HCExtender> *extender in extenders) {
		if (![extender conformsToProtocol:@protocol(HCExtender)])
			[NSException raise:@"Invalid argument" format:@"Got extender %@, of class %s, which does not conform to protocol HCExtender", extender, class_getName(extender.class)];
		
		for (Class curClass = extender.class; curClass != Nil; curClass = class_getSuperclass(curClass)) {
			Protocol **protocols = class_copyProtocolList(curClass, NULL);
			
			BOOL ok = YES;
			for (Protocol **curProtocolPtr = protocols; curProtocolPtr != NULL && *curProtocolPtr != NULL; ++curProtocolPtr) {
				if (!recAddProtocolsHelptendersToSet(*curProtocolPtr, hh->helptenders, object)) {
					ok = NO;
					goto end;
				}
			}
			
		end:
			if (protocols != NULL) free(protocols);
			if (!ok) return Nil;
		}
	}
	
	Class ret = CFDictionaryGetValue(sharedRuntimeHelptendersByHierarchy(), hh);
	if (ret == Nil) {
		/* The runtime class has not been created yet. Let's create it! */
		CFIndex nHelptenders = CFSetGetCount(hh->helptenders);
		CFMutableDictionaryRef ohfrh = sharedOriginalHelptendersFromRuntimeHelptender();
		CFMutableDictionaryRef clfoarh = sharedClassLevelFromOriginalAndRuntimeHelptender();
		NSDLog(@"Creating runtime helptender for base class %s, with %ld helptender(s)", class_getName(hh->baseClass), (long)nHelptenders);
		
		CFArrayCallBacks objectCallbacks = {
			.version         = 0,
			.retain          = &retainHelptenderFromDic,
			.release         = &releaseHelptenderFromDic,
			.copyDescription = NULL,
			.equal           = &areHelptendersEqual
		};
		CFMutableArrayRef helptendersArray = NULL;
		{
			const t_helptender **helptenders = malloc(sizeof(t_helptender*) * nHelptenders);
			CFSetGetValues(hh->helptenders, (const void **)helptenders);
			CFArrayRef har = CFArrayCreate(kCFAllocatorDefault, (const void **)helptenders, nHelptenders, &objectCallbacks);
			free(helptenders);
			
			helptendersArray = CFArrayCreateMutableCopy(kCFAllocatorDefault, nHelptenders, har);
			CFRelease(har);
		}
		
		CFArraySortValues(helptendersArray, CFRangeMake(0, nHelptenders), &compareHelptenders, NULL);
		
		char *baseClassName = copyStrs(class_getName(hh->baseClass), "", NULL);
		for (CFIndex i = 0; i < nHelptenders; ++i) {
			const t_helptender *curHelptender = CFArrayGetValueAtIndex(helptendersArray, i);
			char *newClassName = copyStrs(baseClassName, "_Ext_", class_getName(curHelptender->helptenderClass));
			free(baseClassName); baseClassName = newClassName;
		}
		
		CFIndex level = 0;
		ret = hh->baseClass;
		CFMutableDictionaryRef tempLevels = CFDictionaryCreateMutable(kCFAllocatorDefault, nHelptenders, NULL /* Keys are Class */, &kCFTypeDictionaryValueCallBacks);
		for (CFIndex i = 0; i < nHelptenders; ++i) {
			const t_helptender *curHelptender = CFArrayGetValueAtIndex(helptendersArray, i);
			const t_helptender *prevHelptender = (i > 0? CFArrayGetValueAtIndex(helptendersArray, i - 1): NULL);
			const t_helptender *nextHelptender = (i+1 < nHelptenders? CFArrayGetValueAtIndex(helptendersArray, i + 1): NULL);
			if (prevHelptender == NULL || curHelptender->extended != prevHelptender->extended) {
				char buf[8]; BOOL hasMalloced = NO;
				char *intStr = auto_sprintf(buf, 8, &hasMalloced, "%lld", (long long)i);
				char *newClassName = copyStrs(baseClassName, "__", intStr);
				if (hasMalloced) free(intStr);
				
				ret = objc_allocateClassPair(ret, newClassName, 0);
				if (ret == Nil) [NSException raise:@"Cannot Allocate Class Pair" format:@"Got an error allocating a class pair with name %s. Does the class name already exist in the runtime?", newClassName];
				free(newClassName);
				
				++level;
			}
			
			/* We have created the new class. Let's add the methods of the original helptender to it. */
			Method *methods = class_copyMethodList(curHelptender->helptenderClass, NULL);
			for (Method *curMethodPtr = methods; curMethodPtr != NULL && *curMethodPtr != NULL; ++curMethodPtr)
				if (!class_addMethod(ret, method_getName(*curMethodPtr), method_getImplementation(*curMethodPtr), method_getTypeEncoding(*curMethodPtr)))
					[NSException raise:@"Error Adding Method" format:@"Cannot add method %s to runtime helptender %s. Probably two helptenders extending the same class have methods sharing the same name.", sel_getName(method_getName(*curMethodPtr)), class_getName(ret)];
			if (methods != NULL) free(methods);
			
			/* Let's register the original helptender class for the new runtime helptender class */
			CFMutableSetRef registeredClasses = (CFMutableSetRef)CFDictionaryGetValue(ohfrh, ret);
			if (registeredClasses == NULL) {
				registeredClasses = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL /* Contains classes */);
				CFDictionarySetValue(ohfrh, ret, registeredClasses);
				CFRelease(registeredClasses);
			}
			CFSetAddValue(registeredClasses, curHelptender->helptenderClass);
			
			/* Let's add the level of the class to the temp levels dictionary.
			 * After the final class is created, we fill
			 * classLevelFromOriginalAndRuntimeHelptender from the temp levels. */
			CFNumberRef n = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &level);
			CFDictionarySetValue(tempLevels, curHelptender->helptenderClass, n);
			CFRelease(n);
			
			if (nextHelptender == NULL || curHelptender->extended != nextHelptender->extended)
				/* The runtime helptender is complete. Let's register it in the runtime. */
				objc_registerClassPair(ret);
		}
		
		/* Let's fill classLevelFromOriginalAndRuntimeHelptender from tempLevels. */
		CFIndex maxLevel = level + 1;
		CFIndex n = CFDictionaryGetCount(tempLevels);
		Class *keys = malloc(sizeof(Class) * n);
		CFNumberRef *values = malloc(sizeof(CFNumberRef) * n);
		CFDictionaryGetKeysAndValues(tempLevels, (const void **)keys, (const void **)values);
		for (CFIndex i = 0; i < n; ++i) {
			t_class_pair *cp = createClassPair(ret, keys[i]);
			NSCAssert(CFDictionaryGetValue(clfoarh, cp) == NULL, @"***** INTERNAL ERROR: We shouldn't have the class pair %s/%s registered for class level.", class_getName(cp->class1), class_getName(cp->class2));
			CFIndex newLevel = 0;
			CFNumberGetValue(values[i], kCFNumberCFIndexType, &newLevel);
			newLevel = maxLevel - newLevel;
			CFNumberRef newLevelNumber = CFNumberCreate(kCFAllocatorDefault, kCFNumberCFIndexType, &newLevel);
			CFDictionarySetValue(clfoarh, cp, newLevelNumber);
			CFRelease(newLevelNumber);
			releaseClassPair(cp);
		}
		free(values); values = NULL;
		free(keys); keys = NULL;
		
		CFRelease(tempLevels);
		CFRelease(helptendersArray);
		CFDictionarySetValue(sharedRuntimeHelptendersByHierarchy(), hh, ret);
	}
	
	releaseHelptendersHierarchy(hh);
	return ret;
}

static void callHelptenderWillBeRemoved(const void *value, void *context) {
	[(Class)value hc_helptenderWillBeRemoved:context];
}

static void callHelptenderHasBeenAdded(const void *value, void *context) {
	[(Class)value hc_helptenderHasBeenAdded:context];
}

static Class changeClassOfObjectNotifyingHelptenders(NSObject *object, Class newClass) {
	Class originalActualObjectClass = object_getClass(object);
	CFDictionaryRef ohfrh = sharedOriginalHelptendersFromRuntimeHelptender();
	
	/* Computing original helptenders in the object */
	CFMutableSetRef originalHelptendersInObject = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL /* Contains classes */);
	for (Class curClass = originalActualObjectClass; curClass != Nil; curClass = class_getSuperclass(curClass)) {
		CFSetRef originalHelptendersClasses = CFDictionaryGetValue(ohfrh, curClass);
		if (originalHelptendersClasses != NULL)
			CFSetApplyFunction(originalHelptendersClasses, &addToSet, originalHelptendersInObject);
	}
	
	/* Computing new helptenders for the object */
	CFMutableSetRef newHelptendersInObject = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL /* Contains classes */);
	for (Class curClass = newClass; curClass != Nil; curClass = class_getSuperclass(curClass)) {
		CFSetRef originalHelptendersClasses = CFDictionaryGetValue(ohfrh, curClass);
		if (originalHelptendersClasses != NULL)
			CFSetApplyFunction(originalHelptendersClasses, &addToSet, newHelptendersInObject);
	}
	
	CFMutableSetRef removedHelptenders = CFSetCreateMutableCopy(kCFAllocatorDefault, CFSetGetCount(originalHelptendersInObject), originalHelptendersInObject);
	CFSetApplyFunction(newHelptendersInObject, &removeFromSet, removedHelptenders);
	CFSetApplyFunction(removedHelptenders, &callHelptenderWillBeRemoved, object);
	CFRelease(removedHelptenders);
	
#ifndef NS_BLOCK_ASSERTIONS
	Class classCheck =
#endif
	object_setClass(object, newClass);
	NSCAssert(classCheck == originalActualObjectClass, @"***** INTERNAL ERROR: This check should always be true. This is a serious error.");
	
	CFMutableSetRef addedHelptenders = CFSetCreateMutableCopy(kCFAllocatorDefault, CFSetGetCount(newHelptendersInObject), newHelptendersInObject);
	CFSetApplyFunction(originalHelptendersInObject, &removeFromSet, addedHelptenders);
	CFSetApplyFunction(addedHelptenders, &callHelptenderHasBeenAdded, object);
	CFRelease(addedHelptenders);
	
	CFRelease(originalHelptendersInObject);
	CFRelease(newHelptendersInObject);
	
	return originalActualObjectClass;
}



@implementation NSObject (_Extender)
/* These implementations (except for hc_registerClass:asHelptenderForProtocol:
 * are only called on a non-extended object. For extended objects, the
 * implementation in HCObjectBaseHelptender are called. */

+ (BOOL)hc_registerClass:(Class)c asHelptenderForProtocol:(Protocol *)protocol
{
	if (![c conformsToProtocol:@protocol(HCHelptender)])
		[NSException raise:@"Invalid Argument" format:@"The class %@ was asked to be registered as helptender for protocol %@, but it does not conform to protocol HCHelptender", NSStringFromClass(c), NSStringFromProtocol(protocol)];
	if (!protocol_conformsToProtocol(protocol, @protocol(HCExtender)))
		[NSException raise:@"Invalid Argument" format:@"The class %@ was asked to be registered as helptender for protocol %@, but protocol does not conform to protocol HCExtender", NSStringFromClass(c), NSStringFromProtocol(protocol)];
	
	Class extendedClass = class_getSuperclass(c); /* A helptender extends its direct superclass by definition. */
	if (CFDictionaryGetValue(sharedHelptendersByProtocol(), protocol) != NULL)
		/* There is already a helptender register for the given protocol. Only one
		 * helptender can be defined for a given protocol. */
		return NO;
	
	t_helptender *helptender = createHelptender(extendedClass, protocol, c);
	CFDictionarySetValue(sharedHelptendersByProtocol(), protocol, helptender);
	releaseHelptender(helptender);
	return YES;
}

- (BOOL)hc_isExtended
{
	return NO;
}

- (NSArray *)hc_extenders
{
	return nil;
}

- (NSArray *)hc_extendersConformingToProtocol:(Protocol *)p
{
#pragma unused(p)
	return nil;
}

- (BOOL)hc_addExtender:(NSObject <HCExtender> *)extender
{
	Class c = classForObjectExtendedWith(self, (self.hc_extenders? [self.hc_extenders arrayByAddingObject:extender]: @[extender]));
	if (c == Nil) {
		NSLog(@"*** Warning: Can't get the class to extend object %@.", self);
		return NO;
	}
	
	Class originalClass = changeClassOfObjectNotifyingHelptenders(self, c);
	
	return [self hc_addExtender:extender withOriginalClass:originalClass];
}

- (BOOL)hc_removeExtender:(NSObject <HCExtender> *)extender
{
#pragma unused(extender)
	return NO;
}

- (NSUInteger)hc_removeExtendersOfClass:(Class <HCExtender>)extenderClass
{
#pragma unused(extenderClass)
	return 0;
}

- (void)hc_removeExtender:(NSObject <HCExtender> *)extender atIndex:(NSUInteger)idx
{
#pragma unused(extender, idx)
	[NSException raise:@"Cannot Remove Extender" format:@"Trying to remove an extender on a non-extended object."];
}

- (NSObject <HCExtender> *)hc_firstExtenderOfClass:(Class <HCExtender>)extenderClass
{
#pragma unused(extenderClass)
	return nil;
}

- (BOOL)hc_isExtenderAdded:(NSObject <HCExtender> *)extender
{
#pragma unused(extender)
	return NO;
}

@end



@implementation NSObject (ForHelptendersOnly)

- (Class)getSuperClassWithOriginalHelptenderClass:(Class)originalHelptenderClass
{
	if (self.hc_isExtended) {
		t_class_pair classPair = {.class1 = object_getClass(self), .class2 = originalHelptenderClass, .retainCount = NSUIntegerMax};
		CFNumberRef n = CFDictionaryGetValue(sharedClassLevelFromOriginalAndRuntimeHelptender(), &classPair);
		NSCAssert(n != NULL, @"***** INTERNAL ERROR: Got NULL level for class pair %s/%s.", class_getName(classPair.class1), class_getName(classPair.class2));
		CFIndex level = 0;
		CFNumberGetValue(n, kCFNumberCFIndexType, &level);
		NSCAssert(level > 0, @"***** INTERNAL ERROR: Got invalid level %lld for class pair %s/%s.", (long long)level, class_getName(classPair.class1), class_getName(classPair.class2));
		
		Class ret = classPair.class1;
		for (CFIndex i = 0; i < level; ++i)
			ret = class_getSuperclass(ret);
		
		return ret;
	} else {
		return object_getClass(self); /* And not the superclass! We call this
												 * method in a helptender, expecting to call
												 * super. We must call the original class
												 * then. */
	}
}

@end
