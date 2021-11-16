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



@protocol HPNViewExtender <HPNExtender>
@optional

/* Called _exactly_ after the setFrame:, setCenter:, or layoutSubviews method is
 * called, _before_ it returns.
 * Thus, if the call was in an animation block, you will be called in this
 * animation block.
 * Warning: There's no guarantee the frame will change when the _view_ changes
 * its position in the windows. Eg. (but not the only possibility) the view is
 * in a superview that moves. The position of the view will change, but not its
 * frame. */
- (void)viewDidChangeFrame:(UIView *)view originalFrame:(CGRect)originalFrame;

/* Called after the view normally layouts the sublayers in
 * layoutSublayersOfLayer: */
- (void)view:(UIView *)view layoutSublayersOfLayer:(CALayer *)layer;

@end



@interface HPNViewHelptender : UIView <HPNHelptender>

@end
