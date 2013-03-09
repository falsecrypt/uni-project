//
//  EnergyClockDataManager.m
//  uni-project
//
//  Created by Pavel Ermolin on 08.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "EnergyClockDataManager.h"
#import "EMNetworkManager.h"
#import "Reachability.h"

@interface EnergyClockDataManager ()

@property (nonatomic, strong) Reachability *reachabilityObj;
@property (nonatomic, assign) BOOL deviceIsOnline;
@property (nonatomic, strong) NSArray *participants;

@end

@implementation EnergyClockDataManager

- (id)init{
    if (self = [super init]){
        // avoiding retain cycle
        __weak EnergyClockDataManager *weakSelf = self;
        self.reachabilityObj.reachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Block Says Reachable");
                weakSelf.deviceIsOnline = YES;
            });
        };
        
        self.reachabilityObj.unreachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Block Says Unreachable");
                weakSelf.deviceIsOnline = NO;
            });
        };
        
        [self.reachabilityObj startNotifier];
        
        self.participants = [[NSArray alloc] initWithObjects:
                             [NSNumber numberWithInteger:FirstSensorID],
                             [NSNumber numberWithInteger:SecondSensorID],
                             [NSNumber numberWithInteger:ThirdSensorID], nil];
    }
    
    return self;
}

// Lazy instantiation
- (Reachability *) reachabilityObj
{
    if(!_reachabilityObj)
    {
        _reachabilityObj = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    }
    return _reachabilityObj;
}

-(void)calculateValuesWithMode:(NSString *)mode
{
    if (self.deviceIsOnline)
    {
        if ([mode isEqualToString:DayChartsMode])
        {
            [self getDataFromServerWithMode:DayChartsMode];
        }
        else if ([mode isEqualToString:MultiLevelPieChartMode])
        {
            [self getDataFromServerWithMode:MultiLevelPieChartMode];
        }
    }
    else
    {
        /*NSNumber *numberofentities = [Participant numberOfEntities];
        
        if (numberofentities > 0) {
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            NSString *RankWasCalculatedWithId = [RankWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d", self.currentParticipantId]];
            [center postNotificationName:RankWasCalculatedWithId object:participant.rank userInfo:nil];
            NSString *ScoreWasCalculatedWithId = [ScoreWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            [center postNotificationName:ScoreWasCalculatedWithId object:participant.score userInfo:nil];
        } */
        
    }
}

-(void)getDataFromServerWithMode:(NSString *)mode
{
    if ([mode isEqualToString:DayChartsMode])
    {
        
        for (NSNumber *userId in self.participants) {
            [self getKwPerHourForLastWeekWithUserId:userId];
        }
        
    }
    else if ([mode isEqualToString:MultiLevelPieChartMode])
    {
        
    }
}

-(void)getKwPerHourForLastWeekWithUserId:(NSNumber *)userId
{
    NSString *getPath = @"rpc.php?userID=";
    getPath = [getPath stringByAppendingString:[NSString stringWithFormat:@"%i",[userId intValue]]];
    getPath = [getPath stringByAppendingString:@"&action=get&what=aggregation_h"];
    [[EMNetworkManager sharedClient] getPath:getPath
                                  parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id data) {
                                         
                                         NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                         [self proccessWithOperationResult:result];
                                     
                                     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         
                                     }];
}

-(void)proccessWithOperationResult:(NSString *)result
{
    // split the result-string, create and store Model-Objects in the DB
    NSArray *resultComponents   = [result componentsSeparatedByString:@";"];
    for (NSString *obj in resultComponents)
    {
        
    }
}

@end
