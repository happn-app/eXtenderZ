/*
 * HCUtils.h
 * Happn
 *
 * Pure abstract class for some utility stuff.
 *
 * Created by François LAMBOLEY on 8/6/11.
 * Copyright 2011 FTW & Co. All rights reserved.
 */

#import <Foundation/Foundation.h>



/* Stringification */
# define _sharp(x) #x
# define S(x) _sharp(x)



/* Static assert */
#define STATIC_ASSERT(test, msg) typedef char _static_assert_##msg[((test)? 1: -1)]



/* Implements a static const variable */
#define IMPLEMENT_NAMED_STATIC_CONST(static_var_name, type, ...) \
	static type *static_var_name = nil; \
	static dispatch_once_t static_var_name##onceToken; \
	dispatch_once(&static_var_name##onceToken, ^{ \
		static_var_name = [[type alloc] __VA_ARGS__]; \
	})

#define IMPLEMENT_STATIC_CONST(type, ...) IMPLEMENT_NAMED_STATIC_CONST(staticVar, type, __VA_ARGS__)



/* Formats for NSLog for NSInteger, CGFloat, etc. */
#define CGFLOAT_FMT @"g"
/* See definition of NSUInteger to understand the test below */
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
# define NSINT_FMT @"ld"
# define NSUINT_FMT @"lu"
#else
# define NSINT_FMT @"d"
# define NSUINT_FMT @"u"
#endif



#ifdef DEBUG
# define NSDLog(...) NSLog(__VA_ARGS__)
#else
# define NSDLog(...) (void)NULL
#endif

/* Allows to remove a known and irrelevant warning when code is analysed.
 * Please specify why the warning is irrelevant when using these macros. */
#ifndef __clang_analyzer__
/* Code is not analysed */
# define HC_LEAK_RETAIN(arg)         [(arg) retain]
# define HC_FALSE_RELEASE(arg)       ((void)0)
# define HC_FALSE_AUTORELEASE(arg)   (arg)
# define HC_INVALID_RELEASE(arg)     [(arg) release]
# define HC_INVALID_AUTORELEASE(arg) [(arg) autorelease]
#else
/* Code is analysed */
# define HC_LEAK_RETAIN(arg)         (arg)
# define HC_FALSE_RELEASE(arg)       [(arg) release]
# define HC_FALSE_AUTORELEASE(arg)   [(arg) autorelease]
# define HC_INVALID_RELEASE(arg)     ((void)0)
# define HC_INVALID_AUTORELEASE(arg) ((void)0)
#endif



@interface HCUtils : NSObject

/* See HCUtils+... files */

@end
