/*
 * main.m
 * Extenders
 *
 * Created by François LAMBOLEY on 29/04/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

#import "NSObject+Extender.h"
#import "HCObjectExtender.h"



@interface HCTestExtender : NSObject <HCObjectExtender>

- (void)objectDoStuff:(NSObject *)object;

@end

@implementation HCTestExtender

- (BOOL)prepareObjectForExtender:(NSObject *)object
{
	NSLog(@"Preparing object %@ for extender %@", object, self);
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(NSObject *)object
{
	NSLog(@"Preparing object %@ for removal of extender %@", object, self);
}

- (void)objectDoStuff:(NSObject *)object
{
	NSLog(@"Doing stuff with %@", object);
}

@end



@interface HCTestExtended : NSObject

@end

@implementation HCTestExtended

@end



int main(int argc, const char *argv[]) {
#pragma unused(argc, argv)
	@autoreleasepool {
		HCTestExtended *n = [[HCTestExtended new] autorelease];
		[n hc_addExtender:[[HCTestExtender new] autorelease]];
		[n doStuff];
		[n hc_removeExtendersOfClass:HCTestExtender.class];
	}
	
	return 0;
}
