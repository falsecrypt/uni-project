//
//  ParticipantScoreManager.h
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticipantDataManager : NSObject


+ (void)startCalculatingRankByParticipantId:(NSInteger)_id networkReachable:(BOOL)isReachable;

- (NSNumber *)getScoreByParticipantId:(NSInteger)_id;

- (void)startCalculatingConsumptionSumForParticipantId:(NSInteger)_id;

- (void)syncConsumptionWithOperations:(NSMutableArray *)operations;

- (void)readyToSubmitRank;


@end
