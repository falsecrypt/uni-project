//
//  DetailViewManager.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "DetailViewManager.h"
#import "FirstDetailViewController.h"
#import "EnergyClockViewController.h"

@interface DetailViewManager ()
// Holds a reference to the split view controller's bar button item
// if the button should be shown (the device is in portrait).
// Will be nil otherwise.
@property (nonatomic, retain) UIBarButtonItem *navigationPaneButtonItem;

@end


@implementation DetailViewManager


-(id)initWithSplitViewController:(UISplitViewController*)splitViewController
{
    self = [super init];
    if(self){
        _splitViewController = splitViewController;
        
        splitViewController.delegate = self;
        FirstDetailViewController *initialDetailViewController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
        self.detailViewController = initialDetailViewController;
        DLog(@"Calling DetailViewManager initWithSplitViewcontroller, setting detailViewController = %@", self.detailViewController);
    }
    
    return self;
}

// -------------------------------------------------------------------------------
//	setDetailViewController:
//  Custom implementation of the setter for the detailViewController property.
// -------------------------------------------------------------------------------
- (void)setDetailViewController:(UIViewController<SubstitutableDetailViewController> *)detailViewController
{
    DLog(@"<DetailViewManager> calling setDetailViewController, with detailViewController: %@", detailViewController);
    // Clear any bar button item from the detail view controller that is about to
    // no longer be displayed.
    //self.detailViewController.navigationPaneBarButtonItem = nil;
    
    _detailViewController = detailViewController;
    
    // Set the new detailViewController's navigationPaneBarButtonItem to the value of our
    // navigationPaneButtonItem.  If navigationPaneButtonItem is not nil, then the button
    // will be displayed.
    //_detailViewController.navigationPaneBarButtonItem = self.navigationPaneButtonItem;
    
    // Update the split view controller's view controllers array.
    // This causes the new detail view controller to be displayed.
    id navigationViewController = (self.splitViewController.viewControllers)[0];
    UIViewController *detail = (self.splitViewController.viewControllers)[1];
//    if ([detail isKindOfClass:[EnergyClockViewController class]]) {
//        NSArray *vcs = ((EnergyClockViewController *)detail).childViewControllers;
//        for (UIViewController *vc in vcs) {
//            for (UIView *view in vc.view.subviews ) {
//                [view removeFromSuperview];
//            }
//        }
//        for (UIViewController *vc in vcs) {
//            [vc willMoveToParentViewController:nil];
//            [vc removeFromParentViewController];
//        }
//        for (int i=0; i<[detail.view.subviews count]; i++) {
//            UIView *view = detail.view.subviews[i];
//            view =nil;
//        }
//        [detail removeFromParentViewController];
//        DLog(@"<DetailViewManager> ((EnergyClockViewController *)detail).viewControllers: %@", ((EnergyClockViewController *)detail).viewControllers);
//    }
    NSArray *viewControllers = @[navigationViewController, _detailViewController];
    self.splitViewController.viewControllers = viewControllers;
    //DLog(@"<DetailViewManager> self.splitViewController.viewControllers: %@", self.splitViewController.viewControllers);
    DLog(@"<DetailViewManager> detail prev: %@", detail);
    DLog(@"<DetailViewManager> detail prev: %@", detail.view);
    // Dismiss the navigation popover if one was present.  This will
    // only occur if the device is in portrait.
//    if (self.navigationPopoverController)
//        [self.navigationPopoverController dismissPopoverAnimated:YES];
}

#pragma mark -
#pragma mark UISplitViewDelegate

// -------------------------------------------------------------------------------
//	splitViewController:shouldHideViewController:inOrientation:
// -------------------------------------------------------------------------------
- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

// -------------------------------------------------------------------------------
//	splitViewController:willHideViewController:withBarButtonItem:forPopoverController:
// -------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    DLog(@"calling splitViewController:willHideViewController");
    // If the barButtonItem does not have a title (or image) adding it to a toolbar
    // will do nothing.
    barButtonItem.title = @"Navigation";
    
    self.navigationPaneButtonItem = barButtonItem;
    self.navigationPopoverController = pc;
    
    // Tell the detail view controller to show the navigation button.
    self.detailViewController.navigationPaneBarButtonItem = barButtonItem;
}

// -------------------------------------------------------------------------------
//	splitViewController:willShowViewController:invalidatingBarButtonItem:
// -------------------------------------------------------------------------------
- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationPaneButtonItem = nil;
    self.navigationPopoverController = nil;
    
    // Tell the detail view controller to remove the navigation button.
    self.detailViewController.navigationPaneBarButtonItem = nil;
}


- (void)splitViewController:(UISplitViewController *)svc
          popoverController:(UIPopoverController *)pc
  willPresentViewController:(UIViewController *)aViewController {
    DLog(@"calling splitViewController:popoverController:willPresentViewController");
}


@end

