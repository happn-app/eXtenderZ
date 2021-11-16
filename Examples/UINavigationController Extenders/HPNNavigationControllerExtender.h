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



@protocol HPNNavigationControllerExtender <HPNExtender>
@optional

/* Exactly the same as the standard delegate method. Called before the actual
 * delegate method is called. */
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)navigationController:(UINavigationController *)navigationController didPopViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(UINavigationController *)navigationController didPushViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end



@interface HPNNavigationControllerDelegateForHelptender : NSObject <UINavigationControllerDelegate> {
@private
	Class previousNonNilOriginalDelegateClass;
}

@property(nonatomic, assign) UINavigationController *linkedNavigationController;

@property(nonatomic, weak) id <UINavigationControllerDelegate> originalNavigationControllerDelegate;

@end



@interface HPNNavigationControllerHelptender : UINavigationController <HPNHelptender>

@end
