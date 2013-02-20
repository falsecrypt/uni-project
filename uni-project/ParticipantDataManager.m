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
#import "ParticipantDataManager-Private.h"

// class extension (anonymous category)
@interface ParticipantDataManager()

@end

//////////////////IMPLEMENTATION START////////////////////

@implementation ParticipantDataManager



- (id)initWithParticipantId: (NSInteger)_id {
    if (self = [super init]){
        [self initScalarAttributes];
        self.currentParticipantId = _id;
    }
    
    return self;
}

- (void)initScalarAttributes {
    self.consumptionMonthsSum = 0.0f;
    self.monthsCounter = 0;
    self.consumptionDaysSum = 0.0f;
    self.daysCounter = 0;
    self.yearExtrapolation = 0.0f;
    self.totalDays = 0.0f;
}


- (void)startCalculatingRankAndScoreWithNetworkStatus: (BOOL)isReachable{
    if (isReachable) {
        
        [self startCalculatingConsumptionSumForParticipantId:self.currentParticipantId];
    }
    else {
        NSNumber *numberofentities = [Participant numberOfEntities];
        //NSLog(@"<ParticipantDataManager> OFFLINE numberofentities: %@", numberofentities);
        if (numberofentities > 0) {
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
            //NSLog(@"<ParticipantDataManager> found participant: %@", participant);
            NSString *notificationName = @"RankWasCalculated";
            notificationName = [notificationName stringByAppendingString:[NSString stringWithFormat:@"%d", self.currentParticipantId]];
            //NSLog(@"<ParticipantDataManager> notificationName: %@", notificationName);
            //NSLog(@"<ParticipantDataManager> participant.rank: %@", participant.rank);
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:participant.rank userInfo:nil];
            
            NSString *notificationNameScore = @"ScoreWasCalculated";
            notificationNameScore = [notificationNameScore stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationNameScore object:participant.score userInfo:nil];
        }
    }

}

- (void)startCalculatingConsumptionSumForParticipantId:(NSInteger)_id{

        
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
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    //NSInteger day = [components day];
    //NSInteger month = [components month];
    NSInteger currentYear = [components year];

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
                         NSArray *monthAndYear = [month[0] componentsSeparatedByString:@"-"];
                         NSInteger year = [monthAndYear[0] integerValue];
                         // consider only consumption of the current year
                         if (year == currentYear) {
                             
                             //NSLog(@"[monthAndYear objectAtIndex:1] : %@", monthAndYear[1]);
                             //NSLog(@"[monthAndYear objectAtIndex:0] : %@", monthAndYear[0]);
                             //NSLog(@"monthAndYear : %@==>", monthAndYear);
                             double temp = [month[1] doubleValue];
                             //NSDecimalNumber *monthConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                             self.consumptionMonthsSum += temp;
                             self.monthsCounter++;
                             
                         }
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
                         NSDate *date = [dateFormatter dateFromString:day[0]];
                         if (!self.lastSyncDate) {
                             self.lastSyncDate = [date copy];
                         }
                         else {
                             NSComparisonResult result = [self.lastSyncDate compare:date];
                             //self.lastSyncDate is less
                             if(result==NSOrderedAscending) {
                                 self.lastSyncDate = [date copy];
                             }
                         }
                         
                         NSLog(@"day date : %@", date);
                         NSString *withoutComma = [day[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                         double temp = [withoutComma doubleValue];
                         //NSLog(@"dayConsumption : %@", dayConsumption);
                         self.consumptionDaysSum += temp;
                         self.daysCounter++;
                         
                     }
                     
                 }
                 
                 
             }
             
             
         }//end completionBlock
         
         //NSLog(@"****** JOB DONE! ******");
         //convert to days
         self.totalDays = (self.monthsCounter * 30.0f) + (self.daysCounter);
         float yearPart = self.totalDays/365.0f;
         self.yearExtrapolation = (self.consumptionMonthsSum + self.consumptionDaysSum)/yearPart;
//         NSLog(@"calling getConsumptionSumForParticipantId:");
//         NSLog(@"yearExtrapolation: %f",self.yearExtrapolation);
//         NSLog(@"yearPart: %f",yearPart);
//         NSLog(@"totalDays: %f",totalDays);
//         NSLog(@"monthsCounter: %i",self.monthsCounter);
//         NSLog(@"daysCounter: %i",self.daysCounter);
         [self readyToSubmitRank];
         NSLog(@"self.lastSyncDate : %@",self.lastSyncDate);
         
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

            Participant *participantLocal =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:localContext];
            participantLocal.rank = rankAsNumber;
            //participantLocal.updated = self.lastSyncDate;
            [participantLocal setUpdated:self.lastSyncDate];
            NSLog(@"<ParticipantDataManager> saving rank - participant.rank: %@", participantLocal.rank);
            NSLog(@"<ParticipantDataManager> saving sync date - participant.updated: %@", participantLocal.updated);

            
        } completion:^{
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
            NSLog(@"<ParticipantDataManager> readyToSubmitRank current score: %@, self.currentParticipantId: %i, participantObj: %@", participant.score, self.currentParticipantId, participant);
            
            [[NSManagedObjectContext contextForCurrentThread] saveNestedContexts];
            
            [self calculateParticipantScore];
            
            //NSLog(@"!!!!!!!!! <ParticipantDataManager> sending 'RankWasCalculated' Notification !!!!!!!!!!!");
            NSString *notificationName = @"RankWasCalculated";
            notificationName = [notificationName stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:rankAsNumber userInfo:nil];
            
        }];
    }


}

- (void)calculateParticipantScore{
    
    Participant *participant =
    [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
    NSLog(@"<ParticipantDataManager> calculateParticipantScore current score: %@, self.currentParticipantId: %i, participantObj: %@", participant.score, self.currentParticipantId, participant);
    // he has no score yet
    if (participant.score.intValue == 0) {
        // 'Zaehler'
        float numerator = 75.0f/365.0f; //kwh per day per mˆ2 = max consumption per day

        //float scoreTemp = numerator/denominator;
        float yearConsumptionSum = (self.consumptionMonthsSum + self.consumptionDaysSum); // we use consumption only of the current year
        float consumptionPerDay = yearConsumptionSum/self.totalDays;
        // 'Nenner'
        float denominator = consumptionPerDay/OfficeArea;
        
        float score = self.totalDays * (numerator/denominator); //avg score
        
        [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext){
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:localContext];
            participant.score = [NSNumber numberWithFloat:score];
            //NSLog(@"<ParticipantDataManager> saving score - participant.rank: %@", participant.score);
            
        } completion:^{
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:[NSManagedObjectContext contextForCurrentThread]];
            
             [[NSManagedObjectContext contextForCurrentThread] saveNestedContexts];
            
            NSLog(@"<ParticipantDataManager> saving score!! - participant.score: %@", participant.score);
            
            NSString *notificationName = @"ScoreWasCalculated";
            notificationName = [notificationName stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:[NSNumber numberWithFloat:score] userInfo:nil];
            
        }];
        
        
        NSLog(@"<ParticipantDataManager> score: %f", score);
        
    }
    // get 'updated' from participant object
    // and if it is less than today, update the rank!
    else {
        Participant *participant =
        [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:[NSManagedObjectContext contextForCurrentThread]];
        
        NSString *notificationName = @"ScoreWasCalculated";
        notificationName = [notificationName stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
        // notify the corresponding instance of PublicDetailViewController
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:participant.score userInfo:nil];
    }
    
    
    
}

@end
