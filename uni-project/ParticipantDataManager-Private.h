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

@property (nonatomic, assign) float     consumptionMonthsSum;
@property (nonatomic, assign) float     consumptionDaysSum;
@property (nonatomic, assign) float     totalDays;
@property (nonatomic, assign) int       monthsCounter;
@property (nonatomic, assign) int       daysCounter;
@property (nonatomic, assign) float     yearExtrapolation;
@property (nonatomic, assign) float     consumptionWithOfficeArea;
@property (nonatomic, assign) int       currentParticipantId;
@property (nonatomic, strong) NSString *currentPathForMonths;
@property (nonatomic, strong) NSString *currentPathForDays;
@property (nonatomic, strong) NSDate   *lastSyncDate;


@end
