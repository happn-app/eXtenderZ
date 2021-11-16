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

#import "HPNScrollViewExtender.h"



/* This extender allows customizing the cancellation of touches in a scrollview. */
@interface HPNCustomCancelableTouchesSVE : NSObject <HPNScrollViewExtender>

/* Once the extender is added to an extended scroll view, the different
 * properties (allowedClasses, etc.) are "frozen" for this scroll view. You can
 * still change the values of these properties though. The changes will take
 * effect on any other scroll view the extender is added to, but not the ones
 * on which it is already added. If you want to "refresh" a scroll view on which
 * you've already added the extender so the new properties are applied, use the
 * method below.
 * Calling the method with a scroll view on which the extender has not been
 * added will throw an exception.
 * Note: You can also remove the extender from the scroll view, and add it again
 *       directly. But the implementation of this metod does not do that. It is
 *       probably faster to use this method that removing/adding the extender. */
- (void)reRegisterScrollView:(UIScrollView *)scrollView;
/* Same as above, but applies to all scroll views to which the extender was
 * added. */
- (void)reRegisterAllScrollViews;


/* Touches       cancelled --> The drag          starts in the scroll view.
 * Touches *not* cancelled --> The drag does not start  in the scroll view.
 *
 * How the extender works:
 *    * The scroll view asks the extender whether to cancel or not touches for a
 *      given view;
 *    * The extender, depending on the view and a set of custom rules will
 *      respond whether the touches should be cancelled or not;
 *    * The rules are processed this way:
 *       * The extender have a default answer (cancelsTouchesByDefault);
 *       * A view is either special or not. That is determined via the
 *         specialViews, specialClasses and checkSuperviews properties:
 *          * If the view (or one of its superviews if checkSuperviews is YES),
 *            is pointer equal to any view in specialViews, the view is special;
 *          * else, if the view (or one of its superviews depending on
 *            checkSuperviews) is kind of any class in specialClasses, the view
 *            is special;
 *          * else the view is not special.
 *       * Algorithm to determine whether touches should be cancelled:
 *          * BOOLEAN shouldCancel
 *          *
 *          * -- Sets shouldCancel depending on whether the view is special.
 *          * IF view is special THEN shouldCancel = !cancelsTouchesByDefault
 *          * ELSE                    shouldCancel =  cancelsTouchesByDefault
 *          *
 *          *
 *          * -- If we should cancel touches, let's cancel touches!
 *          * IF shouldCancel THEN RETURN YES
 *          *
 *          * -- Else, if we are exclusive, we don't cancel touches
 *          * IF isExclusive THEN RETURN NO
 *          *
 *          * -- Else, we ask the scroll view its original thoughts on the subject
 *          * RETURN [scrollView touchesShouldCancelInContentView:view]
 */


/* Default is NO. */
@property(nonatomic, assign) BOOL cancelsTouchesByDefault;

/* Default is NO. Basic use is to allow only _adding_ new views on which the
 * touches should be cancelled, instead of re-defining everything. */
@property(nonatomic, assign, getter = isExclusive) BOOL exclusive;


/* Default is NO. If YES, a view will be considered special if either it or one
 * of its superviews matches the specialViews/specialClasses properties of the
 * extender. */
@property(nonatomic, assign) BOOL checkSuperviews;

/* Self-explanatory. If specialViews is nil at the time the extender is added to
 * an object, an exception is thrown (default is an empty array). */
@property(nonatomic, retain) NSArray *specialViews;

/* Self-explanatory. If specialClasses is nil at the time the extender is added
 * to an object, an exception is thrown (default is
 * @[UIButton.class, UITextField.class]). */
@property(nonatomic, retain) NSArray *specialClasses;

@end
