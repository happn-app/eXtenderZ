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

#import "HPNScrollViewExtender.h"

@import ObjectiveC.runtime;

@import eXtenderZ.HelptenderUtils;



static char DEALLOCING;
static char CHEAT_DELEGATE;
void * const SCROLL_VIEW_EXTENDER_CHEAT_REFERENCE = &CHEAT_DELEGATE;
static char EXTENDERS_DID_SCROLL_KEY;
static char EXTENDERS_DID_END_DRAG_SCROLLING_KEY;
static char EXTENDERS_WILL_END_DRAG_SCROLLING_KEY;
static char EXTENDERS_DID_END_DECELERATING_SCROLL_KEY;
static char EXTENDERS_CONTENT_SIZE_WILL_CHANGE_KEY;
static char EXTENDERS_CONTENT_SIZE_DID_CHANGE_KEY;
static char EXTENDERS_CONTENT_INSET_WILL_CHANGE_KEY;
static char EXTENDERS_CONTENT_INSET_DID_CHANGE_KEY;

@implementation HPNScrollViewHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNScrollViewExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(HPNScrollViewHelptender *)helptender
{
	[helptender hpn_overrideDelegate];
}

+ (void)hpn_helptenderWillBeRemoved:(HPNScrollViewHelptender *)helptender
{
	[helptender hpn_resetDelegate];
	objc_setAssociatedObject(helptender, &EXTENDERS_DID_SCROLL_KEY,                  nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_DID_END_DRAG_SCROLLING_KEY,      nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_WILL_END_DRAG_SCROLLING_KEY,     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_DID_END_DECELERATING_SCROLL_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_CONTENT_SIZE_WILL_CHANGE_KEY,    nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_CONTENT_SIZE_DID_CHANGE_KEY,     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_CONTENT_INSET_WILL_CHANGE_KEY,   nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(helptender, &EXTENDERS_CONTENT_INSET_DID_CHANGE_KEY,    nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	/* NOT setting SCROLL_VIEW_EXTENDER_CHEAT_REFERENCE to nil: it can still be in use by a sub-helptender. */
}

- (BOOL)hpn_isDeallocing
{
	return (objc_getAssociatedObject(self, &DEALLOCING) != nil);
}

- (void)hpn_setDeallocing
{
	objc_setAssociatedObject(self, &DEALLOCING, NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersDidScroll,                EXTENDERS_DID_SCROLL_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersDidEndDragScrolling,      EXTENDERS_DID_END_DRAG_SCROLLING_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersWillEndDragScrolling,     EXTENDERS_WILL_END_DRAG_SCROLLING_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersDidEndDeceleratingScroll, EXTENDERS_DID_END_DECELERATING_SCROLL_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersContentWillSizeChange,    EXTENDERS_CONTENT_SIZE_WILL_CHANGE_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersContentDidSizeChange,     EXTENDERS_CONTENT_SIZE_DID_CHANGE_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersContentWillInsetChange,   EXTENDERS_CONTENT_INSET_WILL_CHANGE_KEY)
HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersContentDidInsetChange,    EXTENDERS_CONTENT_INSET_DID_CHANGE_KEY)

- (BOOL)hpn_prepareForExtender:(NSObject <HPNExtender> *)extender
{
	if (!((BOOL (*)(id, SEL, NSObject <HPNExtender> *))HPN_HELPTENDER_CALL_SUPER(HPNScrollViewHelptender, extender))) return NO;
	
	if ([extender conformsToProtocol:@protocol(HPNScrollViewExtender)]) {
		if ([extender respondsToSelector:@selector(scrollViewDidScroll:)])                                        [[self hpn_extendersDidScrollCreateIfNotExist:YES]                addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewDidEndDecelerating:)])                               [[self hpn_extendersDidEndDeceleratingScrollCreateIfNotExist:YES] addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewDidEndDragScrolling:willDecelerate:)])               [[self hpn_extendersDidEndDragScrollingCreateIfNotExist:YES]      addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewWillChangeContentSize:newContentSize:)])             [[self hpn_extendersContentWillSizeChangeCreateIfNotExist:YES]    addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewDidChangeContentSize:originalContentSize:)])         [[self hpn_extendersContentDidSizeChangeCreateIfNotExist:YES]     addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewWillChangeContentInset:newContentInset:)])           [[self hpn_extendersContentWillInsetChangeCreateIfNotExist:YES]   addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewDidChangeContentInset:originalContentInset:)])       [[self hpn_extendersContentDidInsetChangeCreateIfNotExist:YES]    addObject:extender];
		if ([extender respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) [[self hpn_extendersWillEndDragScrollingCreateIfNotExist:YES]     addObject:extender];
		
		[self hpn_refreshDelegate];
	}
	
	return YES;
}

- (void)hpn_removeExtender:(NSObject <HPNExtender> *)extender atIndex:(NSUInteger)idx
{
	if ([extender conformsToProtocol:@protocol(HPNScrollViewExtender)]) {
		[self.hpn_extendersDidScroll                removeObjectIdenticalTo:extender];
		[self.hpn_extendersDidEndDragScrolling      removeObjectIdenticalTo:extender];
		[self.hpn_extendersWillEndDragScrolling     removeObjectIdenticalTo:extender];
		[self.hpn_extendersDidEndDeceleratingScroll removeObjectIdenticalTo:extender];
		[self.hpn_extendersContentWillSizeChange    removeObjectIdenticalTo:extender];
		[self.hpn_extendersContentDidSizeChange     removeObjectIdenticalTo:extender];
		[self.hpn_extendersContentWillInsetChange   removeObjectIdenticalTo:extender];
		[self.hpn_extendersContentDidInsetChange    removeObjectIdenticalTo:extender];
		
		[self hpn_refreshDelegate];
	}
	
	((void (*)(id, SEL, NSObject <HPNExtender> *, NSUInteger))HPN_HELPTENDER_CALL_SUPER(HPNScrollViewHelptender, extender, idx));
}

- (void)hpn_prepareDeallocationOfExtendedObject
{
	[self hpn_setDeallocing];
	((void (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNScrollViewHelptender));
}

#pragma mark - Overrides of UIScrollView

- (void)setContentSize:(CGSize)contentSize
{
	CGSize ori = self.contentSize;
	
	BOOL isDifferent = (ABS(contentSize.width - ori.width) > 0.01 || ABS(contentSize.height - ori.height) > 0.01);
	
	if (isDifferent) {
		for (NSObject <HPNScrollViewExtender> *extender in self.hpn_extendersContentWillSizeChange)
			[extender scrollViewWillChangeContentSize:self newContentSize:contentSize];
	}
	
	((void (*)(id, SEL, CGSize))HPN_HELPTENDER_CALL_SUPER(HPNScrollViewHelptender, contentSize));
	
	if (isDifferent) {
		for (NSObject <HPNScrollViewExtender> *extender in self.hpn_extendersContentDidSizeChange)
			[extender scrollViewDidChangeContentSize:self originalContentSize:ori];
	}
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
	UIEdgeInsets ori = self.contentInset;
	
	for (NSObject <HPNScrollViewExtender> *extender in self.hpn_extendersContentWillInsetChange)
		[extender scrollViewWillChangeContentInset:self newContentInset:contentInset];
	
	((void (*)(id, SEL, UIEdgeInsets))HPN_HELPTENDER_CALL_SUPER(HPNScrollViewHelptender, contentInset));
	
	for (NSObject <HPNScrollViewExtender> *extender in self.hpn_extendersContentDidInsetChange)
		[extender scrollViewDidChangeContentInset:self originalContentInset:ori];
}

#pragma mark - Delegate Overriding

- (HPNScrollViewDelegateForHelptender *)hpn_cheatDelegateCreateIfNotExist
{
	HPNScrollViewDelegateForHelptender *ret = (HPNScrollViewDelegateForHelptender *)[self hpn_getAssociatedObjectWithKey:SCROLL_VIEW_EXTENDER_CHEAT_REFERENCE createIfNotExistWithBlock:^id{
		HPNScrollViewDelegateForHelptender *retIn = [HPNScrollViewDelegateForHelptender new];
		retIn.linkedView = self;
		return retIn;
	}];
	
	NSAssert([ret isKindOfClass:HPNScrollViewDelegateForHelptender.class], @"***** INTERNAL ERROR: Got invalid (not of class HPNScrollViewDelegateForHelptender) associated object %@ in %@", ret, NSStringFromSelector(_cmd));
	NSAssert(ret.linkedView == self, @"***** INTERNAL ERROR: Got invalid linked view %@ for scroll view %@", ret.linkedView, self);
	return ret;
}

- (void)hpn_overrideDelegate
{
	NSParameterAssert(![self.delegate isKindOfClass:HPNScrollViewDelegateForHelptender.class]);
	self.delegate = self.delegate;
}

- (void)hpn_resetDelegate
{
	/* We are NOT modifying the delegate when we're deallocing, or if we are a
	 * table view and the data source has been dealloced when we're here (most
	 * likely to happen when we're deallocing), the table view may try calling
	 * its datasource, which would crash. (The table view does not keep a weak
	 * ref to the data source...)
	 *
	 * Another better solution would be to force the table view to have a weak
	 * data source instead of a simple assign (MAZeroingWeakRef). */
	if (!self.hpn_isDeallocing) {
		void (*setDelegateIMP)(id, SEL, id <UIScrollViewDelegate>) = (void (*)(id, SEL, id <UIScrollViewDelegate>))class_getMethodImplementation(self.class, @selector(setDelegate:));
		setDelegateIMP(self, @selector(setDelegate:), self.hpn_cheatDelegateCreateIfNotExist.originalScrollViewDelegate);
	}
	objc_setAssociatedObject(self, SCROLL_VIEW_EXTENDER_CHEAT_REFERENCE, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* Tells the table view the list of method the delegate responds to has changed. */
- (void)hpn_refreshDelegate
{
	/* Does not seem to be required, but to be symetric with refresh data source,
	 * I'll let this here. */
	if (self.hpn_isDeallocing) return;
	
	[self.hpn_cheatDelegateCreateIfNotExist refreshKnownOriginalResponds];
	
	id <UIScrollViewDelegate> delegate = self.delegate;
	void (*setDelegateIMP)(id, SEL, id <UIScrollViewDelegate>) = (void (*)(id, SEL, id <UIScrollViewDelegate>))class_getMethodImplementation(self.class, @selector(setDelegate:));
	setDelegateIMP(self, @selector(setDelegate:), nil);
	setDelegateIMP(self, @selector(setDelegate:), delegate);
}

- (void)setDelegate:(id <UIScrollViewDelegate>)delegate
{
	if ([delegate isKindOfClass:HPNScrollViewDelegateForHelptender.class])
		delegate = ((HPNScrollViewDelegateForHelptender *)delegate).originalScrollViewDelegate;
	
	self.hpn_cheatDelegateCreateIfNotExist.originalScrollViewDelegate = delegate;
	void (*setDelegateIMP)(id, SEL, id <UIScrollViewDelegate>) = (void (*)(id, SEL, id <UIScrollViewDelegate>))class_getMethodImplementation(self.class, @selector(setDelegate:));
	setDelegateIMP(self, @selector(setDelegate:), nil);
	setDelegateIMP(self, @selector(setDelegate:), self.hpn_cheatDelegateCreateIfNotExist);
}

@end



@implementation HPNScrollViewDelegateForHelptender

+ (instancetype)scrollViewDelegateForHelptenderFromScrollViewDelegateForHelptender:(HPNScrollViewDelegateForHelptender *)original
{
	HPNScrollViewDelegateForHelptender *ret = [self new];
	ret.linkedView = original.linkedView;
	ret.originalScrollViewDelegate = original.originalScrollViewDelegate;
	return ret;
}

- (void)dealloc
{
	self.originalScrollViewDelegate = nil;
}

- (void)refreshKnownOriginalResponds
{
	odRespondsToDidScroll = [self.originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)];
}

- (void)setOriginalScrollViewDelegate:(id <UIScrollViewDelegate>)delegate
{
	NSParameterAssert(![delegate isKindOfClass:HPNScrollViewDelegateForHelptender.class]);
	if (self.originalScrollViewDelegate == delegate)
		return;
	
	_originalScrollViewDelegate = delegate;
	if (_originalScrollViewDelegate != nil) previousNonNilOriginalDelegateClass = delegate.class;
	
	[self refreshKnownOriginalResponds];
}

- (void)scrollViewDidScroll:(HPNScrollViewHelptender *)scrollView
{
	NSParameterAssert(scrollView == self.linkedView);
	
	for (NSObject <HPNScrollViewExtender> *extender in scrollView.hpn_extendersDidScroll)
		[extender scrollViewDidScroll:scrollView];
	
	if (odRespondsToDidScroll)
		[self.originalScrollViewDelegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(HPNScrollViewHelptender *)scrollView willDecelerate:(BOOL)decelerate
{
	NSParameterAssert(scrollView == self.linkedView);
	
	for (NSObject <HPNScrollViewExtender> *extender in scrollView.hpn_extendersDidEndDragScrolling)
		[extender scrollViewDidEndDragScrolling:scrollView willDecelerate:decelerate];
	
	if ([self.originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)])
		[self.originalScrollViewDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewWillEndDragging:(HPNScrollViewHelptender *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
	NSParameterAssert(scrollView == self.linkedView);
	
	for (NSObject <HPNScrollViewExtender> *extender in scrollView.hpn_extendersWillEndDragScrolling)
		[extender scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
	
	if ([self.originalScrollViewDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)])
		[self.originalScrollViewDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDecelerating:(HPNScrollViewHelptender *)scrollView
{
	NSParameterAssert(scrollView == self.linkedView);
	
	for (NSObject <HPNScrollViewExtender> *extender in scrollView.hpn_extendersDidEndDeceleratingScroll)
		[extender scrollViewDidEndDecelerating:scrollView];
	
	if ([self.originalScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)])
		[self.originalScrollViewDelegate scrollViewDidEndDecelerating:scrollView];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return ([super respondsToSelector:aSelector] ||
			  [self.originalScrollViewDelegate respondsToSelector:aSelector]);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if ([self.originalScrollViewDelegate respondsToSelector:aSelector])
		return self.originalScrollViewDelegate;
	
	return [super forwardingTargetForSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	return ([super methodSignatureForSelector:aSelector]?:
			  [previousNonNilOriginalDelegateClass instanceMethodSignatureForSelector:aSelector]);
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
	[NSObject hpn_forwardInvocationLikeNil:anInvocation];
}

@end
