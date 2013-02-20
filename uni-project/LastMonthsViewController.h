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

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;
@property (nonatomic, assign) BOOL instanceWasCached; // for DataOverviewTableViewController

@end
