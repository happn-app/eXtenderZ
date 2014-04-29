/*
 * NSObject+HCUtils.m
 * Happn
 *
 * Created by François LAMBOLEY on 28/02/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import "NSObject+HCUtils.h"



@implementation NSObject (HCUtils)

- (id)hc_getAssociatedObjectWithKey:(void *)key
			 createIfNotExistWithBlock:(id (^)(void))objectCreator releaseCreatedObject:(BOOL)releaseAfterCreation
						associationPolicy:(objc_AssociationPolicy)associationPolicy
{
	id ret = objc_getAssociatedObject(self, key);
	if (ret == nil && objectCreator != NULL) {
		@synchronized(self) {
			ret = objc_getAssociatedObject(self, key);
			if (ret == nil) {
				ret = objectCreator();
				objc_setAssociatedObject(self, key, ret, associationPolicy);
				if (releaseAfterCreation) [ret release];
				
				/* In case associationPolicy is OBJC_ASSOCIATION_COPY for instance,
				 * we must get the new associated object. */
				ret = objc_getAssociatedObject(self, key);
			}
		}
	}
	
	return ret;
}

- (id)hc_getAssociatedObjectWithKey:(void *)key createIfNotExistWithBlock:(id (^)(void))objectCreator
{
	return [self hc_getAssociatedObjectWithKey:key createIfNotExistWithBlock:objectCreator releaseCreatedObject:YES associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
}

@end
