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

#import "HPNAntiScrollSVE.h"

@import ObjectiveC.runtime;

#import "happn-Swift.h"



@implementation HPNAntiScrollSVE

- (id)init
{
	if ((self = [super init]) != nil) {
		self.constantContentInset = UIEdgeInsetsZero;
		self.antiScrolledViewInheritsInset = YES;
	}
	
	return self;
}

- (BOOL)prepareObjectForExtender:(UIScrollView *)scrollView
{
	if (![scrollView isKindOfClass:UIScrollView.class]) return NO;
	
	UIView *v = [[HPNPassthroughView alloc] initWithFrame:scrollView.bounds];
	v.autoresizingMask = UIViewAutoresizingNone;
	v.backgroundColor = UIColor.clearColor;
	v.userInteractionEnabled = YES;
	[scrollView addSubview:v];
	objc_setAssociatedObject(scrollView, (__bridge const void *)self, v, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[self objectUpdateAntiScrollFrame:scrollView];
	
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(UIScrollView *)object
{
	NSParameterAssert([object isKindOfClass:UIScrollView.class]);
	
	[[self objectAntiScrolledView:object] removeFromSuperview];
	objc_setAssociatedObject(object, (__bridge const void *)self, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)objectAntiScrolledView:(UIScrollView *)v
{
	NSParameterAssert([v isKindOfClass:UIScrollView.class]);
	return objc_getAssociatedObject(v, (__bridge const void *)self);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self objectUpdateAntiScrollFrame:scrollView];
}

- (void)viewDidChangeFrame:(UIView *)view originalFrame:(CGRect)originalFrame
{
#pragma unused(originalFrame)
	NSParameterAssert([view isKindOfClass:UIScrollView.class]);
	[self objectUpdateAntiScrollFrame:(UIScrollView *)view];
}

- (void)scrollViewDidChangeContentSize:(UIScrollView *)scrollView originalContentSize:(CGSize)originalSize
{
#pragma unused(originalSize)
	[self objectUpdateAntiScrollFrame:scrollView];
}

- (void)scrollViewDidChangeContentInset:(UIScrollView *)scrollView originalContentInset:(UIEdgeInsets)originalInset
{
#pragma unused(originalInset)
	[self objectUpdateAntiScrollFrame:scrollView];
}

#pragma mark - Private

- (void)objectUpdateAntiScrollFrame:(UIScrollView *)scrollView
{
	UIView *antiScrollView = [self objectAntiScrolledView:scrollView];
	
	CGRect f = antiScrollView.frame;
	f.origin.x = scrollView.bounds.origin.x + self.constantContentInset.left + (self.antiScrolledViewInheritsInset? scrollView.actualContentInset.left: 0.);
	f.origin.y = scrollView.bounds.origin.y + self.constantContentInset.top  + (self.antiScrolledViewInheritsInset? scrollView.actualContentInset.top: 0.);
	f.size.width  = scrollView.bounds.size.width  - (self.constantContentInset.left + self.constantContentInset.right)  - (self.antiScrolledViewInheritsInset? scrollView.actualContentInset.left + scrollView.actualContentInset.right: 0.);
	f.size.height = scrollView.bounds.size.height - (self.constantContentInset.top  + self.constantContentInset.bottom) - (self.antiScrolledViewInheritsInset? scrollView.actualContentInset.top  + scrollView.actualContentInset.bottom: 0.);
	antiScrollView.frame = f;
}

@end
