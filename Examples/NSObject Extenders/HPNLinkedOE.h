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

@import Foundation;

@import eXtenderZ;


/* Abstract implementation of an object extender. The class guarantees the
 * extender will be linked to one and only one object.
 *
 * Subclasses must call super for the following methods:
 *    - (BOOL)prepareObjectForExtender:(HPNExtendedViewController *)viewController;
 *    - (void)prepareObjectForRemovalOfExtender:(HPNExtendedViewController *)viewController;
 *
 * Note: When calling super for the prepareObjectForExtender: method, the
 *       subclass must know for certain it won't refuse adding the given view
 *       controller. Example of implementation:
 * - (BOOL)prepareObjectForExtender:(NSObject *)object
 * {
 *		if (!test to know if can add object) return NO;
 *		if (![super prepareObjectForExtender:object]) return NO;
 *
 *		... init stuff; nothing can go wrong here ...
 *		return YES;
 * }
 *
 *
 * Subclasses should override the following method:
 *    + (Class)linkedClass;
 * Default implementation returns NSObject.
 */
@interface HPNLinkedOE : NSObject <HPNExtender>

/* Should be overridden. Default implementation returns NSObject.class */
- (Class)linkedClass;

/* Will always at least be an NSObject. Set to id so subclasses
 * can redefine the property with a concrete class */
@property(nonatomic, readonly, weak) id linkedObject;

- (BOOL)prepareObjectForExtender:(NSObject *)object;
- (void)prepareObjectForRemovalOfExtender:(NSObject *)object;

@end
