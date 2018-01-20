/*
 * HCUtils.m
 * Happn
 *
 * Created by François LAMBOLEY on 8/6/11.
 * Copyright 2011 FTW & Co. All rights reserved.
 */

#import "HCUtils.h"



/* Tricks the localize.sh script into thinking these are actually used:
 *    NSLocalizedString(@"opening double-quote", @"Eg. in English: “");
 *    NSLocalizedString(@"closing double-quote", @"Eg. in English: ”");
 */

@implementation HCUtils

+ (void)raiseAbstractClassException
{
	[NSException raise:@"Abstract Class Instanstation" format:@"Cannot instantiate the pure abstract class HCUtils"];
}

+ (id)allocWithZone:(NSZone *)zone
{
#pragma unused(zone)
	[self raiseAbstractClassException];
	return nil;
}

- (id)init
{
	[HCUtils raiseAbstractClassException];
	return nil;
}

+ (void)load
{
	srandom((unsigned int)time(NULL));
}

@end
