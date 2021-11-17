/*
Copyright 2021 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

#ifndef HPN_PreprocessorUtils_h
# define HPN_PreprocessorUtils_h


# import <inttypes.h>


/* Stringification */
# define _sharp(x) #x
# define S(x) _sharp(x)


/* Static assert */
# define STATIC_ASSERT(test, msg) typedef char _static_assert_##msg[((test)? 1: -1)]


/* Formats for NSLog for NSInteger, CGFloat, etc. */
# define CGFLOAT_FMT @"g"
/* See definition of NSUInteger to understand the test below */
# if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
#  define NSINT_FMT @"ld"
#  define NSUINT_FMT @"lu"
# else
#  define NSINT_FMT @"d"
#  define NSUINT_FMT @"u"
# endif


#endif /* HPN_PreprocessorUtils_h */
