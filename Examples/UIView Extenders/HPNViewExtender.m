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

#import "HPNViewExtender.h"

@import eXtenderZ.HelptenderUtils;



static char EXTENDERS_FRAME_CHANGE_KEY;

@implementation HPNViewHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNViewExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(HPNViewHelptender *)helptender
{
#pragma unused(helptender)
	/* Nothing to do here */
}

+ (void)hpn_helptenderWillBeRemoved:(HPNViewHelptender *)helptender
{
	objc_setAssociatedObject(helptender, &EXTENDERS_FRAME_CHANGE_KEY, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

HPN_DYNAMIC_ACCESSOR(NSMutableArray, hpn_extendersFrameChange, EXTENDERS_FRAME_CHANGE_KEY)

- (BOOL)hpn_prepareForExtender:(NSObject <HPNExtender> *)extender
{
	if (!((BOOL (*)(id, SEL, NSObject <HPNExtender> *))HPN_HELPTENDER_CALL_SUPER(HPNViewHelptender, extender))) return NO;
	
	if ([extender conformsToProtocol:@protocol(HPNViewExtender)] &&
		 [extender respondsToSelector:@selector(viewDidChangeFrame:originalFrame:)])
		[[self hpn_extendersFrameChangeCreateIfNotExist:YES] addObject:extender];
	
	return YES;
}

- (void)hpn_removeExtender:(NSObject <HPNExtender> *)extender atIndex:(NSUInteger)idx
{
	[self.hpn_extendersFrameChange removeObjectIdenticalTo:extender];
	
	((void (*)(id, SEL, NSObject <HPNExtender> *, NSUInteger))HPN_HELPTENDER_CALL_SUPER(HPNViewHelptender, extender, idx));
}

- (void)setFrame:(CGRect)frame
{
	CGRect ori = self.frame;
	
	((void (*)(id, SEL, CGRect))HPN_HELPTENDER_CALL_SUPER(HPNViewHelptender, frame));
	
	for (id <HPNViewExtender> extender in self.hpn_extendersFrameChange)
		[extender viewDidChangeFrame:self originalFrame:ori];
}

- (void)setCenter:(CGPoint)center
{
	CGRect ori = self.frame;
	
	((void (*)(id, SEL, CGPoint))HPN_HELPTENDER_CALL_SUPER(HPNViewHelptender, center));
	
	for (id <HPNViewExtender> extender in self.hpn_extendersFrameChange)
		[extender viewDidChangeFrame:self originalFrame:ori];
}

- (void)layoutSubviews
{
	CGRect ori = self.frame;
	
	((void (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNViewHelptender));
	
	for (id <HPNViewExtender> extender in self.hpn_extendersFrameChange)
		[extender viewDidChangeFrame:self originalFrame:ori];
}

- (void)layoutSublayersOfLayer:(CALayer *)layer
{
	((void (*)(id, SEL, CALayer *))HPN_HELPTENDER_CALL_SUPER(HPNViewHelptender, layer));
	
	for (id <HPNViewExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNViewExtender)])
		if ([extender respondsToSelector:@selector(view:layoutSublayersOfLayer:)])
			[extender view:self layoutSublayersOfLayer:layer];
}

@end
