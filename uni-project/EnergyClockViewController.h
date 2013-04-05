//
//  EnergyClockViewController.h
//  uni-project
//
//  Created by Pavel Ermolin on 28.02.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BTSPieView.h"
#import "SliceDetailsView.h"

@interface EnergyClockViewController : UIViewController <slicePieChartDatasource>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *radiusValuesForSlice;
@property (nonatomic, strong, readwrite) NSMutableArray *viewControllers;
@property (nonatomic, assign) BOOL instanceWasCached;

-(void)loadEnergyClockForDate:(NSDate *)date;

@end
