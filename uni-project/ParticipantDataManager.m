//
//  ParticipantScoreManager.m
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import "ParticipantDataManager.h"
#import "Reachability.h"
#import "AFAppDotNetAPIClient.h"
#import "Participant.h"
#import "AFHTTPRequestOperation.h"

// class extension (anonymous category)
@interface ParticipantDataManager()

- (NSNumber *)getScoreByParticipantId:(NSInteger)_id;

- (void)startCalculatingConsumptionSumForParticipantId:(NSInteger)_id;

- (void)syncConsumptionWithOperations:(NSMutableArray *)operations;

- (void)readyToSubmitRank;

@property float consumptionMonthsSum;
@property float consumptionDaysSum;
@property int   monthsCounter;
@property int   daysCounter;
@property float yearExtrapolation;
@property int   currentParticipantId;
@property float consumptionWithOfficeArea;
@property(nonatomic, strong)NSString *currentPathForMonths;
@property(nonatomic, strong)NSString *currentPathForDays;

@end

//////////////////IMPLEMENTATION START////////////////////

@implementation ParticipantDataManager



+ (void)startCalculatingRankByParticipantId:(NSInteger)_id networkReachable: (BOOL)isReachable{
    if (isReachable) {
        
        ParticipantDataManager *me = [[ParticipantDataManager alloc]init];
        [me startCalculatingConsumptionSumForParticipantId:_id];
    }
    else {
        NSNumber *numberofentities = [Participant numberOfEntities];
        //NSLog(@"<ParticipantDataManager> OFFLINE numberofentities: %@", numberofentities);
        if (numberofentities > 0) {
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:_id]];
            //NSLog(@"<ParticipantDataManager> found participant: %@", participant);
            NSString *notificationName = @"RankWasCalculated";
            notificationName = [notificationName stringByAppendingString:[NSString stringWithFormat:@"%d", _id]];
            //NSLog(@"<ParticipantDataManager> notificationName: %@", notificationName);
            //NSLog(@"<ParticipantDataManager> participant.rank: %@", participant.rank);
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:participant.rank userInfo:nil];
        }
    }

}

- (void)startCalculatingConsumptionSumForParticipantId:(NSInteger)_id{
    self.consumptionMonthsSum = 0.0f;
    self.monthsCounter = 0;
    self.consumptionDaysSum = 0.0f;
    self.daysCounter = 0;
    self.yearExtrapolation = 0.0f;
    self.currentParticipantId = _id;
        
    //AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    // Temp array of operations
    NSMutableArray *tempOperations = [NSMutableArray array];
    // For every request, create operation
    
    self.currentPathForMonths = currentCostServerBaseURLString;
    self.currentPathForMonths = [self.currentPathForMonths stringByAppendingString:@"rpc.php?userID="];
    self.currentPathForMonths = [self.currentPathForMonths stringByAppendingString:[NSString stringWithFormat:@"%i",_id ]];
    self.currentPathForMonths = [self.currentPathForMonths stringByAppendingString:@"&action=get&what=aggregation_m"];
    //NSLog(@"currentPathForMonths = %@", self.currentPathForMonths);
    
    self.currentPathForDays = currentCostServerBaseURLString;
    self.currentPathForDays =[self.currentPathForDays stringByAppendingString:@"rpc.php?userID="];
    self.currentPathForDays =[self.currentPathForDays stringByAppendingString:[NSString stringWithFormat:@"%d",_id ]];
    self.currentPathForDays =[self.currentPathForDays stringByAppendingString:@"&action=get&what=aggregation_d"];
    //NSLog(@"currentPathForDays = %@", self.currentPathForDays);
    
    //Create 2 NSURLRequests
    NSURL *urlFirst = [[NSURL alloc] initWithString:self.currentPathForMonths];
    NSMutableURLRequest *finalrequestFirst = [[NSMutableURLRequest alloc] initWithURL:urlFirst];
    NSURL *urlSecond = [[NSURL alloc] initWithString:self.currentPathForDays];
    NSMutableURLRequest *finalrequestSecond = [[NSMutableURLRequest alloc] initWithURL:urlSecond];

    // AFNetworking Requests
    AFHTTPRequestOperation *operationFirst = [[AFHTTPRequestOperation alloc] initWithRequest:finalrequestFirst];
    AFHTTPRequestOperation *operationSecond = [[AFHTTPRequestOperation alloc] initWithRequest:finalrequestSecond];
    
    // Add requests to array
    [tempOperations addObject:operationFirst];
    [tempOperations addObject:operationSecond];


    [self syncConsumptionWithOperations:tempOperations];

    //NSLog(@"Returning...");
    
}

-(void)syncConsumptionWithOperations:(NSMutableArray *)operations{

    [[AFAppDotNetAPIClient sharedClient]
     enqueueBatchOfHTTPRequestOperations:operations
     progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
         
         //NSLog(@"numberOfCompletedOperations:%d / totalNumberOfOperations:%d", numberOfCompletedOperations, totalNumberOfOperations);
         
     } completionBlock:^(NSArray *operations) {

         
         for (AFHTTPRequestOperation *ro in operations) {
             
             if (ro.error) {
                 
                 NSLog(@"++++++++++++++ Operation error");
                 
             }else {
                 
                 //NSLog(@"Operation OK: %@", [ro.responseData description]);
                 //NSLog(@"ro.request.URL.absoluteURL: %@", ro.request.URL.absoluteURL);
                 //Months request
                 if ([ro.request.URL.absoluteString isEqualToString:self.currentPathForMonths]) {
                     
                     NSString *oneMonthData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components    = [oneMonthData componentsSeparatedByString:@";"];
                     
                     for (NSString *obj in components) {
                         
                         NSArray *month = [obj componentsSeparatedByString:@"="];
                         //NSLog(@"<==month : %@", month);
                         //NSArray *monthAndYear = [month[0] componentsSeparatedByString:@"-"];
                         //NSLog(@"[month objectAtIndex:0] : %@", month[0]);
                         //NSLog(@"monthAndYear : %@==>", monthAndYear);
                         double temp = [month[1] doubleValue];
                         //NSDecimalNumber *monthConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                         self.consumptionMonthsSum += temp; //we need only max. 11 months TODO
                         self.monthsCounter++;
                         //NSLog(@"monthConsumption(inside block): %@",monthConsumption);
                     }
                 }
                 //Days request
                 else if ([ro.request.URL.absoluteString isEqualToString:self.currentPathForDays]){
                     NSString *twoWeeksData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components   = [twoWeeksData componentsSeparatedByString:@";"];
                     
                     for (NSString *obj in components) {
                         
                         NSArray *day = [obj componentsSeparatedByString:@"="];
                         //NSLog(@"<==day : %@", day);
                         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                         [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                         [dateFormatter setDateFormat:@"yy-MM-dd"];
                         //NSDate *date = [dateFormatter dateFromString:day[0]];
                         //NSLog(@"date : %@==>", date);
                         NSString *withoutComma = [day[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                         double temp = [withoutComma doubleValue];
                         //NSLog(@"dayConsumption : %@", dayConsumption);
                         self.consumptionDaysSum += temp;
                         self.daysCounter++; //we should save the last sync date
                         //NSLog(@"daysCounter(inside block): %i",self.daysCounter);
                     }
                     
                 }
                 
                 
             }
             
             
         }//end completionBlock
         
         //NSLog(@"****** JOB DONE! ******");
         //convert to days
         float totalDays = (self.monthsCounter * 30.0f) + (self.daysCounter);
         float yearPart = totalDays/365.0f;
         self.yearExtrapolation = (self.consumptionMonthsSum + self.consumptionDaysSum)/yearPart;
//         NSLog(@"calling getConsumptionSumForParticipantId:");
//         NSLog(@"yearExtrapolation: %f",self.yearExtrapolation);
//         NSLog(@"yearPart: %f",yearPart);
//         NSLog(@"totalDays: %f",totalDays);
//         NSLog(@"monthsCounter: %i",self.monthsCounter);
//         NSLog(@"daysCounter: %i",self.daysCounter);
         [self readyToSubmitRank];
         
     }];


}

-(void)readyToSubmitRank {
    self.consumptionWithOfficeArea = self.yearExtrapolation/OfficeArea;
    NSLog(@"consumptionWithOfficeArea: %f",self.consumptionWithOfficeArea);
    NSInteger currentRank = 0;
    if (self.consumptionWithOfficeArea < 25.0f) {
        currentRank = APlusPlusPlus;
    }
    else if (self.consumptionWithOfficeArea <= 35.0f) {
        currentRank = APlusPlus;
    }
    else if (self.consumptionWithOfficeArea <= 45.0f) {
        currentRank = APlus;
    }
    else if (self.consumptionWithOfficeArea <= 55.0f) {
        currentRank = A;
    }
    else if (self.consumptionWithOfficeArea <= 65.0f) {
        currentRank = B;
    }
    else if (self.consumptionWithOfficeArea <= 75.0f) {
        currentRank = C;
    }
    else if (self.consumptionWithOfficeArea > 75.0f) {
        currentRank = D;
    }
    NSNumber *rankAsNumber = [NSNumber numberWithInt:currentRank];
    NSNumber *numberofentities = [Participant numberOfEntities];
    if (numberofentities > 0) {
        
        [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext){

            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:localContext];
            participant.rank = rankAsNumber;
            NSLog(@"<ParticipantDataManager> saving rank - participant.rank: %@", participant.rank);
            
        } completion:^{
            
            //Participant *updatedParticipant =
            //[Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
            //NSLog(@"updatedParticipant: %@", updatedParticipant);
        }];
    }

    //NSLog(@"!!!!!!!!! <ParticipantDataManager> sending 'RankWasCalculated' Notification !!!!!!!!!!!");
    NSString *notificationName = @"RankWasCalculated";
    notificationName = [notificationName stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
    // notify the corresponding instance of PublicDetailViewController
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:rankAsNumber userInfo:nil];
}

- (NSNumber *)getScoreByParticipantId:(NSInteger)_id{
    
    
    
    
}

@end
