//
//  EnergyClockDataManager.h
//  uni-project
//
//  Created by Pavel Ermolin on 08.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DayChartsDelegate <NSObject>

- (void)dayValuesCalculated:(NSArray *)dayValues;

@end

@protocol MultiLevelPieChartDelegate <NSObject>

- (void)energyClockValuesCalculated:(NSArray *)sliceValues slotValues:(NSArray *)slotValues;

@end

/** Provides Pie Chart data for the EnergyClockDataViewController and for the ScrollViewContentViewController.
 After calculating EnergyClockDataManager informs its delegates using DayChartsDelegate and MultiLevelPieChartDelegate protocols.
 *
 */
@interface EnergyClockDataManager : NSObject

@property (nonatomic, weak) id<DayChartsDelegate> dayChartsDelegate;
@property (nonatomic, weak) id<MultiLevelPieChartDelegate> multiLevelPieChartDelegate;

@end
