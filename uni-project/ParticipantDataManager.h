//
//  ParticipantScoreManager.h
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticipantDataManager : NSObject

/** This method starts a sequence of methods, that calculate the selected user's rank and score
 
 @param isReachable reachibility-flag, NetworkStatus
 */
- (void)startCalculatingRankAndScoreWithNetworkStatus: (BOOL)isReachable;

// Designated initializer.
- (id)initWithParticipantId: (NSInteger)_id;


@end
