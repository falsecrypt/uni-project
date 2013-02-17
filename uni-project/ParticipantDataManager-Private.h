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

@property (nonatomic) float consumptionMonthsSum;
@property (nonatomic) float consumptionDaysSum;
@property (nonatomic) float totalDays;
@property (nonatomic) int   monthsCounter;
@property (nonatomic) int   daysCounter;
@property (nonatomic) float yearExtrapolation;
@property (nonatomic) float consumptionWithOfficeArea;
@property (nonatomic) int  currentParticipantId;
@property (nonatomic, strong) NSString *currentPathForMonths;
@property (nonatomic, strong) NSString *currentPathForDays;
@property (nonatomic, strong) NSDate   *lastSyncDate;


@end
