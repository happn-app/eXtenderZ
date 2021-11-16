/*
Copyright 2021 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#import "HPNCustomCancelableTouchesSVE.h"

@import ObjectiveC.runtime;



/* CFDicationary callbacks */
static void release(__unused CFAllocatorRef allocator, const void *value) {
	[(id)value release];
}

static const void *retain(__unused CFAllocatorRef allocator, const void *value) {
	return [(id)value retain];
}



@interface HPNCustomCancelableTouchesSVESettings : NSObject

@property(nonatomic, assign) BOOL cancelsTouchesByDefault;
@property(nonatomic, assign, getter = isExclusive) BOOL exclusive;
@property(nonatomic, assign) BOOL checkSuperviews;
@property(nonatomic, copy) NSArray *specialViews;
@property(nonatomic, copy) NSArray *specialClasses;

@end

@implementation HPNCustomCancelableTouchesSVESettings

+ (instancetype)settingsWithCancelsByDefault:(BOOL)cancelsByDefault isExclusive:(BOOL)exclusive checkSuperviews:(BOOL)checkSuperviews
										  specialViews:(NSArray *)specialViews specialClasses:(NSArray *)specialClasses
{
	HPNCustomCancelableTouchesSVESettings *ret = [HPNCustomCancelableTouchesSVESettings new];
	ret.cancelsTouchesByDefault = cancelsByDefault;
	ret.exclusive = exclusive;
	ret.checkSuperviews = checkSuperviews;
	ret.specialViews = specialViews;
	ret.specialClasses = specialClasses;
	return [ret autorelease];
}

+ (instancetype)settingsFromExtender:(HPNCustomCancelableTouchesSVE *)extender
{
	return [self settingsWithCancelsByDefault:extender.cancelsTouchesByDefault isExclusive:extender.isExclusive checkSuperviews:extender.checkSuperviews
										  specialViews:extender.specialViews specialClasses:extender.specialClasses];
}

- (void)dealloc
{
	self.specialViews = nil;
	self.specialClasses = nil;
	
	[super dealloc];
}

@end



/* Note: The implementation of this extender is weird (exchange of
 *       implementations of two methods which do not even belong to the same
 *       class...).
 *       At the time of writing of this extender, the concept of helptender did
 *       not exist, and it was difficult to extend a method which was not meant
 *       to be extended by the original extender implementation.
 *       Now, the correct thing to do would either to extend the scroll view
 *       helptender so it allows extending
 *       redirectedTouchesShouldCancelInContentView:, or create a new scroll
 *       view helptender dedicated to this extender (the choice should consider
 *       performance issues). */
@implementation HPNCustomCancelableTouchesSVE

static CFMutableDictionaryRef specialClassesInfos = NULL;

- (id)init
{
	if ((self = [super init]) != nil) {
		self.exclusive = NO;
		self.checkSuperviews = NO;
		self.cancelsTouchesByDefault = NO;
		
		self.specialViews = @[];
		self.specialClasses = @[UIButton.class, UITextField.class];
	}
	
	return self;
}

- (void)dealloc
{
	self.specialViews = nil;
	self.specialClasses = nil;
	
	[super dealloc];
}

- (BOOL)prepareObjectForExtender:(UIScrollView *)scrollView
{
	if (![scrollView isKindOfClass:[UIScrollView class]]) return NO;
	if (specialClassesInfos != NULL && CFDictionaryGetValue(specialClassesInfos, scrollView) != NULL) return NO;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		method_exchangeImplementations(class_getInstanceMethod([UIScrollView class], @selector(touchesShouldCancelInContentView:)),
												 class_getInstanceMethod([HPNCustomCancelableTouchesSVE class], @selector(redirectedTouchesShouldCancelInContentView:)));
	});
	
	static CFDictionaryValueCallBacks valueCallbacks = {0, &retain, &release, NULL, NULL};
	if (specialClassesInfos == NULL) specialClassesInfos = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, &valueCallbacks);
	[self registerScrollView:scrollView];
	
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(UIScrollView *)scrollView
{
	NSParameterAssert([scrollView isKindOfClass:[UIScrollView class]]);
	NSAssert(specialClassesInfos != NULL, @"***** INTERNAL ERROR: specialClasses is NULL in prepareTableViewForRemovalOfExtender:");
	CFDictionaryRemoveValue(specialClassesInfos, scrollView);
	if (CFDictionaryGetCount(specialClassesInfos) == 0) {
		CFRelease(specialClassesInfos);
		specialClassesInfos = NULL;
	}
}

- (void)registerScrollView:(UIScrollView *)scrollView
{
	if (self.specialClasses == nil) [NSException raise:@"Invalid Configuration" format:@"specialClasses is nil when custom cancelable touches extender is added to a scroll view"];
	
	NSAssert(specialClassesInfos != NULL, @"***** INTERNAL ERROR: NULL specialClassesInfos in %@", NSStringFromSelector(_cmd));
	CFDictionarySetValue(specialClassesInfos, scrollView, [HPNCustomCancelableTouchesSVESettings settingsFromExtender:self]);
}

- (void)reRegisterScrollView:(UIScrollView *)scrollView
{
	if (specialClassesInfos == NULL || CFDictionaryGetValue(specialClassesInfos, scrollView) == NULL)
		[NSException raise:@"Invalid Parameter" format:@"Trying to re-register an unregistered scroll view"];
	
	[self registerScrollView:scrollView];
}

static void registerEach(const void *key, const void *value, void *context) {
#pragma unused(value)
	UIScrollView *scrollView = key;
	HPNCustomCancelableTouchesSVE *self = context;
	NSCParameterAssert([(id)value isKindOfClass:[NSArray class]]);
	NSCParameterAssert([scrollView isKindOfClass:[UIScrollView class]]);
	NSCParameterAssert([self isKindOfClass:[HPNCustomCancelableTouchesSVE class]]);
	
	[self registerScrollView:scrollView];
}

- (void)reRegisterAllScrollViews
{
	if (specialClassesInfos == NULL) return;
	CFDictionaryApplyFunction(specialClassesInfos, &registerEach, self);
}

#pragma mark - Weird Stuff

- (BOOL)redirectedTouchesShouldCancelInContentView:(UIView *)view
{
	if (specialClassesInfos == NULL) goto callSuper;
	
	HPNCustomCancelableTouchesSVESettings *i = (HPNCustomCancelableTouchesSVESettings *)CFDictionaryGetValue(specialClassesInfos, self /* self is here the UIScrollView, not the extender */);
	NSAssert(i == nil || [i isKindOfClass:HPNCustomCancelableTouchesSVESettings.class],
				@"***** INTERNAL ERROR: Got invalid infos %@, not of class HPNCustomCancelableTouchesSVESettings.", i);
	if (i == nil) goto callSuper;
	
	UIView *currentView;
	
	currentView = view;
	while (currentView != nil) {
		for (UIView *v in i.specialViews) {
			if (currentView == v) {
				if (i.cancelsTouchesByDefault && !i.isExclusive) goto callSuper;
				return !i.cancelsTouchesByDefault;
			}
		}
		currentView = (i.checkSuperviews? currentView.superview: nil);
	}
	
	currentView = view;
	while (currentView != nil) {
		for (Class c in i.specialClasses) {
			if ([currentView isKindOfClass:c]) {
				if (i.cancelsTouchesByDefault && !i.isExclusive) goto callSuper;
				return !i.cancelsTouchesByDefault;
			}
		}
		currentView = (i.checkSuperviews? currentView.superview: nil);
	}
	
	if (i.cancelsTouchesByDefault || i.isExclusive) return i.cancelsTouchesByDefault;
	
callSuper:;
	BOOL (*imp)(id, SEL, UIView *) = (BOOL (*)(id, SEL, UIView *))class_getMethodImplementation([HPNCustomCancelableTouchesSVE class], @selector(redirectedTouchesShouldCancelInContentView:));
	return imp(self, @selector(touchesShouldCancelInContentView:), view); /* Calls the original touchesShouldCancelInContentView: method */
}

@end
