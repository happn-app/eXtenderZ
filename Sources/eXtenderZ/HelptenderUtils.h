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

@import ObjectiveC.runtime;



NS_ASSUME_NONNULL_BEGIN


#define HPN_HELPTENDER_CALL_SUPER_NO_ARGS(className) \
	class_getMethodImplementation([self hpn_getSuperClassWithOriginalHelptenderClass:className.class], _cmd))(self, _cmd

#define HPN_HELPTENDER_CALL_SUPER(className, ...) \
	class_getMethodImplementation([self hpn_getSuperClassWithOriginalHelptenderClass:className.class], _cmd))(self, _cmd, __VA_ARGS__

#define HPN_HELPTENDER_CALL_SUPER_WITH_SEL_NAME(className, sel_name, ...) \
	class_getMethodImplementation([self hpn_getSuperClassWithOriginalHelptenderClass:className.class], @selector(sel_name)))(self, @selector(sel_name), __VA_ARGS__


@interface NSObject (ForHelptendersOnly)

- (Class)hpn_getSuperClassWithOriginalHelptenderClass:(Class)originalHelptenderClass;

@end


/* *** */

#define HPN_DYNAMIC_ACCESSOR(type, name, key)                                                                                                                                            \
	- (nullable type *)name                                                                                                                                                               \
	{                                                                                                                                                                                     \
		return [self name##CreateIfNotExist:NO];                                                                                                                                           \
	}                                                                                                                                                                                     \
	                                                                                                                                                                                      \
	- (nullable type *)name##CreateIfNotExist:(BOOL)createIfNeeded                                                                                                                        \
	{                                                                                                                                                                                     \
		id ret = [self hpn_getAssociatedObjectWithKey:&key createIfNotExistWithBlock:(createIfNeeded? ^id{                                                                                 \
			return [[type alloc] initWithCapacity:7];                                                                                                                                       \
		}: NULL)];                                                                                                                                                                         \
																																																													  \
		NSAssert(ret == nil || [ret isKindOfClass:type.class], @"***** INTERNAL ERROR: Got invalid (not of class "S(type)") associated object %@ in %@", ret, NSStringFromSelector(_cmd)); \
		return ret;                                                                                                                                                                        \
	}


NS_ASSUME_NONNULL_END
