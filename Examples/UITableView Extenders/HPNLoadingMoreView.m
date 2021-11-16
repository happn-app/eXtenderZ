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

#import "HPNLoadingMoreView.h"



#define SPACE_BETWEEN_ACTIVITY_AND_TEXT (8.) /* Pixels */

@implementation HPNLoadingMoreView

+ (HPNLoadingMoreView *)loadingMoreView
{
	return [[self alloc] initWithFrame:CGRectMake(0., 0., 0. /* Set later */, 46. /* Default image height */ + 10. /* Spacing */)];
}

- (void)privateInit
{
	NSAssert(activityIndicatorView == nil, @"***** WTF?");
	endingTopMargin = 5.;
	leftMargin = rightMaring = 0.;
	
	imageViewEndOfList = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_end_of_lists_light.png"]];
	activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	
	imageViewEndOfList.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
	activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
	
	[self addSubview:imageViewEndOfList];
	[self addSubview:activityIndicatorView];
	
	modeIsLoading = NO;
	[self setModeLoading];
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]) != nil) {
		[self privateInit];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]) != nil) {
		[self privateInit];
	}
	
	return self;
}

- (void)setEndingImage:(UIImage *)image
{
	if ([image isEqual:imageViewEndOfList.image]) return;
	
	imageViewEndOfList.image = image;
	[imageViewEndOfList sizeToFit];
	
	[self setNeedsLayout];
}

- (void)setEndingTopMargin:(CGFloat)margin
{
	if (ABS(endingTopMargin - margin) < .25) return;
	
	endingTopMargin = margin;
	
	[self setNeedsLayout];
}

- (void)setLeftMargin:(CGFloat)margin
{
	if (ABS(leftMargin - margin) < .25) return;
	
	leftMargin = margin;
	
	[self setNeedsLayout];
}

- (void)setRightMargin:(CGFloat)margin
{
	if (ABS(rightMaring - margin) < .25) return;
	
	rightMaring = margin;
	
	[self setNeedsLayout];
}

- (void)setActivityIndicatorIsWhite:(BOOL)isWhite
{
	activityIndicatorView.activityIndicatorViewStyle = (isWhite? UIActivityIndicatorViewStyleWhite: UIActivityIndicatorViewStyleGray);
}

- (void)setModeLoading
{
	if (modeIsLoading) return;
	modeIsLoading = YES;
	
	imageViewEndOfList.hidden = YES;
	
	[activityIndicatorView startAnimating];
	activityIndicatorView.hidden = NO;
	
	CGRect f;
	f = activityIndicatorView.frame;
	f.origin.x = ((self.bounds.size.width - leftMargin - rightMaring) - f.size.width) / 2. + leftMargin;
	f.origin.y = endingTopMargin;
	activityIndicatorView.frame = f;
}

- (void)setModeNoMoreStories
{
	if (!modeIsLoading) return;
	modeIsLoading = NO;
	
	[activityIndicatorView stopAnimating];
	activityIndicatorView.hidden = YES;
	
	CGRect f = imageViewEndOfList.frame;
	f.origin.x = ((self.bounds.size.width - leftMargin - rightMaring) - f.size.width) / 2. + leftMargin;
	f.origin.y = endingTopMargin;
	imageViewEndOfList.frame = f;
	imageViewEndOfList.hidden = NO;
}

- (void)layoutSubviews
{
	if (modeIsLoading) {modeIsLoading = NO;  [self setModeLoading];}
	else               {modeIsLoading = YES; [self setModeNoMoreStories];}
}

@end
