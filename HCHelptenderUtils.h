/*
 * HCHelptenderUtils.h
 * Happn
 *
 * Created by François LAMBOLEY on 30/04/14.
 * Copyright (c) 2014 FTW & Co. All rights reserved.
 */

#import <objc/runtime.h>

#define HELPTENDER_CALL_SUPER_NO_ARGS(className) \
	class_getMethodImplementation([self hc_getSuperClassWithOriginalHelptenderClass:className.class], _cmd))(self, _cmd

#define HELPTENDER_CALL_SUPER(className, ...) \
	class_getMethodImplementation([self hc_getSuperClassWithOriginalHelptenderClass:className.class], _cmd))(self, _cmd, __VA_ARGS__

#define HELPTENDER_CALL_SUPER_WITH_SEL_NAME(className, sel_name, ...) \
	class_getMethodImplementation([self hc_getSuperClassWithOriginalHelptenderClass:className.class], @selector(sel_name)))(self, @selector(sel_name), __VA_ARGS__



@interface NSObject (ForHelptendersOnly)

- (Class)hc_getSuperClassWithOriginalHelptenderClass:(Class)originalHelptenderClass;

@end
