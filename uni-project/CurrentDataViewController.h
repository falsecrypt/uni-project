//
//  CurrentDataViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProfilePopoverViewController.h"
#import "DetailViewManager.h"

@interface CurrentDataViewController : UIViewController <SubstitutableDetailViewController,CPTPlotSpaceDelegate,CPTPlotDataSource,CPTScatterPlotDelegate>

// Top Area, Speedometer
@property (strong, nonatomic) UIImageView *needleImageView;
@property (nonatomic,assign) int speedometerCurrentValue;
@property (nonatomic,assign) float prevAngleFactor;
@property (nonatomic,assign) float angle;
@property (assign, nonatomic) int maxVal;
@property (strong, nonatomic) IBOutlet UIImageView *speedometerImageView;
@property (assign, nonatomic) int userMaximumWatt;
@property (assign, nonatomic) int userCurrentWatt;
@property (strong, nonatomic) IBOutlet UILabel *spReadingFirstNumber;
@property (strong, nonatomic) IBOutlet UILabel *spReadingSecondNumber;
@property (strong, nonatomic) IBOutlet UILabel *spReadingThirdNumber;
@property (strong, nonatomic) IBOutlet UILabel *spReadingFourthNumber;
// for (UILabel *spLabel in labelsWithNumbersCollection) { ...
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labelsWithNumbersCollection;

// Bottom Area, Scatter Plot on the left side
@property (strong, nonatomic) IBOutlet CPTGraphHostingView *hostingView;
@property (strong, nonatomic) CPTGraphHostingView *scatterPlotView;
@property (strong, nonatomic) CPTXYGraph *scatterPlot;
@property (strong, nonatomic) NSMutableArray *dataForPlot;

// Bottom Area, Current Day - total power consumption and Total Cost on the right side
@property (strong, nonatomic) IBOutlet UIView *dataDisplayView;
@property (strong, nonatomic) IBOutlet UILabel *kwhDataLabel;
@property (strong, nonatomic) IBOutlet UILabel *eurDataLabel;



@property (nonatomic, retain) ProfilePopoverViewController *userProfile;
@property (nonatomic, retain) UIPopoverController *profilePopover;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;


-(void) addMeterViewContents;
-(void) rotateIt:(float)angl;
-(void) rotateNeedle;
-(void) setSpeedometerCurrentValue;

@end
