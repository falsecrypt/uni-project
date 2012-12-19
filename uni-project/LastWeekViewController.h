//
//  LastWeekViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@interface LastWeekViewController : UIViewController<CPTPlotSpaceDelegate, CPTPlotDataSource, CPTPieChartDelegate, SubstitutableDetailViewController> {
    
    NSArray *plotData;
    
}

@property (strong, nonatomic) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;

@property (strong, nonatomic) CPTGraphHostingView *pieChartView;
@property (strong, nonatomic) CPTGraph *graph;

@end
