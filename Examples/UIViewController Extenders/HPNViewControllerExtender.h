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



NS_ASSUME_NONNULL_BEGIN

@protocol HPNViewControllerExtender <HPNExtender>
@optional

/* Called in controller's viewDidLoad method.
 * May never be called if the extender is added after the view is loaded!
 * You can use the isViewLoaded property of the extended table view controller
 * to know if it has loaded its view. */
- (void)viewControllerViewDidLoad:(UIViewController *)viewController;

/* Called in controller's viewWillAppear: method */
- (void)viewController:(UIViewController *)viewController viewWillAppear:(BOOL)animated;

/* Called in controller's viewDidLayoutSubviews method */
- (void)viewControllerViewDidLayoutSubviews:(UIViewController *)viewController;

/* Called in controller's viewDidAppear: method */
- (void)viewController:(UIViewController *)viewController viewDidAppear:(BOOL)animated;

/* Called in controller's viewWillDisappear: method */
- (void)viewController:(UIViewController *)viewController viewWillDisappear:(BOOL)animated;

/* Called in controller's viewDidDisappear: method */
- (void)viewController:(UIViewController *)viewController viewDidDisappear:(BOOL)animated;

/* Called in controller's didMoveToParentViewController: method */
- (void)viewController:(UIViewController *)viewController didMoveToParentViewController:(nullable UIViewController *)parent;

/* Called in controller's prepareForSegue:sender: method */
- (void)viewController:(UIViewController *)viewController prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender;

/* Called in controller's preferredStatusBarStyle method */
- (UIStatusBarStyle)viewControllerPreferredStatusBarStyle:(UIViewController *)viewController;

/* Called in controller's willMoveToParentViewController: method */
- (void)viewController:(UIViewController *)viewController willMoveToParentViewController:(UIViewController *)parent;

@end



@interface HPNViewControllerHelptender : UIViewController <HPNHelptender>

@end

NS_ASSUME_NONNULL_END
