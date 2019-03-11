/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#import "HPNSimpleObjectHelptender.h"

@import eXtenderZ.HelptenderUtils;



@implementation HPNSimpleObject0Helptender

+ (void)load
{
	[self hpn_registerClass:self asHelptenderForProtocol:@protocol(HPNSimpleObject0Extender)];
}

+ (void)hpn_helptenderHasBeenAdded:(NSObject <HPNHelptender> *)helptender
{
#pragma unused(helptender)
	/* Nothing do to here */
}

+ (void)hpn_helptenderWillBeRemoved:(NSObject <HPNHelptender> *)helptender
{
#pragma unused(helptender)
	/* Nothing do to here */
}

- (void)test1
{
	witnesses[@"HPNSimpleObject0Helptender-test1"] = @(witnesses[@"HPNSimpleObject0Helptender-test1"].integerValue + 1);
	
	for (id <HPNSimpleObject0Extender> extender in [self hpn_extendersConformingToProtocol:@protocol(HPNSimpleObject0Extender)])
		if ([extender respondsToSelector:@selector(didCallTest1)])
			[extender didCallTest1];
	
	((void (*)(id, SEL))HPN_HELPTENDER_CALL_SUPER_NO_ARGS(HPNSimpleObject0Helptender));
}

@end
