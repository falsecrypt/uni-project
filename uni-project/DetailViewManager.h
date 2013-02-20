//
//  DetailViewManager.h
//  uni-project
//  Abstract: The split view controller's delegate.  It coordinates the display of detail view controllers.

//  Copyright (c) 2012 test. All rights reserved.
//

#import <Foundation/Foundation.h>

/**  SubstitutableDetailViewController defines the protocol that detail view controllers must adopt.
  *  The protocol specifies a property for the bar button item controlling the navigation pane.
 */
@protocol SubstitutableDetailViewController
@optional
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;
@end

/** Custom controller object to manage the master and detail view controllers and mediate between them.
 DetailViewManager is a split view controller’s delegate.
 */
@interface DetailViewManager : NSObject <UISplitViewControllerDelegate>


/** Reference to UISplitViewController container-object, assigned in EcoMeterAppDelegate
  * DetailViewManager manages its viewControllers-array-property
 */
@property (strong, nonatomic) UISplitViewController *splitViewController;


/** This UIViewController is displayed on the right side of the interface.
  * It can be accessed through viewControllers-property of UISplitViewController: viewControllers[1].
  * Each UIViewController can set itselt as current detailViewController.
 */
@property (strong, nonatomic) UIViewController<SubstitutableDetailViewController> *detailViewController;


/** Holds a reference to the popover that will be displayed when the navigation button is pressed.
 */
@property (strong, nonatomic) UIPopoverController *navigationPopoverController;


/** Designated initializer for the DetailViewManager Class
 
 @param splitViewController Reference to a UISplitViewController Object
 @return id DetailViewManager instance
 */
-(id)initWithSplitViewController:(UISplitViewController*)splitViewController;

@end
