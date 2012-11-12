//
//  DetailViewManager.h
//  uni-project
//  Abstract: The split view controller's delegate.  It coordinates the display of detail view controllers.

//  Copyright (c) 2012 test. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 SubstitutableDetailViewController defines the protocol that detail view controllers must adopt.
 The protocol specifies aproperty for the bar button item controlling the navigation pane.
 */
@protocol SubstitutableDetailViewController
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;
@end

@interface DetailViewManager : NSObject <UISplitViewControllerDelegate>

/// Things for IB
// The split view this class will be managing.
//@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;

@property (strong, nonatomic) UISplitViewController *splitViewController;

// The presently displayed detail view controller.  This is modified by the various
// view controllers in the navigation pane of the split view controller.
//@property (nonatomic, assign) IBOutlet UIViewController<SubstitutableDetailViewController> *detailViewController;
@property (strong, nonatomic) UIViewController<SubstitutableDetailViewController> *detailViewController;

// Holds a reference to the popover that will be displayed
// when the navigation button is pressed.
@property (strong, nonatomic) UIPopoverController *navigationPopoverController;

-(id)initWithSplitViewController:(UISplitViewController*)splitViewController;

@end
