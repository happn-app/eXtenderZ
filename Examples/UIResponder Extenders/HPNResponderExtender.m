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

#import "HPNResponderExtender.h"

@import eXtenderZ.HelptenderUtils;



@implementation HPNResponderHelptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNResponderExtender)];
}

+ (void)hpn_helptenderHasBeenAdded:(HPNResponderHelptender *)helptender
{
#pragma unused(helptender)
	/* Nothing to do here */
}

+ (void)hpn_helptenderWillBeRemoved:(HPNResponderHelptender *)helptender
{
#pragma unused(helptender)
	/* Nothing to do here */
}

/* Removed because we do nothing special here:
- (BOOL)hpn_prepareForExtender:(NSObject <HPNExtender> *)extender
{
	if (!((BOOL (*)(id, SEL, NSObject <HPNExtender> *))HELPTENDER_CALL_SUPER(HPNResponderHelptender, extender))) return NO;
	// nop
	return YES;
}*/

/* Removed because we do nothing special here:
- (void)hpn_removeExtender:(NSObject <HPNExtender> *)extender atIndex:(NSUInteger)idx
{
	// nop
	((void (*)(id, SEL, NSObject <HPNExtender> *, NSUInteger))HELPTENDER_CALL_SUPER(HPNResponderHelptender, extender, idx));
}*/

- (BOOL)canBecomeFirstResponder
{
	for (id <HPNResponderExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNResponderExtender)]) {
		if ([extender respondsToSelector:@selector(responderCanBecomeFirstResponder:)]) {
			TVL flag = [extender responderCanBecomeFirstResponder:self];
			if (flag == TVL_MAYBE) continue;
			return flag;
		}
	}
	
	return ((BOOL (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNResponderHelptender));
}

- (UIView *)inputView
{
	for (id <HPNResponderExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNResponderExtender)])
		if ([extender respondsToSelector:@selector(inputViewForResponder:)])
			return [extender inputViewForResponder:self];
	
	return ((UIView *(*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNResponderHelptender));
}

- (UIView *)inputAccessoryView
{
	for (id <HPNResponderExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNResponderExtender)])
		if ([extender respondsToSelector:@selector(inputAccessoryViewForResponder:)])
			return [extender inputAccessoryViewForResponder:self];
	
	return ((UIView *(*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNResponderHelptender));
}

- (NSString *)textInputContextIdentifier
{
	for (id <HPNResponderExtender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNResponderExtender)])
		if ([extender respondsToSelector:@selector(textInputContextIdentifierForResponder:)])
			return [extender textInputContextIdentifierForResponder:self];
	
	return ((NSString *(*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNResponderHelptender));
}

@end
