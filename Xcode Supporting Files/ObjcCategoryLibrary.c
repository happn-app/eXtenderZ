/*
 * ObjcCategoryLibrary.c
 * eXtenderZ
 *
 * Created by François Lamboley on 11/22/14.
 * Copyright (c) 2014-2018 happn. All rights reserved.
 */

/* See http://stackoverflow.com/questions/2567498/objective-c-categories-in-static-library
 * Objective-c categories are not real symbols. So a lib with only categories
 * is seen as empty by the linker and it compiles with a warning. To get rid of
 * the warning, this symbol is added to categories-only libs. */
void _eXtenderZ_heyTheresARealSymbolInThisLib_(void) {}
