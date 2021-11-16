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

@import UIKit;

@import eXtenderZ;

#import "HPNScrollViewExtender.h"



/* WARNING: When using an extended table view, if you plan to use extenders that
 * transform the section/row indexes, you should always use the
 *    hpn_transformedIndexPath:
 * and
 *    hpn_transformedSectionIndex:
 * to get the actual row/section index to or from a datasource row/section index
 * (as the transformation is a bijection, transforming from or to actual
 * row/section is the same operation). */

@protocol HPNTableViewExtender <HPNExtender>
@optional

/*****************************************/
/* *** Configuration of the extender *** */

/* Default (when not implemented) is NO.
 * If implementation returns YES, the extender can use the
 * viewInTableHeaderForExtender: (resp. viewInTableFooterForExtender:)
 * method to get their views in the header (resp. footer) view of the
 * table view. The methods can be used even in the prepareTableViewForExtender:
 * method implementation of the extender.
 * The view initial frame will be for a header view:
 *    CGRectMake(0., <tableheaderview>.bounds.size.height, <tableheaderview>.bounds.size.width, 0.)
 * resp., for a footer view:
 *    CGRectMake(0., 0., <tableheaderview>.bounds.size.width, 0.)
 * The initial autoresizing mask will be for a header view:
 *    UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin
 * resp., for a footer view:
 *    UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin
 * When the extender is removed from a table view, its associated subview in the
 * header or footer view will be removed. However, the size of the header/footer
 * view won't be modified automatically, you have to do it in the
 * prepareObjectForRemovalOfExtender: method. */
- (BOOL)needsSubviewInTableHeaderView;
- (BOOL)needsSubviewInTableFooterView;



/***************************/
/* *** Transformations *** */

/* Gives the extender an opportunity to divide a section into more subsections.
 * The transformedSectionIndexFrom:..., transformedRowIndexFrom:... must of
 * course be implemented when implementing these methods.
 * It is also an error to implement the first of these method but not the second
 * one or vice-versa. */
- (NSInteger)transformedNumberOfSectionsFrom:(NSInteger)numberOfSections inTableView:(UITableView *)tableView;
- (NSInteger)transformedNumberOfRowsFrom:(NSInteger)numberOfRows inSection:(NSInteger)section inTableView:(UITableView *)tableView;

/* Gives the extender an opportunity to modify the order of the sections
 * from the one the data source gives, or to implement the division introduced
 * by transformedNumberOfSectionsFrom:...
 * row is _not_ transformed before this method is called. It can be -1 if there
 * are no row information known at the time of calling.
 * The transformation *must* be bijective. */
- (NSInteger)transformedSectionIndexFrom:(NSInteger)section withRow:(NSInteger)row inTableView:(UITableView *)tableView;

/* Gives the extender an opportunity to modify the order of the rows from the
 * one the data source gives.
 * section is _not_ transformed before this method is called.
 * The transformation *must* be bijective. */
- (NSInteger)transformedRowIndexFrom:(NSInteger)row inSection:(NSInteger)section inTableView:(UITableView *)tableView;

/* Gives the extender an opportunity to modify cells appearance. */
- (CGFloat)transformWidth:(CGFloat)originalWidth forRowAtIndex:(NSInteger)idx inSection:(NSInteger)section inTableView:(UITableView *)tableView;
- (CGFloat)transformHeight:(CGFloat)originalHeight forRowAtIndex:(NSInteger)idx inSection:(NSInteger)section inTableView:(UITableView *)tableView;
/* Allows to customize how the cell looks (for instance you can set a custom
 * background).
 * In the implementation of this method, you can (should) use the
 * isTransformedByExtender:/setTransformed:byExtender: methods of the cell.
 * These methods are created so you can avoid applying the transformation more
 * than once on the same cell (cells are reused). */
- (void)transformCell:(UITableViewCell *)cell forRowAtIndex:(NSInteger)idx inSection:(NSInteger)section inTableView:(UITableView *)tableView;

@end



@interface UITableViewCell (TransformableCell)

/* When transforming a cell (see above), you can (understand should) use these
 * methods to avoid transforming the cell more than once. */
- (BOOL)hpn_isTransformedByExtender:(id <HPNTableViewExtender>)extender;
- (void)hpn_setTransformed:(BOOL)isTransformed byExtender:(id <HPNTableViewExtender>)extender;

@end



@interface UITableView (ExtendedTableView)

- (NSInteger)hpn_transformedSectionIndex:(NSInteger)section;
- (NSIndexPath *)hpn_transformedIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)hpn_transformedIndexPaths:(NSArray *)indexPaths;

/* Returns the available width for the given cell from table view's bounds.
 * As some extenders can change the available width for a cell, don't
 * use tableview.bounds.size.width to get the available width for a
 * cell when using an extended table view.
 * The given index path must not be transformed. */
- (CGFloat)hpn_cellWidthForRowAtIndexPath:(NSIndexPath *)indexPath;



/* *** The methods below are mainly designed to be used by the extenders *** */

/* Asking the view for an extender which is not registered for the given table
 * view will throw an exception */
- (UIView *)hpn_viewInTableHeaderForExtender:(id <HPNTableViewExtender>)extender;
- (UIView *)hpn_viewInTableFooterForExtender:(id <HPNTableViewExtender>)extender;

@end



@interface UITableView (RecommendedConvenience)

/* This method sets the data source and the delegate of the table view. It is
 * recommended to use this method instead of
 *    tableView.delegate = ...; tableView.dataSource = ...;
 * for performance (for extended table views) and stability (probably only for
 * extended table views too) reasons.
 *
 * In some rare cases, setting the data source before the delegate might make
 * the table view crash (probably for extended table views only, but untested on
 * non-extended table views).
 *
 * See HPNProfileDisplayerALVCE.swift, prepareObjectForRemovalOfExtender(_:) for
 * more information. */
- (void)setDelegate:(id <UITableViewDelegate>)delegate andDataSource:(id <UITableViewDataSource>)dataSource;

@end



@interface HPNTableViewDelegateDataSourceForHelptender : HPNScrollViewDelegateForHelptender <UITableViewDataSource, UITableViewDelegate> {
@private
	Class previousNonNilOriginalDataSourceClass;
}

@property(nonatomic, assign) UITableView *linkedView;

@property(nonatomic, weak) id <UITableViewDelegate> originalTableViewDelegate;
@property(nonatomic, weak) id <UITableViewDataSource> originalTableViewDataSource;

@end



@interface HPNTableViewHelptender : UITableView <HPNHelptender>

- (HPNTableViewDelegateDataSourceForHelptender *)hpn_cheatDataSourceCreateIfNotExist;

- (void)hpn_overrideDataSource;
- (void)hpn_resetDataSource;

@end
