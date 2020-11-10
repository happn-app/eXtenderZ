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

/*
 * Use this file to import your target's public headers that you would like to
 * expose to Swift.
 *
 * “Funny” note: This file (it is presumably this file) must not be along a file
 * called module.modulemap or the test target will use the given the modulemap
 * as its own, and compilation will fail.
 */

#import "HPNSimpleObject.h"
#import "HPNSimpleObjectHelptender.h"





#ifndef HPN_RealSymbolFunctionForCodeCoverage_h
# define HPN_RealSymbolFunctionForCodeCoverage_h

/* Expose this function so we can call it to have a better code coverage… */
void _eXtenderZ_heyTheresARealSymbolInThisLib_(void);

#endif /* HPN_RealSymbolFunctionForCodeCoverage_h */
