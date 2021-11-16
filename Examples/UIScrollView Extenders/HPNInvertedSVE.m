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

#import "HPNInvertedSVE.h"



/* Note: Logs are commented for performance reasons. (Not sure it's 100% needed,
 *       but feels safer.) */
@implementation HPNInvertedSVE

- (BOOL)prepareObjectForExtender:(UIScrollView *)scrollView
{
	if (![scrollView isKindOfClass:UIScrollView.class]) return NO;
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(UIScrollView *)scrollView
{
#pragma unused(scrollView)
	NSParameterAssert([scrollView isKindOfClass:UIScrollView.class]);
}

- (void)adaptScrollViewOffsetFromContentSizeChange:(UIScrollView *)scrollView originalContentSize:(CGSize)originalSize newContentSize:(CGSize)newSize
{
	CGPoint contentOffset = scrollView.contentOffset;
	
	CGFloat originalY = contentOffset.y;
	
	contentOffset.y = originalSize.height - (contentOffset.y + scrollView.bounds.size.height); /* <-- Changing y content offset from standard coordinates to reversed ones with original content size */
	contentOffset.y = MAX(-scrollView.contentInset.bottom, contentOffset.y);
	
	contentOffset.y = newSize.height      - (contentOffset.y + scrollView.bounds.size.height); /* <-- Changing y content offset from reversed coordinates to standard ones with new content size */
	contentOffset.y = MAX(-scrollView.contentInset.top, contentOffset.y);
	
	if (ABS(contentOffset.y - originalY) > 1.) {
//		HPNLogT(@"Setting content offset to %@ (was %@)", NSStringFromCGPoint(contentOffset), NSStringFromCGPoint(scrollView.contentOffset));
		scrollView.contentOffset = contentOffset;
	}
}

- (void)scrollViewWillChangeContentSize:(UIScrollView *)scrollView newContentSize:(CGSize)newSize
{
	CGSize originalSize = scrollView.contentSize;
//	HPNLogT(@"Will change content size from %@ to %@", NSStringFromCGSize(originalSize), NSStringFromCGSize(newSize));
	
	if (newSize.height <= originalSize.height)
		[self adaptScrollViewOffsetFromContentSizeChange:scrollView originalContentSize:originalSize newContentSize:newSize];
}

- (void)scrollViewDidChangeContentSize:(UIScrollView *)scrollView originalContentSize:(CGSize)originalSize
{
	CGSize newSize = scrollView.contentSize;
//	HPNLogT(@"Did change content size from %@ to %@", NSStringFromCGSize(originalSize), NSStringFromCGSize(newSize));
	
	if (newSize.height >= originalSize.height)
		[self adaptScrollViewOffsetFromContentSizeChange:scrollView originalContentSize:originalSize newContentSize:newSize];
}

- (void)adaptScrollViewOffsetFromContentInsetChange:(UIScrollView *)scrollView delta:(CGFloat)d
{
	CGPoint contentOffset = scrollView.contentOffset;
	
	CGFloat originalY = contentOffset.y;
	
	contentOffset.y = scrollView.contentSize.height - (contentOffset.y + scrollView.bounds.size.height); /* <-- Changing y content offset from standard coordinates to reversed ones */
	contentOffset.y = MAX(-scrollView.contentInset.bottom, contentOffset.y);
	
	contentOffset.y += d;
	
	contentOffset.y = scrollView.contentSize.height - (contentOffset.y + scrollView.bounds.size.height); /* <-- Changing y content offset from reversed coordinates to standard ones */
	contentOffset.y = MAX(-scrollView.contentInset.top, contentOffset.y);
	
	if (ABS(contentOffset.y - originalY) > 1.) {
//		HPNLogT(@"Setting content offset to %@ (was %@)", NSStringFromCGPoint(contentOffset), NSStringFromCGPoint(scrollView.contentOffset));
		scrollView.contentOffset = contentOffset;
	}
}

- (void)scrollViewWillChangeContentInset:(UIScrollView *)scrollView newContentInset:(UIEdgeInsets)newInset
{
	UIEdgeInsets originalInset = scrollView.contentInset;
//	HPNLogT(@"Will change content inset from %@ to %@", NSStringFromUIEdgeInsets(originalInset), NSStringFromUIEdgeInsets(newInset));
	
	CGFloat d = (originalInset.top - newInset.top) + (originalInset.bottom - newInset.bottom);
	if (d < 0) [self adaptScrollViewOffsetFromContentInsetChange:scrollView delta:d]; /* This test for d is less than 0 is very very hacky... */
}

@end
