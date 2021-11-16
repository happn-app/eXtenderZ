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

@import Foundation;
@import ObjectiveC.runtime;



NS_ASSUME_NONNULL_BEGIN

@interface NSObject (HPNUtils)

+ (void)hpn_forwardInvocationLikeNil:(NSInvocation *)invocation;

/**
 Convenient method to get associated object with automatic creation if the object does not exist.
 
 If the block is @c NULL@endc, the object is not auto-created.
 In case the object must be created, it is created using the creator block, then associated to the object with the given association policy.
 
 The return value won’t necessarily be the object returned by the creator block (in case for instance the association policy is @c OBJC_ASSOCIATION_COPY@endc).
 
 Using this method is thread-safe. */
- (nullable id)hpn_getAssociatedObjectWithKey:(void *)key
						  createIfNotExistWithBlock:(id (^_Nullable)(void))objectCreator
									 associationPolicy:(objc_AssociationPolicy)associationPolicy;

/** Same as above, with @c releaseAfterCreation set to @c YES, associationPolicy set to @c OBJC_ASSOCIATION_RETAIN_NONATOMIC@endc. */
- (nullable id)hpn_getAssociatedObjectWithKey:(void *)key createIfNotExistWithBlock:(id (^_Nullable)(void))objectCreator;
/** Get the associated object for the given key (same as calling @c objc_getAssociatedObject@endc). */
- (nullable id)hpn_getAssociatedObjectWithKey:(void *)key;

@end

NS_ASSUME_NONNULL_END
