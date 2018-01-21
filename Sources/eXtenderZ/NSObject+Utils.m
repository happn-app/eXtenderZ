/*
 * NSObject+Utils.m
 * eXtenderZ
 *
 * Created by François LAMBOLEY on 28/02/14.
 * Copyright (c) 2014-2018 happn. All rights reserved.
 */

#import "NSObject+Utils.h"



#define DEFAULT_BUFFER_LENGTH (16)

@implementation NSObject (HPNUtils)

+ (void)hpn_forwardInvocationLikeNil:(NSInvocation *)invocation
{
	if (invocation.methodSignature.methodReturnLength == 0)
		return;
	
	void *dynamicBuffer = NULL;
	char staticBuffer[DEFAULT_BUFFER_LENGTH] = {'\0'};
	
	void *ret = &staticBuffer;
	if (invocation.methodSignature.methodReturnLength > DEFAULT_BUFFER_LENGTH) {
		dynamicBuffer = calloc(invocation.methodSignature.methodReturnLength, 1);
		ret = dynamicBuffer;
	}
	
	[invocation setReturnValue:ret];
	
	if (dynamicBuffer != NULL) free(dynamicBuffer);
}

- (id)hpn_getAssociatedObjectWithKey:(void *)key
			  createIfNotExistWithBlock:(id (^)(void))objectCreator
						 associationPolicy:(objc_AssociationPolicy)associationPolicy
{
	id ret = objc_getAssociatedObject(self, key);
	if (ret == nil && objectCreator != NULL) {
		@synchronized(self) {
			ret = objc_getAssociatedObject(self, key);
			if (ret == nil) {
				ret = objectCreator();
				objc_setAssociatedObject(self, key, ret, associationPolicy);
				
				/* In case associationPolicy is OBJC_ASSOCIATION_COPY for instance,
				 * we must get the new associated object. */
				ret = objc_getAssociatedObject(self, key);
			}
		}
	}
	
	return ret;
}

- (id)hpn_getAssociatedObjectWithKey:(void *)key createIfNotExistWithBlock:(id (^)(void))objectCreator
{
	return [self hpn_getAssociatedObjectWithKey:key createIfNotExistWithBlock:objectCreator associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
}

- (id)hpn_getAssociatedObjectWithKey:(void *)key
{
	return [self hpn_getAssociatedObjectWithKey:key createIfNotExistWithBlock:NULL associationPolicy:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
}

@end
