//
//  ParticipantScoreManager.m
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import "ParticipantDataManager.h"
#import "Reachability.h"
#import "EMNetworkManager.h"
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


- (void)startCalculatingRankAndScoreWithNetworkStatus: (BOOL)isReachable {
    
    if (isReachable) {
        NSNumber *numberofentities = [Participant numberOfEntities];
        DLog(@"startCalculatingRankAndScoreWithNetworkStatus numberofentities %@", numberofentities);
        [self startCalculatingConsumptionSumForParticipantId:self.currentParticipantId];
        
    }
    else {
        
        if ([Participant hasAtLeastOneEntity]) {
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            NSString *RankWasCalculatedWithId_ = [RankWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d", self.currentParticipantId]];
            [center postNotificationName:RankWasCalculatedWithId_ object:participant.rank userInfo:nil];
            NSString *ScoreWasCalculatedWithId_ = [ScoreWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            [center postNotificationName:ScoreWasCalculatedWithId_ object:participant.score userInfo:nil];
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
    //DLog(@"currentPathForMonths = %@", self.currentPathForMonths);
    
    self.currentPathForDays = currentCostServerBaseURLString;
    self.currentPathForDays =[self.currentPathForDays stringByAppendingString:@"rpc.php?userID="];
    self.currentPathForDays =[self.currentPathForDays stringByAppendingString:[NSString stringWithFormat:@"%d",_id ]];
    self.currentPathForDays =[self.currentPathForDays stringByAppendingString:@"&action=get&what=aggregation_d"];
    //DLog(@"currentPathForDays = %@", self.currentPathForDays);
    
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

    //DLog(@"Returning...");
    
}

-(void)syncConsumptionWithOperations:(NSMutableArray *)operations{
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    //NSInteger day = [components day];
    //NSInteger month = [components month];
    NSInteger currentYear = [components year];

    [[EMNetworkManager sharedClient]
     enqueueBatchOfHTTPRequestOperations:operations
     progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
         
         //DLog(@"numberOfCompletedOperations:%d / totalNumberOfOperations:%d", numberOfCompletedOperations, totalNumberOfOperations);
         
     } completionBlock:^(NSArray *operations) {

         
         for (AFHTTPRequestOperation *ro in operations) {
             
             if (ro.error) {
                 
                 DLog(@"++++++++++++++ Operation error");
                 
             }else {
                 
                 //DLog(@"Operation OK: %@", [ro.responseData description]);
                 //DLog(@"ro.request.URL.absoluteURL: %@", ro.request.URL.absoluteURL);
                 //Months request
                 if ([ro.request.URL.absoluteString isEqualToString:self.currentPathForMonths]) {
                     
                     NSString *oneMonthData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components    = [oneMonthData componentsSeparatedByString:@";"];
                     
                     for (NSString *obj in components) {
                         
                         NSArray *month = [obj componentsSeparatedByString:@"="];
                         //DLog(@"<==month : %@", month);
                         NSArray *monthAndYear = [month[0] componentsSeparatedByString:@"-"];
                         NSInteger year = [monthAndYear[0] integerValue];
                         // consider only consumption of the current year
                         if (year == currentYear) {
                             
                             //DLog(@"[monthAndYear objectAtIndex:1] : %@", monthAndYear[1]);
                             //DLog(@"[monthAndYear objectAtIndex:0] : %@", monthAndYear[0]);
                             //DLog(@"monthAndYear : %@==>", monthAndYear);
                             double temp = [month[1] doubleValue];
                             //NSDecimalNumber *monthConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                             self.consumptionMonthsSum += temp;
                             self.monthsCounter++;
                             
                         }
                         //DLog(@"monthConsumption(inside block): %@",monthConsumption);
                     }
                 }
                 //Days request
                 else if ([ro.request.URL.absoluteString isEqualToString:self.currentPathForDays]){
                     NSString *twoWeeksData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components   = [twoWeeksData componentsSeparatedByString:@";"];
                     
                     for (NSString *obj in components) {
                         
                         NSArray *day = [obj componentsSeparatedByString:@"="];
                         //DLog(@"<==day : %@", day);
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
                         
                         DLog(@"day date : %@", date);
                         NSString *withoutComma = [day[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                         double temp = [withoutComma doubleValue];
                         //DLog(@"dayConsumption : %@", dayConsumption);
                         self.consumptionDaysSum += temp;
                         self.daysCounter++;
                         
                     }
                     
                 }
                 
                 
             }
             
             
         }//end completionBlock
         
         //DLog(@"****** JOB DONE! ******");
         //convert to days
         self.totalDays = (self.monthsCounter * 30.0f) + (self.daysCounter);
         float yearPart = self.totalDays/365.0f;
         self.yearExtrapolation = (self.consumptionMonthsSum + self.consumptionDaysSum)/yearPart;
//         DLog(@"calling getConsumptionSumForParticipantId:");
//         DLog(@"yearExtrapolation: %f",self.yearExtrapolation);
//         DLog(@"yearPart: %f",yearPart);
//         DLog(@"totalDays: %f",totalDays);
//         DLog(@"monthsCounter: %i",self.monthsCounter);
//         DLog(@"daysCounter: %i",self.daysCounter);
         [self readyToSubmitRank];
         DLog(@"self.lastSyncDate : %@",self.lastSyncDate);
         
     }];


}

-(void)readyToSubmitRank {
    self.consumptionWithOfficeArea = self.yearExtrapolation/OfficeArea;
    DLog(@"consumptionWithOfficeArea: %f",self.consumptionWithOfficeArea);
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
            DLog(@"<ParticipantDataManager> saving rank - participant.rank: %@", participantLocal.rank);
            DLog(@"<ParticipantDataManager> saving sync date - participant.updated: %@", participantLocal.updated);

            
        } completion:^{
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
            DLog(@"<ParticipantDataManager> readyToSubmitRank current score: %@, self.currentParticipantId: %i, participantObj: %@", participant.score, self.currentParticipantId, participant);
            
            [[NSManagedObjectContext contextForCurrentThread] saveNestedContexts];
            
            [self calculateParticipantScore];
            
            //DLog(@"!!!!!!!!! <ParticipantDataManager> sending 'RankWasCalculated' Notification !!!!!!!!!!!");

            NSString *RankWasCalculatedWithId_ = [RankWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            // touching UI? -> main thread!
            [[NSNotificationCenter defaultCenter] postNotificationName:RankWasCalculatedWithId_ object:rankAsNumber userInfo:nil];
            
        }];
    }


}

- (void)calculateParticipantScore{
    
    Participant *participant =
    [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId]];
    DLog(@"<ParticipantDataManager> calculateParticipantScore current score: %@, self.currentParticipantId: %i, participantObj: %@", participant.score, self.currentParticipantId, participant);
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
            //DLog(@"<ParticipantDataManager> saving score - participant.rank: %@", participant.score);
            
        } completion:^{
            
            Participant *participant =
            [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:[NSManagedObjectContext contextForCurrentThread]];
            
             [[NSManagedObjectContext contextForCurrentThread] saveNestedContexts];
            
            DLog(@"<ParticipantDataManager> saving score!! - participant.score: %@", participant.score);
            
            NSString *ScoreWasCalculatedWithId_ = [ScoreWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
            // notify the corresponding instance of PublicDetailViewController
            [[NSNotificationCenter defaultCenter] postNotificationName:ScoreWasCalculatedWithId_ object:[NSNumber numberWithFloat:score] userInfo:nil];
            
        }];
        
        
        DLog(@"<ParticipantDataManager> score: %f", score);
        
    }
    // get 'updated' from participant object
    // and if it is less than today, update the rank!
    else {
        Participant *participant =
        [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.currentParticipantId] inContext:[NSManagedObjectContext contextForCurrentThread]];
        
        NSString *ScoreWasCalculatedWithId_ = [ScoreWasCalculated stringByAppendingString:[NSString stringWithFormat:@"%d",self.currentParticipantId]];
        // notify the corresponding instance of PublicDetailViewController
        [[NSNotificationCenter defaultCenter] postNotificationName:ScoreWasCalculatedWithId_ object:participant.score userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ScoreWasCalculatedWithId object:@{@(self.currentParticipantId): participant.score} userInfo:nil];
    }
    
    
    
}

@end
