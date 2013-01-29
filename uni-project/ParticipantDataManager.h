//
//  ParticipantScoreManager.h
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticipantDataManager : NSObject

/** This method starts a sequence of methods, that calculate the selected user's rank
 
 @param _id sensor id or user id of the selected user in the master table
 @param isReachable reachibility-flag, NetworkStatus
 */
+ (void)startCalculatingRankByParticipantId:(NSInteger)_id networkReachable:(BOOL)isReachable;


@end
