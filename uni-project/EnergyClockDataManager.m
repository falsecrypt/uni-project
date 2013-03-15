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
#import "EcoMeterAppDelegate.h"
#import "AggregatedDay.h"
#import "AFJSONRequestOperation.h"

@interface EnergyClockDataManager ()

@property (nonatomic, strong) NSArray *participants;
@property (nonatomic, assign) BOOL deviceIsOnline;

@end

@implementation EnergyClockDataManager

static const NSArray *serverHours;


+ (EnergyClockDataManager *)sharedClient {
    static EnergyClockDataManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[EnergyClockDataManager alloc] init];
    });
    return _sharedClient;
}

- (id)init{
    
    if (self = [super init]){
        
        self.participants = [[NSArray alloc] initWithObjects:
                             [NSNumber numberWithInteger:FirstSensorID],
                             [NSNumber numberWithInteger:SecondSensorID],
                             [NSNumber numberWithInteger:ThirdSensorID], nil];
        
        NSMutableArray *tempHours = [[NSMutableArray alloc] init];
        for (NSInteger i=1; i<=24; i+=2) {
            [tempHours addObject:@(i)]; // 12 possible hour-values
        }
        serverHours = [tempHours copy];
    }
    
    return self;
}

-(void)reachabilityChanged
{
    
}

-(void)calculateValuesWithMode:(NSString *)mode
{
    EcoMeterAppDelegate *appDelegate = (EcoMeterAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.deviceIsOnline = appDelegate.deviceIsOnline;
    //NSLog(@"<calculateValuesWithMode> self.deviceIsOnline: %i", self.deviceIsOnline);
    
    if (self.deviceIsOnline)
    {
        if ([mode isEqualToString:DayChartsMode])
        {
            NSDateComponents *todayComponents =
            [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
            System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
            NSAssert(systemObj!=nil, @"System Object with id=primary doesnt exist");
            NSDate *lastSyncDate = systemObj.daysupdated;
            if (lastSyncDate) { // we have synced already
                NSDateComponents *lastSyncComponents =
                [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:lastSyncDate];
                
                if(([todayComponents year]  != [lastSyncComponents year])  ||
                   ([todayComponents month] != [lastSyncComponents month]) ||
                   ([todayComponents day]   != [lastSyncComponents day]))
                {
                    // OK, we havent synced today yet
                    [self getDataFromServerWithMode:DayChartsMode];
                }
                
                // DEBUG MODE
                else if (FORCEDAYCHARTSUPDATE){
                    [self getDataFromServerWithMode:DayChartsMode];
                }
            }
            // first sync ever?
            else {
                [self getDataFromServerWithMode:DayChartsMode];
            }

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
    NSLog(@"getDataFromServerWithMode...");
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
    NSLog(@"getKwPerHourForLastWeekWithUserId...");
    NSString *getPath = @"rpc.php?userID=";
    getPath = [getPath stringByAppendingString:[NSString stringWithFormat:@"%i",[userId intValue]]];
    getPath = [getPath stringByAppendingString:@"&action=get&what=aggregation_h"];
    [[EMNetworkManager sharedClient] getPath:getPath
                                  parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id data) {
                                         [AggregatedDay truncateAll];
                                         NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                         // sync sunrise and sunset values first
                                         [self syncSunriseSunsetDataWithResult:result forMode:DayChartsMode];
                                     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         
                                     }];
}

-(void)proccessWithOperationResult:(NSString *)result forMode:(NSString *)mode sunriseSunsetData:(NSDictionary*)sunriseSunset
{
    NSLog(@"proccessWithOperationResult...");
    if ([mode isEqualToString:DayChartsMode]) {
        // calculate the actual sunset/sunrise time we want to display
        //NSLog(@"sunriseSunset: %@", sunriseSunset);
        //NSLog(@"serverHours: %@", serverHours);
        NSUInteger sunriseHour = [[[sunriseSunset objectForKey:@"sunrise"] objectForKey:@"hour"] integerValue];
        if (![serverHours containsObject:@(sunriseHour)]) {
            sunriseHour += 1;
        }
        NSUInteger sunsetHour = [[[sunriseSunset objectForKey:@"sunset"] objectForKey:@"hour"] integerValue];
        if (![serverHours containsObject:@(sunsetHour)]) {
            sunsetHour += 1;
        }
        
        // split the result-string, extract the values, create and store Model-Objects in the DB
        // calculate day and night consumption for this user
        NSArray *resultComponents   = [result componentsSeparatedByString:@";"];
        NSLog(@"resultComponents: %@", resultComponents);
        for (NSString *obj in resultComponents)
        {
            NSArray *data = [obj componentsSeparatedByString:@"="];
            NSString *dateString = [data[0] substringWithRange:(NSMakeRange(0, 8))];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
            [dateFormatter setDateFormat:@"yy-MM-dd"];
            NSDate *date = [dateFormatter dateFromString:dateString];
            NSString *hour = [data[0] substringWithRange:(NSMakeRange(9, 2))];
            NSString *withoutComma = [data[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
            double temp = [withoutComma doubleValue];
            NSDecimalNumber *consumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
            //NSLog(@"date: %@", date);
            //NSLog(@"hour: %@", hour);
            //NSLog(@"consumption: %@", consumption);
            
            AggregatedDay *day = [AggregatedDay findFirstByAttribute:@"date" withValue:date];
            if (day) { // day already exists -> update
                NSLog(@"UPDATING DAY");
                NSLog(@"updating... date: %@", day.date);
                NSLog(@"updating... nightconsumption: %@", day.nightconsumption);
                NSLog(@"updating... dayconsumption: %@", day.dayconsumption);
                NSLog(@"updating... current hour: %i, sunriseHour: %i, sunsetHour: %i", [hour integerValue], sunriseHour, sunsetHour);
                // Night Period
                if (([hour integerValue] >= sunsetHour) || ([hour integerValue] <= sunriseHour )) {
                    day.nightconsumption = [day.nightconsumption decimalNumberByAdding:consumption];
                }
                // Day Period
                else {
                    day.dayconsumption = [day.dayconsumption decimalNumberByAdding:consumption];
                } 
            }
            // New Day
            else {
                NSLog(@"CREATING NEW DAY");
                AggregatedDay *newDay = [AggregatedDay createEntity];
                newDay.date = date;
                NSLog(@"newDay.date: %@", newDay.date);
                if (sunriseHour<10) {
                    newDay.sunrise = [NSString stringWithFormat:@"0%i:00",sunriseHour];
                    NSLog(@"newDay.sunrise: %@", newDay.sunrise);
                }
                else {
                    newDay.sunrise = [NSString stringWithFormat:@"%i:00",sunriseHour];
                    NSLog(@"newDay.sunrise: %@", newDay.sunrise);
                }
                if (sunsetHour<10) {
                    newDay.sunset = [NSString stringWithFormat:@"0%i:00",sunsetHour];
                    NSLog(@"newDay.sunset: %@", newDay.sunset);
                }
                else {
                    newDay.sunset = [NSString stringWithFormat:@"%i:00",sunsetHour];
                    NSLog(@"newDay.sunset: %@", newDay.sunset);
                }
                NSLog(@"current hour: %@, sunriseHour: %i, sunsetHour: %i", hour, sunriseHour, sunsetHour);
                // Night Period
                if (([hour integerValue] >= sunsetHour) || ([hour integerValue] <= sunriseHour) ) {
                    newDay.nightconsumption = [newDay.nightconsumption decimalNumberByAdding:consumption];
                    NSLog(@"newDay.nightconsumption: %@", newDay.nightconsumption);
                }
                // Day Period
                else {
                    newDay.dayconsumption = [newDay.dayconsumption decimalNumberByAdding:consumption];
                    NSLog(@"newDay.dayconsumption: %@", newDay.dayconsumption);
                }
            }
            
        }
        // LOGGING
        System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
        systemObj.daysupdated = [NSDate date];
        
        //[[NSManagedObjectContext defaultContext] saveNestedContexts];
        [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
            NSArray *days = [AggregatedDay findAllSortedBy:@"date" ascending:YES];
            NSLog(@"number of days: %i", [days count]);
            for (AggregatedDay *day in days) {
                NSLog(@"date: %@, dayconsumption: %@, nightconsumption: %@", day.date, day.dayconsumption, day.nightconsumption);
            }
            //notify observers (instances of ScrollViewContentVC)
            [[NSNotificationCenter defaultCenter] postNotificationName:AggregatedDaysSaved object:nil userInfo:nil];
        }];
    }
}

// get sunset/sunrise time from wunderground.com Weather API
- (void)syncSunriseSunsetDataWithResult:(NSString *)result forMode:(NSString *)mode
{
    __block NSDictionary *sunriseSunset; //result
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:wundergroundRequestURL]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^
                                         (NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        NSDictionary *jsonDict = (NSDictionary *) JSON;
        
        __block NSDictionary *sunsetData = [[NSDictionary alloc] init];
        __block NSDictionary *sunriseData = [[NSDictionary alloc] init];
        
        [jsonDict enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent // first loop
                                          usingBlock:^(id key, id object, BOOL *stop)
        {
                                              if ([(NSString *)key isEqualToString:@"moon_phase"])
                                              {
                                                  [[jsonDict objectForKey:key]
                                                   enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent // second loop
                                                   usingBlock:^(id key, id object, BOOL *stop)
                                                  {
                                                       if ([(NSString *)key isEqualToString:@"sunset"])
                                                       { // bingo
                                                           sunsetData = object;
                                                       }
                                                       if ([(NSString *)key isEqualToString:@"sunrise"])
                                                       { // bingo
                                                           sunriseData = object;
                                                       }
                                                       
                                                   }];
                                              }
        }];
        // construct result dictionary
        sunriseSunset = [[NSMutableDictionary alloc] initWithObjectsAndKeys:sunsetData, @"sunset", sunriseData, @"sunrise", nil];
        [self proccessWithOperationResult:result forMode:DayChartsMode sunriseSunsetData:(NSDictionary*)sunriseSunset];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"wunderground.com Weather API: Request Failure Because %@",[error userInfo]);
    }];
    
    [operation start];

}

@end
