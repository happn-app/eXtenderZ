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



@protocol HPNScrollViewExtender <HPNExtender>
@optional

/*********************************/
/* *** Extentions on actions *** */

/* Called when the scroll view was scrolled. Called _before_ the actual delegate
 * is called. */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

/* Called when the scroll view drag scroll ends */
- (void)scrollViewDidEndDragScrolling:(UIScrollView *)scrollView willDecelerate:(BOOL)willDecelerate;

/* Gives the extender an opportunity to override the scroll destination when the
 * user ends a scroll */
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;

/* Called when the content size of the scroll view changes */
- (void)scrollViewWillChangeContentSize:(UIScrollView *)scrollView newContentSize:(CGSize)newSize;
- (void)scrollViewDidChangeContentSize:(UIScrollView *)scrollView originalContentSize:(CGSize)originalSize;

/* Called when the content size of the scroll view changes */
- (void)scrollViewWillChangeContentInset:(UIScrollView *)scrollView newContentInset:(UIEdgeInsets)originalInset;
- (void)scrollViewDidChangeContentInset:(UIScrollView *)scrollView originalContentInset:(UIEdgeInsets)originalInset;

/* Called when the scroll view ends scrolling */
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;

@end



@interface HPNScrollViewDelegateForHelptender : NSObject <UIScrollViewDelegate> {
@private
	BOOL odRespondsToDidScroll;
	
	Class previousNonNilOriginalDelegateClass;
}

+ (instancetype)scrollViewDelegateForHelptenderFromScrollViewDelegateForHelptender:(HPNScrollViewDelegateForHelptender *)original;

- (void)refreshKnownOriginalResponds;

@property(nonatomic, assign) UIScrollView *linkedView;

@property(nonatomic, weak) id <UIScrollViewDelegate> originalScrollViewDelegate;

@end



@interface HPNScrollViewHelptender : UIScrollView <HPNHelptender>

/* Can be overridden by sub-helptenders to return custom cheat delegate. The
 * following restrictions apply:
 *    * The cheat delegate must always be kind of class
 *      HPNScrollViewDelegateForHelptender
 *    * The cheat delegate/data source MUST be stored using the following line:
 *      objc_setAssociatedObject(<#self or helptender#>, SCROLL_VIEW_EXTENDER_CHEAT_REFERENCE, <#cheat#>, OBJC_ASSOCIATION_RETAIN_NONATOMIC) */
extern void * const SCROLL_VIEW_EXTENDER_CHEAT_REFERENCE;
- (HPNScrollViewDelegateForHelptender *)hpn_cheatDelegateCreateIfNotExist;

/* If you provide your own cheat delegate in a sub-helptender, you should
 * probably also override these... */
- (void)hpn_overrideDelegate;
- (void)hpn_resetDelegate;

@end
