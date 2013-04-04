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
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *radiusValuesForSlice;
@property (nonatomic, strong, readonly) NSMutableArray *viewControllers;

-(void)loadEnergyClockForDate:(NSDate *)date;

@end
