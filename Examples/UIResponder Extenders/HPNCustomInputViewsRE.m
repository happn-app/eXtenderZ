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

#import "HPNCustomInputViewsRE.h"

@import ObjectiveC.runtime;



@implementation HPNCustomInputViewsRE

- (instancetype)init
{
	if ((self = [super init]) != nil) {
		self.overrideInputView = YES;
		self.overrideInputAccessoryView = YES;
		self.overrideTextInputContextIdentifier = YES;
	}
	
	return self;
}

- (BOOL)prepareObjectForExtender:(NSObject *)object
{
#pragma unused(object)
	NSParameterAssert([object isKindOfClass:UIResponder.class]);
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(NSObject *)object
{
#pragma unused(object)
	NSParameterAssert([object isKindOfClass:UIResponder.class]);
}

- (TVL)responderCanBecomeFirstResponder:(UIResponder *)responder
{
#pragma unused(responder)
	if (self.inputAccessoryView != nil) return TVL_YES;
	else                                return TVL_NO;
}

- (UIView *)inputViewForResponder:(UIResponder *)responder
{
#pragma unused(responder)
	return self.inputView;
}

- (UIView *)inputAccessoryViewForResponder:(UIResponder *)responder
{
#pragma unused(responder)
	return self.inputAccessoryView;
}

- (NSString *)textInputContextIdentifierForResponder:(UIResponder *)responder
{
#pragma unused(responder)
	return self.textInputContextIdentifier;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
	if (sel_isEqual(aSelector, @selector(inputViewForResponder:)))                  return self.overrideInputView;
	if (sel_isEqual(aSelector, @selector(inputAccessoryViewForResponder:)))         return self.overrideInputAccessoryView;
	if (sel_isEqual(aSelector, @selector(textInputContextIdentifierForResponder:))) return self.overrideTextInputContextIdentifier;
	
	return [super respondsToSelector:aSelector];
}

@end
