//
//  LastMonthsViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CircleView.h"
#import "DetailViewManager.h"
#import "ProfilePopoverViewController.h"

@interface LastMonthsViewController : UIViewController <SubstitutableDetailViewController, circleViewDelegate>

@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;
@property (nonatomic, retain) UIPopoverController *profilePopover;
@property (nonatomic, assign) BOOL instanceWasCached; // for DataOverviewTableViewController
@property (strong, nonatomic) IBOutlet UILabel *consumptionMonthLabel;
@property (strong, nonatomic) IBOutlet UILabel *monthNameLabel;

@property (strong, nonatomic) IBOutlet CircleView *dataView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, retain) ProfilePopoverViewController *userProfile;

@end
