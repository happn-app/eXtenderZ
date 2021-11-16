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

@import Foundation;

#import "HPNLinkedOE.h"
#import "HPNObjectExtender.h"
#import "HPNScrollViewExtender.h"

#import "HPNLoadingMoreView.h"



@protocol HPNProgressiveLoadingScrollViewDelegate <UIScrollViewDelegate>
@optional

/* Called when the user reached the end of the scroll view, notifying more data should be loaded */
- (void)progressiveLoadingScrollViewDidReachEnd:(UIScrollView *)progressiveLoadingScrollView;

@end



/* This TVE can only be used by one extended table view */
@interface HPNProgressiveLoadingLSVE : HPNLinkedOE <HPNObjectExtender, HPNScrollViewExtender> {
@private
	BOOL hasMore;
	BOOL isEmptyAndLoading;
	BOOL insetting;
	BOOL delegateRespondsToDidReachEnd;
	
	CGFloat topInset, bottomInset;
	CGRect isEmptyAndLoadingRect;
}

/* Once the progressive loading TVE is assigned to an extended table view,
 * this property "becomes" read-only (trying to set it throws an exception). */
@property(nonatomic, assign) BOOL inverted;

/* Margin for y position of the activity loader */
@property(nonatomic, assign) CGFloat topMargin;

/* Once the progressive loading TVE is assigned to an extended table view,
 * this property "becomes" read-only (trying to set it throws an exception). */
@property(nonatomic, retain) UIView <HPNLoadingMoreView> *viewLoadingMore;

@end



@interface UIScrollView (ExtensionsByProgressiveLoadingLSVE)

/* Declarative. Has no actual effect. */
@property(nonatomic, weak) IBOutlet id <HPNProgressiveLoadingScrollViewDelegate> delegate;

/* Set to YES when there is more data that can be loaded */
@property(nonatomic, assign) BOOL hasMore;

/* Set to YES when it is empty and loading (aka first loading of the first page) */
@property(nonatomic, assign) BOOL isEmptyAndLoading;

/* The rect where the view loading more must be vertically centered into when it is empty and loading */
@property(nonatomic, assign) CGRect isEmptyAndLoadingRect;

/* Returns the inset applied to the scroll view by the progressive loading extender */
@property(nonatomic, readonly) UIEdgeInsets progressiveInset;

@end
