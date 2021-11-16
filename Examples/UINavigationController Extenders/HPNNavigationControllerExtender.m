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

#import "HPNNavigationControllerExtender.h"

@import ObjectiveC.runtime;

@import eXtenderZ.HelptenderUtils;



static char CHEAT_DELEGATE;

@implementation HPNNavigationControllerHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNNavigationControllerExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(HPNNavigationControllerHelptender *)helptender
{
	[helptender hpn_overrideDelegate];
}

+ (void)hpn_helptenderWillBeRemoved:(HPNNavigationControllerHelptender *)helptender
{
	[helptender hpn_resetDelegate];
	objc_setAssociatedObject(helptender, &CHEAT_DELEGATE, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hpn_prepareForExtender:(NSObject <HPNExtender> *)extender
{
	if (!((BOOL (*)(id, SEL, NSObject <HPNExtender> *))HPN_HELPTENDER_CALL_SUPER(HPNNavigationControllerHelptender, extender))) return NO;
	
	if ([extender conformsToProtocol:@protocol(HPNNavigationControllerExtender)]) {
		[self hpn_refreshDelegate];
	}
	
	return YES;
}

- (void)hpn_removeExtender:(NSObject <HPNExtender> *)extender atIndex:(NSUInteger)idx
{
	if ([extender conformsToProtocol:@protocol(HPNNavigationControllerExtender)]) {
		[self hpn_refreshDelegate];
	}
	
	((void (*)(id, SEL, NSObject <HPNExtender> *, NSUInteger))HPN_HELPTENDER_CALL_SUPER(HPNNavigationControllerHelptender, extender, idx));
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
	UIViewController *ret = ((UIViewController *(*)(id, SEL, BOOL))HPN_HELPTENDER_CALL_SUPER(HPNNavigationControllerHelptender, animated));
	
	for (id <HPNNavigationControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNNavigationControllerExtender)])
		if ([extender respondsToSelector:@selector(navigationController:didPopViewController:animated:)])
			[extender navigationController:self didPopViewController:ret animated:animated];
	
	return ret;
#ifdef __clang_analyzer__
	return [super popViewControllerAnimated:animated];
#endif
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	((void (*)(id, SEL, UIViewController *, BOOL))HPN_HELPTENDER_CALL_SUPER(HPNNavigationControllerHelptender, viewController, animated));
	
	for (id <HPNNavigationControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNNavigationControllerExtender)])
		if ([extender respondsToSelector:@selector(navigationController:didPushViewController:animated:)])
			[extender navigationController:self didPushViewController:viewController animated:animated];
	
#ifdef __clang_analyzer__
	[super pushViewController:viewController animated:animated];
#endif
}

#pragma mark - Delegate Overriding

- (HPNNavigationControllerDelegateForHelptender *)hpn_cheatDelegateCreateIfNotExist
{
	HPNNavigationControllerDelegateForHelptender *ret = (HPNNavigationControllerDelegateForHelptender *)[self hpn_getAssociatedObjectWithKey:&CHEAT_DELEGATE createIfNotExistWithBlock:^id {
		HPNNavigationControllerDelegateForHelptender *retIn = [HPNNavigationControllerDelegateForHelptender new];
		retIn.linkedNavigationController = self;
		return retIn;
	}];
	
	NSAssert([ret isKindOfClass:HPNNavigationControllerDelegateForHelptender.class], @"***** INTERNAL ERROR: Got invalid (not of class HPNNavigationControllerDelegateForHelptender) associated object %@ in %@", ret, NSStringFromSelector(_cmd));
	NSAssert(ret.linkedNavigationController == self, @"***** INTERNAL ERROR: Got invalid linked navigation controller %@ for navigation controller %@", ret.linkedNavigationController, self);
	return ret;
}

- (void)hpn_overrideDelegate
{
	NSParameterAssert(![self.delegate isKindOfClass:HPNNavigationControllerDelegateForHelptender.class]);
	self.delegate = self.delegate;
}

- (void)hpn_resetDelegate
{
	void (*setDelegateIMP)(id, SEL, id <UINavigationControllerDelegate>) = (void (*)(id, SEL, id <UINavigationControllerDelegate>))class_getMethodImplementation(self.class, @selector(setDelegate:));
	setDelegateIMP(self, @selector(setDelegate:), self.hpn_cheatDelegateCreateIfNotExist.originalNavigationControllerDelegate);
	objc_setAssociatedObject(self, &CHEAT_DELEGATE, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/* Tells the table view the list of method the delegate responds to has changed. */
- (void)hpn_refreshDelegate
{
	id <UINavigationControllerDelegate> delegate = self.delegate;
	void (*setDelegateIMP)(id, SEL, id <UINavigationControllerDelegate>) = (void (*)(id, SEL, id <UINavigationControllerDelegate>))class_getMethodImplementation(self.class, @selector(setDelegate:));
	setDelegateIMP(self, @selector(setDelegate:), nil);
	setDelegateIMP(self, @selector(setDelegate:), delegate);
}

- (void)setDelegate:(id <UINavigationControllerDelegate>)delegate
{
	if ([delegate isKindOfClass:HPNNavigationControllerDelegateForHelptender.class])
		delegate = ((HPNNavigationControllerDelegateForHelptender *)delegate).originalNavigationControllerDelegate;
	
	self.hpn_cheatDelegateCreateIfNotExist.originalNavigationControllerDelegate = delegate;
	void (*setDelegateIMP)(id, SEL, id <UINavigationControllerDelegate>) = (void (*)(id, SEL, id <UINavigationControllerDelegate>))class_getMethodImplementation(self.class, @selector(setDelegate:));
	setDelegateIMP(self, @selector(setDelegate:), nil);
	setDelegateIMP(self, @selector(setDelegate:), self.hpn_cheatDelegateCreateIfNotExist);
}

@end



@implementation HPNNavigationControllerDelegateForHelptender

- (void)dealloc
{
	self.originalNavigationControllerDelegate = nil;
}

- (void)setOriginalNavigationControllerDelegate:(id <UINavigationControllerDelegate>)delegate
{
	NSParameterAssert(![delegate isKindOfClass:HPNNavigationControllerDelegateForHelptender.class]);
	if (self.originalNavigationControllerDelegate == delegate)
		return;
	
	_originalNavigationControllerDelegate = delegate;
	if (_originalNavigationControllerDelegate != nil) previousNonNilOriginalDelegateClass = delegate.class;
}

- (void)navigationController:(HPNNavigationControllerHelptender *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	NSParameterAssert(navigationController == self.linkedNavigationController);
	
	for (NSObject <HPNNavigationControllerExtender> *extender in [navigationController hpn_extendersConformingToProtocol:@protocol(HPNNavigationControllerExtender)])
		if ([extender respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
			[extender navigationController:navigationController willShowViewController:viewController animated:animated];
	
	if ([self.originalNavigationControllerDelegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[self.originalNavigationControllerDelegate navigationController:navigationController willShowViewController:viewController animated:animated];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	return ([super respondsToSelector:aSelector] ||
			  [self.originalNavigationControllerDelegate respondsToSelector:aSelector]);
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if ([self.originalNavigationControllerDelegate respondsToSelector:aSelector])
		return self.originalNavigationControllerDelegate;
	
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
