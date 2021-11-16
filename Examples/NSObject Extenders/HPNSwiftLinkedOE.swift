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

import Foundation



/** Abstract implementation of an object extender. The class guarantees the
extender will be linked to one and only one object, of class T.

Subclasses must call super for the following methods:

- `func prepareObjectForExtender(object: NSObject!) -> Bool`
- `func prepareObjectForRemovalOfExtender(object: NSObject!)`


- Important: When calling super for the prepareObjectForExtender: method, the
subclass must know for certain it won't refuse adding the given view controller.
Example of implementation:
```
override func prepareObjectForExtender(object: NSObject!) -> Bool {
   guard test_to_know_if_can_add_extender else {return false}
   guard super.prepareObject(forExtender: object) else {return false}

   ... init stuff; nothing can go wrong here ...
   return true
}
*/
class HPNSwiftLinkedOE<T : NSObject> : NSObject, HPNExtender {
	
	weak private(set) var linkedObject: T?
	
	func prepareObject(forExtender object: NSObject) -> Bool {
		guard linkedObject == nil, let t = object as? T else {return false}
		
		linkedObject = t
		return true
	}
	
	func prepareObjectForRemoval(ofExtender object: NSObject) {
		/* linkedObject can be nil as it is weak. */
		assert(linkedObject == nil || object === linkedObject, "***** ERROR: Asked to prepare for removal of extender in linked OE, with object (\(String(describing: object))) != _linkedObject (\(String(describing: linkedObject)))")
		linkedObject = nil;
	}
	
}
