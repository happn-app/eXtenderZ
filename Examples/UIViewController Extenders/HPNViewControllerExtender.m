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

#import "HPNViewControllerExtender.h"

@import eXtenderZ.HelptenderUtils;



static char EXTENDERS_DID_LAYOUT_SUBVIEWS_KEY;

@implementation HPNViewControllerHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNViewControllerExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(HPNViewControllerHelptender *)helptender
{
#pragma unused(helptender)
	/* Nothing to do here */
}

+ (void)hpn_helptenderWillBeRemoved:(HPNViewControllerHelptender *)helptender
{
#pragma unused(helptender)
	objc_setAssociatedObject(helptender, &EXTENDERS_DID_LAYOUT_SUBVIEWS_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersDidLayoutSubviews, EXTENDERS_DID_LAYOUT_SUBVIEWS_KEY)

- (BOOL)hpn_prepareForExtender:(NSObject <HPNExtender> *)extender
{
	if (!((BOOL (*)(id, SEL, NSObject <HPNExtender> *))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, extender))) return NO;
	
	if ([extender conformsToProtocol:@protocol(HPNViewControllerExtender)] &&
		 [extender respondsToSelector:@selector(viewControllerViewDidLayoutSubviews:)])
		[[self hpn_extendersDidLayoutSubviewsCreateIfNotExist:YES] addObject:extender];
	
	return YES;
}

- (void)hpn_removeExtender:(NSObject <HPNExtender> *)extender atIndex:(NSUInteger)idx
{
	[self.hpn_extendersDidLayoutSubviews removeObjectIdenticalTo:extender];
	
	((void (*)(id, SEL, NSObject <HPNExtender> *, NSUInteger))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, extender, idx));
}

- (void)viewDidLoad
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewControllerViewDidLoad:)])
			[extender viewControllerViewDidLoad:self];
	
	((void (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNViewControllerHelptender));
#ifdef __clang_analyzer__
	[super viewDidLoad];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:viewWillAppear:)])
			[extender viewController:self viewWillAppear:animated];
	
	((void (*)(id, SEL, BOOL))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, animated));
#ifdef __clang_analyzer__
	[super viewWillAppear:animated];
#endif
}

- (void)viewDidLayoutSubviews
{
	for (id <HPNViewControllerExtender> extender in self.hpn_extendersDidLayoutSubviews)
		[extender viewControllerViewDidLayoutSubviews:self];
	
	((void (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNViewControllerHelptender));
}

- (void)viewDidAppear:(BOOL)animated
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:viewDidAppear:)])
			[extender viewController:self viewDidAppear:animated];
	
	((void (*)(id, SEL, BOOL))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, animated));
#ifdef __clang_analyzer__
	[super viewDidAppear:animated];
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:viewWillDisappear:)])
			[extender viewController:self viewWillDisappear:animated];
	
	((void (*)(id, SEL, BOOL))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, animated));
#ifdef __clang_analyzer__
	[super viewWillDisappear:animated];
#endif
}

- (void)viewDidDisappear:(BOOL)animated
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:viewDidDisappear:)])
			[extender viewController:self viewDidDisappear:animated];
	
	((void (*)(id, SEL, BOOL))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, animated));
#ifdef __clang_analyzer__
	[super viewDidDisappear:animated];
#endif
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:prepareForSegue:sender:)])
			[extender viewController:self prepareForSegue:segue sender:sender];
	
	((void (*)(id, SEL, UIStoryboardSegue *, id))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, segue, sender));
#ifdef __clang_analyzer__
	[super prepareForSegue:segue sender:sender];
#endif
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:didMoveToParentViewController:)])
			[extender viewController:self didMoveToParentViewController:parent];
	
	((void (*)(id, SEL, UIViewController *))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, parent));
#ifdef __clang_analyzer__
	[super didMoveToParentViewController:parent];
#endif
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewControllerPreferredStatusBarStyle:)])
			return [extender viewControllerPreferredStatusBarStyle:self];
	
	return ((UIStatusBarStyle (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNViewControllerHelptender));
#ifdef __clang_analyzer__
	return [super preferredStatusBarStyle];
#endif
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
	for (id <HPNViewControllerExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewControllerExtender)])
		if ([extender respondsToSelector:@selector(viewController:willMoveToParentViewController:)])
			[extender viewController:self willMoveToParentViewController:parent];
	
	((void (*)(id, SEL, UIViewController *))HPN_HELPTENDER_CALL_SUPER(HPNViewControllerHelptender, parent));
#ifdef __clang_analyzer__
	[super willMoveToParentViewController:parent];
#endif
}

@end
