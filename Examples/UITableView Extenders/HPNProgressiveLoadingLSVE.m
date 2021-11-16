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

#import "HPNProgressiveLoadingLSVE.h"

#import "HPNInvertedRowTVE.h"



#define DEBUG_PROGRESSIVE_LOADING
#undef DEBUG_PROGRESSIVE_LOADING

@interface HPNProgressiveLoadingLSVE ()

@property(nonatomic, readonly) UIScrollView *linkedObject;
#ifdef DEBUG_PROGRESSIVE_LOADING
@property(nonatomic, retain) UIView *progressiveDebugView;
#endif
@end



@implementation HPNProgressiveLoadingLSVE

@dynamic linkedObject;

- (id)init
{
	if ((self = [super init]) != nil) {
		self.viewLoadingMore = [HPNLoadingMoreView loadingMoreView];
		self.topMargin = 0.;
		isEmptyAndLoadingRect = CGRectZero;
	}
	
	return self;
}

- (Class)linkedClass
{
	return UIScrollView.class;
}

- (BOOL)prepareObjectForExtender:(UIScrollView *)scrollView
{
	if (![super prepareObjectForExtender:scrollView]) return NO;
	
#ifdef DEBUG_PROGRESSIVE_LOADING
	self.progressiveDebugView = [UIView new];
	self.progressiveDebugView.backgroundColor = [UIColor colorWithRed:0./255. green:255./255. blue:255./255. alpha:.5];
	[scrollView addSubview:self.progressiveDebugView];
#endif
	
	insetting = NO;
	topInset = bottomInset = 0.;
	delegateRespondsToDidReachEnd = [scrollView.delegate respondsToSelector:@selector(progressiveLoadingScrollViewDidReachEnd:)];
	
	/* Let's add the loading more view to the table view */
	_viewLoadingMore.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin;
	CGRect f = _viewLoadingMore.frame;
	f.origin.x = 0.;
	if (!_inverted) f.origin.y = MAX(scrollView.contentSize.height, scrollView.bounds.size.height);
	else            f.origin.y = -f.size.height;
	f.size.width = scrollView.bounds.size.width;
	_viewLoadingMore.frame = f;
	
	UIEdgeInsets inset = scrollView.contentInset;
	if (!_inverted) inset.bottom += (bottomInset = f.size.height);
	scrollView.contentInset = inset;
	
	[scrollView addSubview:_viewLoadingMore];
	[self object:scrollView setHasMore:YES]; /* Cannot call scrollView.hasMore = YES yet! */
	
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(UIScrollView *)scrollView
{
	NSParameterAssert([scrollView isKindOfClass:UIScrollView.class]);
	UIEdgeInsets inset = scrollView.contentInset;
	inset.top -= topInset; topInset = 0.;
	inset.bottom -= bottomInset; bottomInset = 0.;
	scrollView.contentInset = inset;
	
	[_viewLoadingMore removeFromSuperview];
	[super prepareObjectForRemovalOfExtender:scrollView];
}

- (void)scrollViewDidChangeContentSize:(UIScrollView *)scrollView originalContentSize:(CGSize)size
{
#pragma unused(size)
	[self updateLoadingViewLocationWith:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (delegateRespondsToDidReachEnd) {
#if !defined RELEASE_TYPE_DEV
		/* We're in non-developer release */
		CGFloat margin = scrollView.frame.size.height/0.5;
#else
		CGFloat margin = -scrollView.contentInset.top;
#endif
		if ((!_inverted && scrollView.contentOffset.y + margin > MAX(scrollView.contentSize.height - scrollView.frame.size.height, margin)) ||
			 ( _inverted && scrollView.contentOffset.y - margin < 0.)) {
			[(id <HPNProgressiveLoadingScrollViewDelegate>)scrollView.delegate progressiveLoadingScrollViewDidReachEnd:scrollView];
		}
	}
}

- (BOOL)objectIsLoadingFirstPage:(UIScrollView *)scrollView
{
#pragma unused(scrollView)
	NSParameterAssert(scrollView == self.linkedObject);
	return isEmptyAndLoading;
}

- (BOOL)objectHasMore:(UIScrollView *)scrollView
{
#pragma unused(scrollView)
	NSParameterAssert(scrollView == self.linkedObject);
	return hasMore;
}

- (CGRect)objectIsEmptyAndLoadingRect:(UIScrollView *)scrollView
{
#pragma unused(scrollView)
	NSParameterAssert(scrollView == self.linkedObject);
	return isEmptyAndLoadingRect;
}

- (void)object:(UIScrollView *)scrollView setHasMore:(BOOL)flag
{
	if ((flag && hasMore) || (!flag && !hasMore)) return;
	
	hasMore = flag;
	if (hasMore) {
		[self.viewLoadingMore setModeLoading];
		if (_inverted) {
			/* Let's show the "Loading..." message. Needs inset if inverted. */
			if (!insetting) {
				UIEdgeInsets inset = scrollView.contentInset;
				inset.top += (topInset = _viewLoadingMore.frame.size.height);
				scrollView.contentInset = inset;
				insetting = YES;
			}
			_viewLoadingMore.hidden = NO;
		}
	} else {
		[self.viewLoadingMore setModeNoMoreStories];
		if (_inverted) {
			/* Let's remove the inset added by the "Loading…" message: We hide the
			 * "You’ve reached the end" message if inverted. */
			if (insetting) {
				UIEdgeInsets inset = scrollView.contentInset;
				inset.top -= topInset; topInset = 0.;
				scrollView.contentInset = inset;
				insetting = NO;
			}
			_viewLoadingMore.hidden = YES;
		}
	}
}

- (void)object:(UIScrollView *)scrollView setIsEmptyAndLoading:(BOOL)flag
{
	if ((flag && isEmptyAndLoading) || (!flag && !isEmptyAndLoading)) return;
	
	isEmptyAndLoading = flag;
	[self updateLoadingViewLocationWith:scrollView];
}

- (void)object:(UIScrollView *)scrollView setIsEmptyAndLoadingRect:(CGRect)rect
{
	if (CGRectEqualToRect(rect, isEmptyAndLoadingRect)) return;
#ifdef DEBUG_PROGRESSIVE_LOADING
	self.progressiveDebugView.frame = rect;
#endif
	isEmptyAndLoadingRect = rect;
	[self updateLoadingViewLocationWith:scrollView];
}

- (UIEdgeInsets)objectProgressiveInset:(UIScrollView *)scrollView
{
#pragma unused(scrollView)
	NSParameterAssert(scrollView == self.linkedObject);
	return UIEdgeInsetsMake(topInset, 0., bottomInset, 0.);
}

#pragma mark - Overridden Accessors

- (void)setInverted:(BOOL)flag
{
	if (self.linkedObject != nil) [NSException raise:@"Read-Only Property" format:@"The property \"inverted\" is read-only after this TVE is assigned."];
	_inverted = flag;
}

- (void)setViewLoadingMore:(UIView <HPNLoadingMoreView> *)v
{
	if (self.linkedObject != nil) [NSException raise:@"Read-Only Property" format:@"The property \"viewLoadingMore\" is read-only after this TVE is assigned."];
	_viewLoadingMore = v;
}

#pragma mark - Private

- (void)updateLoadingViewLocationWith:(UIScrollView *)scrollView
{
	/* Let's place the "Loading More" view */
	CGRect f = _viewLoadingMore.frame;
	if (isEmptyAndLoading) {
		f.origin.y = CGRectEqualToRect(isEmptyAndLoadingRect, CGRectZero)? 0.: CGRectGetMidY(isEmptyAndLoadingRect) - CGRectGetHeight(_viewLoadingMore.frame) / 2.;
	} else {
		if (!_inverted) f.origin.y = MAX(scrollView.contentSize.height, scrollView.bounds.size.height) + _topMargin;
		else            f.origin.y = -f.size.height;
	}
	f.size.width = scrollView.bounds.size.width;
	_viewLoadingMore.frame = f;
}

@end
