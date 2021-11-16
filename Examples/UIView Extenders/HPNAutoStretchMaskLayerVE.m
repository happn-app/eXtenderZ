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

#import "HPNAutoStretchMaskLayerVE.h"



@implementation HPNAutoStretchMaskLayerVE

+ (void)applyMaskEdges:(UIEdgeInsets)edges toView:(UIView *)view
{
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	CGRect bounds = view.bounds;
	view.layer.mask.frame = CGRectMake(bounds.origin.x + edges.left, bounds.origin.y + edges.top,
												  bounds.size.width  - (edges.left + edges.right),
												  bounds.size.height - (edges.top  + edges.bottom));
	[CATransaction commit];
}

- (BOOL)prepareObjectForExtender:(NSObject *)object
{
#pragma unused(object)
	NSParameterAssert([object isKindOfClass:UIView.class]);
	return YES;
}

- (void)prepareObjectForRemovalOfExtender:(NSObject *)object
{
#pragma unused(object)
	NSParameterAssert([object isKindOfClass:UIView.class]);
}

- (void)view:(UIView *)view layoutSublayersOfLayer:(CALayer *)layer
{
	if (layer == view.layer) {
		[self.class applyMaskEdges:self.maskEdges toView:view];
	}
}

@end
