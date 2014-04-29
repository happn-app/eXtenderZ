/*
 * NSObject+HCUtils.h
 * Happn
 *
 * Created by François LAMBOLEY on 28/02/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <objc/runtime.h>



@interface NSObject (HCUtils)

/* Convenient method to get associated object with automatic creation if the
 * object does not exist. If the block is NULL, the object is not auto-created.
 * In case the object must be created, it is created using the creator block,
 * then associated to the object with the given association policy. If
 * releaseAfterCreation is true, the newly created object will be released after
 * it is associated.
 * The return value won't necessarily be the object returned by the creator
 * block (in case for instance the association policy is OBJC_ASSOCIATION_COPY).
 * Using this method is thread-safe. */
- (id)hc_getAssociatedObjectWithKey:(void *)key
			 createIfNotExistWithBlock:(id (^)(void))objectCreator releaseCreatedObject:(BOOL)releaseAfterCreation
						associationPolicy:(objc_AssociationPolicy)associationPolicy;

/* Same as above, with releaseAfterCreation set to YES, associationPolicy set
 * to OBJC_ASSOCIATION_RETAIN_NONATOMIC */
- (id)hc_getAssociatedObjectWithKey:(void *)key createIfNotExistWithBlock:(id (^)(void))objectCreator;

@end
