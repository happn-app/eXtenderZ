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

#import "HPNViewExtender.h"



@interface HPNAutoStretchMaskLayerVE : NSObject <HPNViewExtender>

+ (void)applyMaskEdges:(UIEdgeInsets)edges toView:(UIView *)layer;

/* Changing this does NOT update the frame of the mask immediatly.
 * You can call the class method above to force a refresh. */
@property(nonatomic, assign) UIEdgeInsets maskEdges;

@end