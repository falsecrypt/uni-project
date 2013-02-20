//
//  CurrentDataViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfilePopoverViewController.h"
#import "DetailViewManager.h"

@interface CurrentDataViewController : UIViewController<SubstitutableDetailViewController,CPTPlotSpaceDelegate,CPTPlotDataSource,CPTScatterPlotDelegate>


@property (nonatomic, assign) BOOL instanceWasCached; // for MyOfficeTableViewController
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;


@end
