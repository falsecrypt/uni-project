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

@interface ParticipantDataManager()

@property(nonatomic, assign)float consumptionMonthsSum;
@property(nonatomic, assign)float consumptionDaysSum;
@property(nonatomic, assign)int monthsCounter;
@property(nonatomic, assign)int daysCounter;

@end

@implementation ParticipantDataManager

NSString *currentPathForMonths;
NSString *currentPathForDays;
float yearExtrapolation;
static ParticipantDataManager *me;


+ (void)startCalculatingRankByParticipantId:(NSInteger)_id networkReachable: (BOOL)isReachable{
    if (isReachable) {
        me = [[ParticipantDataManager alloc]init];
        
        [me startCalculatingConsumptionSumForParticipantId:_id];
    }

}

- (void)startCalculatingConsumptionSumForParticipantId:(NSInteger)_id{
    self.consumptionMonthsSum = 0.0f;
    self.monthsCounter = 0;
    self.consumptionDaysSum = 0.0f;
    self.daysCounter = 0;
    yearExtrapolation = 0.0f;
        
    //AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@""]];
    // Temp array of operations
    NSMutableArray *tempOperations = [NSMutableArray array];
    // For every request, create operation
    
    currentPathForMonths = currentCostServerBaseURLString;
    currentPathForMonths = [currentPathForMonths stringByAppendingString:@"rpc.php?userID="];
    currentPathForMonths = [currentPathForMonths stringByAppendingString:[NSString stringWithFormat:@"%i",_id ]];
    currentPathForMonths = [currentPathForMonths stringByAppendingString:@"&action=get&what=aggregation_m"];
    NSLog(@"currentPathForMonths = %@", currentPathForMonths);
    
    currentPathForDays = currentCostServerBaseURLString;
    currentPathForDays =[currentPathForDays stringByAppendingString:@"rpc.php?userID="];
    currentPathForDays =[currentPathForDays stringByAppendingString:[NSString stringWithFormat:@"%d",_id ]];
    currentPathForDays =[currentPathForDays stringByAppendingString:@"&action=get&what=aggregation_d"];
    NSLog(@"currentPathForDays = %@", currentPathForDays);
    
    //Create 2 NSURLRequests
    NSURL *urlFirst = [[NSURL alloc] initWithString:currentPathForMonths];
    NSMutableURLRequest *finalrequestFirst = [[NSMutableURLRequest alloc] initWithURL:urlFirst];
    NSURL *urlSecond = [[NSURL alloc] initWithString:currentPathForDays];
    NSMutableURLRequest *finalrequestSecond = [[NSMutableURLRequest alloc] initWithURL:urlSecond];

    // AFNetworking Requests
    AFHTTPRequestOperation *operationFirst = [[AFHTTPRequestOperation alloc] initWithRequest:finalrequestFirst];
    AFHTTPRequestOperation *operationSecond = [[AFHTTPRequestOperation alloc] initWithRequest:finalrequestSecond];
    
    // Add requests to array
    [tempOperations addObject:operationFirst];
    [tempOperations addObject:operationSecond];


    [self syncConsumptionWithOperations:tempOperations];

    NSLog(@"Returning...");
    
}

-(void)syncConsumptionWithOperations:(NSMutableArray *)operations{

    [[AFAppDotNetAPIClient sharedClient]
     enqueueBatchOfHTTPRequestOperations:operations
     progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
         
         NSLog(@"numberOfCompletedOperations:%d / totalNumberOfOperations:%d", numberOfCompletedOperations, totalNumberOfOperations);
         
     } completionBlock:^(NSArray *operations) {

         
         for (AFHTTPRequestOperation *ro in operations) {
             
             if (ro.error) {
                 
                 NSLog(@"++++++++++++++ Operation error");
                 
             }else {
                 
                 NSLog(@"Operation OK: %@", [ro.responseData description]);
                 NSLog(@"ro.request.URL.absoluteURL: %@", ro.request.URL.absoluteURL);
                 //Months request
                 if ([ro.request.URL.absoluteString isEqualToString:currentPathForMonths]) {
                     
                     NSString *oneMonthData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components    = [oneMonthData componentsSeparatedByString:@";"];
                     
                     for (NSString *obj in components) {
                         NSArray *month = [obj componentsSeparatedByString:@"="];
                         NSLog(@"<==month : %@", month);
                         NSArray *monthAndYear = [month[0] componentsSeparatedByString:@"-"];
                         NSLog(@"[month objectAtIndex:0] : %@", month[0]);
                         NSLog(@"monthAndYear : %@==>", monthAndYear);
                         double temp = [month[1] doubleValue];
                         //NSDecimalNumber *monthConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                         self.consumptionMonthsSum += temp; //we need only max. 11 months TODO
                         self.monthsCounter++;
                         NSLog(@"monthsCounter(inside block): %i",self.monthsCounter);
                     }
                 }
                 //Days request
                 else if ([ro.request.URL.absoluteString isEqualToString:currentPathForDays]){
                     NSString *twoWeeksData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components   = [twoWeeksData componentsSeparatedByString:@";"];
                     
                     for (NSString *obj in components) {
                         
                         NSArray *day = [obj componentsSeparatedByString:@"="];
                         NSLog(@"<==day : %@", day);
                         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                         [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                         [dateFormatter setDateFormat:@"yy-MM-dd"];
                         NSDate *date = [dateFormatter dateFromString:day[0]];
                         NSLog(@"date : %@==>", date);
                         NSString *withoutComma = [day[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                         double temp = [withoutComma doubleValue];
                         //NSLog(@"dayConsumption : %@", dayConsumption);
                         self.consumptionDaysSum += temp;
                         self.daysCounter++; //we should save the last sync date
                         NSLog(@"daysCounter(inside block): %i",self.daysCounter);
                     }
                     
                 }
                 
                 
             }
             
             
         }//end completionBlock
         
         NSLog(@"****** JOB DONE! ******");
         //convert to days
         float totalDays = (self.monthsCounter * 30.0f) + (self.daysCounter);
         float yearPart = totalDays/365.0f;
         yearExtrapolation = (self.consumptionMonthsSum + self.consumptionDaysSum)/yearPart;
         NSLog(@"calling getConsumptionSumForParticipantId:");
         NSLog(@"yearExtrapolation: %f",yearExtrapolation);
         NSLog(@"yearPart: %f",yearPart);
         NSLog(@"totalDays: %f",totalDays);
         NSLog(@"monthsCounter: %i",self.monthsCounter);
         NSLog(@"daysCounter: %i",self.daysCounter);
         [me readyToSubmitRank];
     }];


}

-(void)readyToSubmitRank {
    float consumptionWithOfficeArea = yearExtrapolation/OfficeArea;
    NSInteger currentRank = 0;
    if (consumptionWithOfficeArea < 25.0f) {
        currentRank = APlusPlusPlus;
    }
    else if (consumptionWithOfficeArea <= 35.0f) {
        currentRank = APlusPlus;
    }
    else if (consumptionWithOfficeArea <= 45.0f) {
        currentRank = APlus;
    }
    else if (consumptionWithOfficeArea <= 55.0f) {
        currentRank = A;
    }
    else if (consumptionWithOfficeArea <= 65.0f) {
        currentRank = B;
    }
    else if (consumptionWithOfficeArea <= 75.0f) {
        currentRank = C;
    }
    else if (consumptionWithOfficeArea > 75.0f) {
        currentRank = D;
    }
    NSNumber *rankAsNumber = [NSNumber numberWithInt:currentRank];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RankWasCalculated" object:rankAsNumber userInfo:nil];
}

- (NSNumber *)getScoreByParticipantId:(NSInteger)_id{
    
}

@end
