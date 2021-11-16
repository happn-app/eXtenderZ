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

#import "HPNObjectExtender.h"
#import "HPNScrollViewExtender.h"



@interface HPNAntiScrollSVE : NSObject <HPNObjectExtender, HPNScrollViewExtender>

/* Default is UIEdgeInsetsZero. Call updateAntiScrollFrame on the scroll views
 * on which the extender was added after changing it, or
 * objectUpdateAntiScrollFrame: of the extender (see discussion on
 * updateAntiScrollFrame in UIScrollView extension for difference between the
 * two). */
@property(nonatomic, assign) UIEdgeInsets constantContentInset;
- (void)objectUpdateAntiScrollFrame:(UIScrollView *)scrollView;

/* See the antiScrolledView of the UIScrollView category extension. */
- (UIView *)objectAntiScrolledView:(UIScrollView *)scrollView;

/* Default is YES. */
@property(nonatomic, assign) BOOL antiScrolledViewInheritsInset;

@end



@interface UIScrollView (ExtensionsByAntiScrollSVE)

/* The anti-scrolled view is a view which always have the same frame as the
 * scroll view. But it does not move when the scroll view scrolls.
 * IMPORTANT NOTE: If there are more than one HPNAntiScrollSVE, calling this
 * method will return the _first_ antiScrolledView of the scrollView!
 * Call objectAntiScrolledView: on the wanted extender to get the view you want.
 */
@property(nonatomic, readonly) UIView *antiScrolledView;

/* Call this right after changing the constantContentInset of the extender.
 * No need to call it anywhere else.
 * IMPORTANT NOTE: If there are more than one HPNAntiScrollSVE, calling this
 * method will only refresh the frame of the first anti-scroll SVE. To
 * specifically update the frame of one anti-scroll SVE, call
 * objectUpdateAntiScrollFrame: on the SVE. */
- (void)updateAntiScrollFrame;

@end
