/*
 * NSObject+Utils.h
 * eXtenderZ
 *
 * Created by François LAMBOLEY on 28/02/14.
 * Copyright (c) 2014-2018 happn. All rights reserved.
 */

@import Foundation;
@import ObjectiveC.runtime;



@interface NSObject (HPNUtils)

+ (void)hpn_forwardInvocationLikeNil:(NSInvocation *)invocation;

/* Convenient method to get associated object with automatic creation if the
 * object does not exist. If the block is NULL, the object is not auto-created.
 * In case the object must be created, it is created using the creator block,
 * then associated to the object with the given association policy.
 * The return value won't necessarily be the object returned by the creator
 * block (in case for instance the association policy is OBJC_ASSOCIATION_COPY).
 * Using this method is thread-safe. */
- (id)hpn_getAssociatedObjectWithKey:(void *)key
			  createIfNotExistWithBlock:(id (^)(void))objectCreator
						 associationPolicy:(objc_AssociationPolicy)associationPolicy;

/* Same as above, with releaseAfterCreation set to YES, associationPolicy set
 * to OBJC_ASSOCIATION_RETAIN_NONATOMIC */
- (id)hpn_getAssociatedObjectWithKey:(void *)key createIfNotExistWithBlock:(id (^)(void))objectCreator;
/* Get the associated object for the given key (same as calling objc_getAssociatedObject). */
- (id)hpn_getAssociatedObjectWithKey:(void *)key;

@end
