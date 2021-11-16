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

#import "HPNLinkedOE.h"



@implementation HPNLinkedOE

- (Class)linkedClass
{
	return NSObject.class;
}

- (BOOL)prepareObjectForExtender:(NSObject *)object
{
	NSAssert([self.linkedClass isSubclassOfClass:NSObject.class], @"***** Error: Invalid linked class %@ for an HPNLinkedVCE", NSStringFromClass(self.linkedClass));
	if (_linkedObject != nil || ![object isKindOfClass:self.linkedClass])
		return NO;
	
	_linkedObject = object;
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(NSObject *)object
{
#pragma unused(object)
	/* _linkedObject can be nil as it is weak. */
	NSAssert(_linkedObject == nil || object == _linkedObject, @"***** Error: Asked to prepare for removal of extender in linked OE, with object (%@) != _linkedObject (%@)", object, _linkedObject);
	_linkedObject = nil;
}

@end
