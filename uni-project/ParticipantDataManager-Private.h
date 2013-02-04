//
//  ParticipantDataManager-Private.h
//  uni-project
//
//  Created by Pavel Ermolin on 04.02.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "ParticipantDataManager.h"


// class extension (anonymous category)
// private methods and properties of ParticipantDataManager Class
@interface ParticipantDataManager ()

- (void)startCalculatingConsumptionSumForParticipantId:(NSInteger)_id;

- (void)syncConsumptionWithOperations:(NSMutableArray *)operations;

- (void)readyToSubmitRank;

- (void)calculateParticipantScore;

- (void)initScalarAttributes;

@property float consumptionMonthsSum;
@property float consumptionDaysSum;
@property float totalDays;
@property int   monthsCounter;
@property int   daysCounter;
@property float yearExtrapolation;
@property float consumptionWithOfficeArea;
@property int  currentParticipantId;
@property(nonatomic, strong)NSString *currentPathForMonths;
@property(nonatomic, strong)NSString *currentPathForDays;
@property(nonatomic, strong)NSDate   *lastSyncDate;


@end
