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
@import Foundation;

@import eXtenderZ;

#import "ThreeValuedLogic.h"



@protocol HPNResponderExtender <HPNExtender>
@optional

/* The first extender responding to this selector will be used to force the
 * input view of the given responder. */
- (TVL)responderCanBecomeFirstResponder:(UIResponder *)responder;

/* The first extender responding to this selector will be used to force the
 * input view of the given responder. */
- (UIView *)inputViewForResponder:(UIResponder *)responder;
/* The first extender responding to this selector will be used to force the
 * accessory input view of the given responder. */
- (UIView *)inputAccessoryViewForResponder:(UIResponder *)responder;

/* The first extender responding to this selector will be used to force the
 * text input context identifier of the given responder. */
- (NSString *)textInputContextIdentifierForResponder:(UIResponder *)responder;

@end



@interface HPNResponderHelptender : UIResponder <HPNHelptender>

@end
