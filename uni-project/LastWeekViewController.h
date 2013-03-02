//
//  LastWeekViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import "ProfilePopoverViewController.h"

@interface LastWeekViewController : UIViewController<CPTPlotSpaceDelegate,
                                                     CPTPlotDataSource,
                                                     CPTPieChartDelegate,
                                                     SubstitutableDetailViewController>
{
    
    NSMutableArray *plotDataConsumption;
    NSMutableArray *plotDataDates;
    
}

@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;
@property (nonatomic, strong) UIPopoverController *profilePopover;
@property (nonatomic, strong) ProfilePopoverViewController *userProfile;

@property (strong, nonatomic) CPTGraphHostingView *pieChartView;
@property (strong, nonatomic) CPTGraph *graph;


@property (nonatomic, assign) BOOL instanceWasCached; // for DataOverviewTableViewController

@property (strong, nonatomic) NSMutableDictionary *daysColors;

@end
