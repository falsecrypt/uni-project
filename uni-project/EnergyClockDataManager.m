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
#import "EnergyClockSlice.h"
#import "AFJSONRequestOperation.h"
#import "WeatherApiCommManager.h"

@interface EnergyClockDataManager ()

@property (nonatomic, strong) NSArray *participants;
@property (nonatomic, assign) BOOL deviceIsOnline;
@property (nonatomic, strong) NSArray *cachedSlices;

@end

@implementation EnergyClockDataManager

static const NSArray *serverHours;
static int methodCounter;
static NSDictionary *sunriseSunset;

+ (EnergyClockDataManager *)sharedClient {
    static EnergyClockDataManager *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[EnergyClockDataManager alloc] init];
    });
    return _sharedClient;
}

- (id)init {
    
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

- (void)reachabilityChange {
    
}

- (void)calculateValuesWithMode:(NSString *)mode {
    EcoMeterAppDelegate *appDelegate = (EcoMeterAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.deviceIsOnline = appDelegate.deviceIsOnline;
    DLog(@"<calculateValuesWithMode> self.deviceIsOnline: %i", self.deviceIsOnline);
    
    if (self.deviceIsOnline)
    {
        if ([mode isEqualToString:DayChartsMode])
        {
            NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
            NSDateComponents *todayComponents =
            [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
            System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
            NSAssert(systemObj!=nil, @"System Object with id=primary doesnt exist");
            NSDate *lastSyncDate = systemObj.daysupdated;
            DLog(@"<calculateValuesWithMode> lastSyncDate: %@, todayComponents: %@", lastSyncDate, todayComponents);
            if ([lastSyncDate isKindOfClass:[NSDate class]]) { // we have synced already
                NSDateComponents *lastSyncComponents =
                [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:lastSyncDate];
                
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
        //        else if ([mode isEqualToString:MultiLevelPieChartMode])
        //        {
        //            [self getDataFromServerWithMode:MultiLevelPieChartMode];
        //        }
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

- (void)getDataFromServerWithMode:(NSString *)mode {
    DLog(@"getDataFromServerWithMode...");
    
    if ( [mode isEqualToString:DayChartsMode] ){
        
        [self resetDatabase];
        // sync sunrise and sunset values first, then get new values and store new objects
        [self syncSunriseSunsetData];
    }
}

- (void)processAfterGettingSunriseSunset {
    
    for (NSNumber *userId in self.participants)
    {
        [self getKwPerHourForLastWeekWithUserId:userId];
    }
}

- (void)resetDatabase {
    // Delete all existing objects/entities before updating
    [AggregatedDay truncateAll];
    [EnergyClockSlice truncateAll];
    DLog(@"calling resetDatabase... end");
}

- (void)getKwPerHourForLastWeekWithUserId:(NSNumber *)userId {
    DLog(@"getKwPerHourForLastWeekWithUserId..., userId: %@", userId);
    NSString *getPath = @"rpc.php?userID=";
    getPath = [getPath stringByAppendingString:[NSString stringWithFormat:@"%i",[userId intValue]]];
    getPath = [getPath stringByAppendingString:@"&action=get&what=aggregation_h"];
    [[EMNetworkManager sharedClient] getPath:getPath
                                  parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id data) {
                                         NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                         DLog(@"calling syncSunriseSunsetDataWithResult... start ");
                                         // sync sunrise and sunset values first, then get new values and store new objects
                                         [self proccessWithOperationResult:result forUserId:(NSNumber *)userId sunriseSunsetData:sunriseSunset];
                                     }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         DLog(@"HCM Server: Request Failure Because %@",[error userInfo]);
                                     }];
}

- (void)proccessWithOperationResult:(NSString *)result forUserId:(NSNumber *)userId sunriseSunsetData:(NSDictionary *)sunriseSunset {
    DLog(@"proccessWithOperationResult...");
    // calculate the actual sunset/sunrise time we want to display
    //DLog(@"sunriseSunset: %@", sunriseSunset);
    //DLog(@"serverHours: %@", serverHours);
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
    DLog(@"resultComponents: %@", resultComponents);
    NSString *lastDateString = @""; // we will make sure, that we store only 7 AggregatedDay-Objects
    NSUInteger objectsCounter = 0;
    for (NSString *obj in resultComponents){
        NSArray *data = [obj componentsSeparatedByString:@"="];
        DLog(@"data: %@", data);
        NSString *dateString = [data[0] substringWithRange:(NSMakeRange(0, 8))];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
        [dateFormatter setDateFormat:@"yy-MM-dd"];
        //IMPORTANT! Actual NSDate-Object generated with this NSDateFormatter depends on the Timezone
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]];
        NSString *today = [dateFormatter stringFromDate:[NSDate date]];
        DLog(@"today: %@", today);
        DLog(@"dateString: %@", dateString);
        // We dont want to show today's data, since we dont have all the data
        // only past 7 days
        if (![today isEqualToString:dateString]) {
            if (![lastDateString isEqualToString:dateString]){
                objectsCounter++;
                lastDateString = [dateString copy];
            }
            
            if (objectsCounter <= 7){
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                [dateFormatter setDateFormat:@"yy-MM-dd"];
                //IMPORTANT! Actual NSDate-Object generated with this NSDateFormatter depends on the Timezone
                [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                NSDate *date = [dateFormatter dateFromString:dateString];
                NSString *hour = [data[0] substringWithRange:(NSMakeRange(9, 2))];
                NSString *withoutComma = [data[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                double temp = [withoutComma doubleValue];
                NSDecimalNumber *consumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                //                DLog(@"Data for ParticipantConsumption-Entities");
                //                DLog(@"date: %@", date);
                //                DLog(@"hour: %@", hour);
                //                DLog(@"consumption: %@", consumption);
                //                DLog(@"userID: %@", userId);
                
                // 'date'-'hour' combination is unique
                //NSPredicate *energyClockFilter = [NSPredicate predicateWithFormat:@"date == %@ && hour == %@", date, @([hour integerValue])];
                //EnergyClockSlice *slice = [EnergyClockSlice findFirstWithPredicate:energyClockFilter];
                // Performance opt.:
                NSString *identifier = [[dateFormatter stringFromDate:date] stringByAppendingString:hour];
                EnergyClockSlice *slice = [EnergyClockSlice findFirstByAttribute:@"identifier" withValue:identifier];
                if (slice) { // slice already exists -> update
                    DLog(@"UPDATING SLICE");
                    DLog(@"updating slice... slice: %@", slice);
                    NSMutableDictionary *slotValuesDict = [NSKeyedUnarchiver unarchiveObjectWithData:slice.slotValues];
                    [slotValuesDict setValue:consumption forKey: [NSString stringWithFormat:@"%@",userId]];
                    DLog(@"updating slice... slotValuesDict: %@", slotValuesDict);
                    NSData *slotValues = [NSKeyedArchiver archivedDataWithRootObject:slotValuesDict];
                    slice.slotValues = slotValues;
                    slice.consumption = [slice.consumption decimalNumberByAdding:consumption];
                    DLog(@"updating slice... consumption is now: %@", slice.consumption);
                }
                // New Slice
                else {
                    EnergyClockSlice *slice = [EnergyClockSlice createEntity];
                    slice.date = date;
                    slice.hour = [NSNumber numberWithInt:[hour intValue]];
                    slice.consumption = consumption;
                    NSMutableDictionary *slotValuesDict = [[NSMutableDictionary alloc] init];
                    [slotValuesDict setValue:consumption forKey: [NSString stringWithFormat:@"%@",userId]];
                    NSData *slotValues = [NSKeyedArchiver archivedDataWithRootObject:slotValuesDict];
                    slice.slotValues = slotValues;
                    slice.identifier = [[dateFormatter stringFromDate:date] stringByAppendingString:hour];
                    DLog(@"CREATING NEW SLICE: %@", slice);
                    DLog(@"creating slice... slice.date: %@", slice.date);
                    DLog(@"creating slice... slice.hour: %@", slice.hour);
                    DLog(@"creating slice... slice.consumption: %@", slice.consumption);
                    DLog(@"creating slice... slotValuesDict: %@", slotValuesDict);
                    DLog(@"creating slice... identifier: %@", slice.identifier);
                }
                
                // 'date' is a unique field
                AggregatedDay *day = [AggregatedDay findFirstByAttribute:@"date" withValue:date];
                if (day) { // day already exists -> update
                    DLog(@"UPDATING DAY");
                    DLog(@"updating day... date: %@", day.date);
                    DLog(@"updating day... nightconsumption: %@", day.nightconsumption);
                    DLog(@"updating day... dayconsumption: %@", day.dayconsumption);
                    DLog(@"updating day... current hour: %i, sunriseHour: %i, sunsetHour: %i", [hour integerValue], sunriseHour, sunsetHour);
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
                    DLog(@"CREATING NEW DAY");
                    AggregatedDay *newDay = [AggregatedDay createEntity];
                    newDay.date = date;
                    DLog(@"newDay.date: %@", newDay.date);
                    if (sunriseHour<10) {
                        newDay.sunrise = [NSString stringWithFormat:@"0%i:00",sunriseHour];
                        DLog(@"newDay.sunrise: %@", newDay.sunrise);
                    }
                    else {
                        newDay.sunrise = [NSString stringWithFormat:@"%i:00",sunriseHour];
                        DLog(@"newDay.sunrise: %@", newDay.sunrise);
                    }
                    if (sunsetHour<10) {
                        newDay.sunset = [NSString stringWithFormat:@"0%i:00",sunsetHour];
                        DLog(@"newDay.sunset: %@", newDay.sunset);
                    }
                    else {
                        newDay.sunset = [NSString stringWithFormat:@"%i:00",sunsetHour];
                        DLog(@"newDay.sunset: %@", newDay.sunset);
                    }
                    DLog(@"current hour: %@, sunriseHour: %i, sunsetHour: %i", hour, sunriseHour, sunsetHour);
                    // Night Period
                    if (([hour integerValue] >= sunsetHour) || ([hour integerValue] <= sunriseHour) ) {
                        newDay.nightconsumption = [newDay.nightconsumption decimalNumberByAdding:consumption];
                        DLog(@"newDay.nightconsumption: %@", newDay.nightconsumption);
                    }
                    // Day Period
                    else {
                        newDay.dayconsumption = [newDay.dayconsumption decimalNumberByAdding:consumption];
                        DLog(@"newDay.dayconsumption: %@", newDay.dayconsumption);
                    }
                    
                }
            }
        }
        
    }
    // LOGGING
    System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
    systemObj.daysupdated = [NSDate date];
    for (AggregatedDay *day in [AggregatedDay findAll]) {
        day.totalconsumption = [day.nightconsumption decimalNumberByAdding:day.dayconsumption];
    }
    methodCounter = 0;
    //[[NSManagedObjectContext defaultContext] saveNestedContexts];
    [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
        
        DLog(@"saving defaultContext");
        methodCounter++;
        DLog(@"methodCounter: %i", methodCounter);
        if (methodCounter == numberOfParticipants) {
            [self retrieveOutsideTemperatureValues];
        }
        
        // DEBUGGING
        DLog(@"System numberOfEntities: %@", [System numberOfEntities]);
        NSArray *allsystems = [System findAll];
        
        for (System *sys in allsystems) {
            DLog(@"System object daysupdated: %@", sys.daysupdated);
        }
        //            NSArray *days = [AggregatedDay findAllSortedBy:@"date" ascending:YES];
        //            NSArray *slices = [EnergyClockSlice findAllSortedBy:@"date" ascending:YES];
        //            NSArray *pconObjects = [ParticipantConsumption findAllSortedBy:@"date" ascending:YES];
        //            DLog(@"number of days: %i", [days count]);
        //            for (AggregatedDay *day in days) {
        //                DLog(@"date: %@, dayconsumption: %@, nightconsumption: %@", day.date, day.dayconsumption, day.nightconsumption);
        //
        //            }
        //            DLog(@"number of slices: %i", [slices count]);
        //            for (EnergyClockSlice *slice in slices) {
        //                NSMutableDictionary *slotValuesDict = [NSKeyedUnarchiver unarchiveObjectWithData:slice.slotValues];
        //                DLog(@"date: %@, consumption: %@, hour: %@, slotValues: %@", slice.date, slice.consumption, slice.hour, slotValuesDict);
        //
        //            }
        //            DLog(@"number of pcons: %i", [pconObjects count]);
        //            for (ParticipantConsumption *pcon in pconObjects) {
        //                DLog(@"date: %@, consumption: %@, hour: %@, sensorid: %@", pcon.date, pcon.consumption, pcon.hour, pcon.sensorid);
        //
        //            }
        
        
    }];
}

// get sunset/sunrise time from wunderground.com Weather API
- (void)syncSunriseSunsetData {
    DLog(@"syncSunriseSunsetDataWithResult, self.sunriseSunset  %@ \n self: %@",sunriseSunset, self );
    // Construct request URL
    NSString *requestAstronomyUrl = [WWABaseURL stringByAppendingString:WWAKey];
    requestAstronomyUrl = [[requestAstronomyUrl stringByAppendingString:WWAAstronomyURLpart] stringByAppendingString:WWALocationURLpart];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestAstronomyUrl]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^
                                         (NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
                                             NSArray *jsonArray = (NSArray *) JSON;
                                             // Key-Value Coding
                                             NSDictionary *jsonArrayFilteredSunrise = [jsonArray valueForKeyPath:@"moon_phase.sunrise"];
                                             NSDictionary *jsonArrayFilteredSunset = [jsonArray valueForKeyPath:@"moon_phase.sunset"];
                                             DLog(@"\n jsonArrayFilteredSunrise: %@ \n jsonArrayFilteredSunset: %@ \n", jsonArrayFilteredSunrise, jsonArrayFilteredSunset);
                                             
                                             // construct result dictionary
                                             sunriseSunset = [[NSMutableDictionary alloc] initWithObjectsAndKeys:jsonArrayFilteredSunset, @"sunset",
                                                              jsonArrayFilteredSunrise, @"sunrise", nil];
                                             DLog(@"\n sunriseSunset %@ \n",sunriseSunset);
                                             [self processAfterGettingSunriseSunset];
                                             
                                         }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                            DLog(@"wunderground.com Weather API: Request Failure Because %@",[error userInfo]);
                                                                                        }];
    
    [operation start];
    
}

// Help Method
- (NSDictionary *)getURLParameters:(NSURL *)url {
    
    NSString * q = [url query];
    NSArray * pairs = [q componentsSeparatedByString:@"&"];
    NSMutableDictionary * kvPairs = [NSMutableDictionary dictionary];
    for (NSString * pair in pairs) {
        NSArray * bits = [pair componentsSeparatedByString:@"="];
        NSString * key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [kvPairs setObject:value forKey:key];
    }
    return kvPairs;
}


- (void)retrieveUserTemperatureValues {
    // Get Temp-Values for all Participants  /////////
    // Construct temperature-requests-array /////////
    NSMutableArray *requestsStorage = [[NSMutableArray alloc] init];
    
    for (NSNumber *sensorId in self.participants) {
        
        NSString *requestTemperatureUrl = currentCostServerBaseURLString;
        requestTemperatureUrl = [requestTemperatureUrl stringByAppendingString:@"rpc.php?userID="];
        requestTemperatureUrl = [requestTemperatureUrl stringByAppendingString:[sensorId stringValue]];
        requestTemperatureUrl = [requestTemperatureUrl stringByAppendingString:@"&action=get&what=tempRep"];
        NSURLRequest *temperatureRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestTemperatureUrl]];
        [requestsStorage addObject:temperatureRequest];
        
    }
    ///////////////////////////////////////////////
    DLog(@"requestsStorage UserTemps: %@", requestsStorage);
    
    [[EMNetworkManager sharedClient]
     enqueueBatchOfHTTPRequestOperationsWithRequests:requestsStorage
     progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
         
         
     } completionBlock:^(NSArray *operations) {
         DLog(@"\nTempUsers operations: %@", operations);
         for (AFHTTPRequestOperation *ro in operations) {
             
             if (ro.error) {
                 DLog(@"++++++++++++++ Operation error");
             } else {
                 
                 if (ro.responseData != nil && ro.responseData.length > 0) {
                     NSDictionary *urlParameters = [self getURLParameters:ro.request.URL];
                     // Get userID from Request Parameters
                     NSString *userID = [urlParameters objectForKey:@"userID"];
                     NSString *tempData = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSArray *components    = [tempData componentsSeparatedByString:@";"];
                     DLog(@"\nTempUsers userID: %@", userID);
                     DLog(@"\nTempUsers components: %@", components);
                     //DLog(@"\nTempUsers ro.responseData: %@", ro.responseData);
                     // In Components are all Temp-Values with Data and Hour for the User with userID
                     for (NSString *obj in components) {
                         if ([obj length] > 0) {
                             DLog(@"\nTempUsers, obj: %@", obj);
                             NSArray *data = [obj componentsSeparatedByString:@"="];
                             DLog(@"data: %@", data);
                             NSString *dateString = [data[0] substringWithRange:(NSMakeRange(0, 10))];
                             NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                             [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                             [dateFormatter setDateFormat:@"yy-MM-dd"];
                             //IMPORTANT! Actual NSDate-Object generated with this NSDateFormatter depends on the Timezone
                             [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
                             NSDate *date = [dateFormatter dateFromString:dateString];
                             NSString *hour = [data[0] substringWithRange:(NSMakeRange(11, [data[0] length]-11))];
                             DLog(@"calc. date: %@ and hour: %@", date, hour);
                             //DLog(@"yeah! self.cachedSlices: %@", self.cachedSlices);
                             NSArray *filteredSlice = [self.cachedSlices filteredArrayUsingPredicate:
                                                       [NSPredicate predicateWithFormat:@"hour == %@ AND date == %@", @([hour integerValue]), date]];
                             //EnergyClockSlice *foundSliceFromDB = [EnergyClockSlice findFirstWithPredicate:
                             //[NSPredicate predicateWithFormat:@"hour == %@ AND date == %@", @([hour integerValue]), date]];
                             DLog(@"yeah! found slice: %@", filteredSlice);
                             //DLog(@"yeah! found foundSliceFromDB: %@", foundSliceFromDB);
                             // We have found the slice with this date and hour
                             // Save the new UserTemp-Values-Dict!
                             if ([filteredSlice count] > 0) {
                                 EnergyClockSlice *slice = filteredSlice[0];
                                 NSMutableDictionary *temperatureUsers = [[NSMutableDictionary alloc] init];
                                 if (slice.temperatureUsers != nil) {
                                     temperatureUsers = [NSKeyedUnarchiver unarchiveObjectWithData:slice.temperatureUsers];
                                 }
                                 [temperatureUsers setObject:@([data[1] floatValue]) forKey:userID];
                                 NSData *temperatureUsersData = [NSKeyedArchiver archivedDataWithRootObject:temperatureUsers];
                                 slice.temperatureUsers = temperatureUsersData; // aaand Save It!
                             }
                             
                         }//end if length
                         
                     }//end for components
                     
                 }//end if responsedata check
                 
             }//end else no error
             
             
         }//end for completionBlock - operations
         
         // Save new user-temperature values
         [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
             
                        NSArray *newslices = [EnergyClockSlice findAll];
             DLog(@"saving: slicesData: %i Objs found", [newslices count]);
                         for (EnergyClockSlice *slice in newslices) {
                              DLog(@"\n saved temperatureUsers: %@", [NSKeyedUnarchiver unarchiveObjectWithData:slice.temperatureUsers]);
                          }
             
             //notify observers (instances of ScrollViewContentVC)
             [[NSNotificationCenter defaultCenter] postNotificationName:EnergyClockDataSaved object:nil userInfo:nil];
         }];
         
         
     }];
    
    
    
    
}

- (void)retrieveOutsideTemperatureValues {
    __block NSMutableArray *historyResultObjects = [[NSMutableArray alloc] init];
    AggregatedDay *lastDay = [AggregatedDay findFirstOrderedByAttribute:@"date" ascending:NO];
    DLog(@"lastDay found: %@", lastDay);
    NSDate *lastDate = lastDay.date;
    DLog(@"lastDay-date found: %@", lastDate);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
    [dateFormatter setDateFormat:@"yyyyMMdd/"];
    //IMPORTANT! Actual NSDate-Object generated with this NSDateFormatter depends on the Timezone
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSString *requestTemperatureUrl = [WWABaseURL stringByAppendingString:WWAKey];
    requestTemperatureUrl = [ [ [requestTemperatureUrl stringByAppendingString:WWAHistoryURLpart]
                               stringByAppendingString:[dateFormatter stringFromDate:lastDate] ]
                             stringByAppendingString:WWALocationURLpart];
    NSURLRequest *temperatureRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestTemperatureUrl]];
    // Construct temperature-requests-array /////////
    NSMutableArray *requestsStorage = [[NSMutableArray alloc] init];
    requestsStorage[0] = temperatureRequest;
    NSDateComponents *components = [[NSDateComponents alloc] init];
    for (int i=1; i<=6; i++) {
        [components setDay:-1];
        lastDate = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:lastDate options:0];
        requestTemperatureUrl = [WWABaseURL stringByAppendingString:WWAKey];
        requestTemperatureUrl = [ [ [requestTemperatureUrl stringByAppendingString:WWAHistoryURLpart]
                                   stringByAppendingString:[dateFormatter stringFromDate:lastDate] ]
                                 stringByAppendingString:WWALocationURLpart];
        NSURLRequest *temperatureRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestTemperatureUrl]];
        [requestsStorage addObject:temperatureRequest];
        
    }
    ///////////////////////////////////////////////
    DLog(@"requestsStorage : %@", requestsStorage);
    
    [[WeatherApiCommManager sharedClient] enqueueBatchOfHTTPRequestOperationsWithRequests:requestsStorage
                                                                            progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
                                                                                
                                                                                
                                                                            }
                                                                          completionBlock:^(NSArray *operations) {
                                                                              //DLog(@"completion block! operations:%@",operations);
                                                                              for (id op in operations) {
                                                                                  AFJSONRequestOperation *myOperation = (AFJSONRequestOperation *)op;
                                                                                  NSArray *response = [myOperation responseJSON];
                                                                                  [historyResultObjects addObject:response];
                                                                                  //DLog(@"\n completion block! response:%@",response);
                                                                                  
                                                                              }
                                                                              
                                                                              [self storeOutsideTemperatureValues:historyResultObjects];
                                                                              
                                                                          }];
    
}


- (void)storeOutsideTemperatureValues:(NSArray *)historyResultObjects {
    DLog(@"\n storeTemperatureValues calling");
    self.cachedSlices = [EnergyClockSlice findAll];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yy-MM-dd";
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    //DLog(@"slice date Form: %@", date);
    // there must be 7 objects
    for (NSArray *response in historyResultObjects) {
        NSArray *historyArray = [response valueForKeyPath:@"history.observations"];
        NSString *year = [response valueForKeyPath:@"history.date.year"];
        NSString *month = [response valueForKeyPath:@"history.date.mon"];
        NSString *day = [response valueForKeyPath:@"history.date.mday"];
        NSString *fullDate = [[[[year stringByAppendingString:@"-"] stringByAppendingString:month] stringByAppendingString:@"-"] stringByAppendingString:day];
        NSDate *dateFromString = [dateFormatter dateFromString:fullDate];
        // EnergyClockSlice *sliceObj = [EnergyClockSlice findFirstByAttribute:@"date" withValue:dateFromString];
        // These Objects have the same date, but different time
        NSArray *foundItems = [self.cachedSlices filteredArrayUsingPredicate:
                               [NSPredicate predicateWithFormat:@"date == %@", dateFromString]];
        NSAssert([foundItems count] > 0, @"fountItems empty");
        /* *********** Outer For-Loop *********** */
        for (EnergyClockSlice *daySlice in foundItems) {
            NSInteger sliceHour = [daySlice.hour integerValue];
            // average temperature in the given interval, e.g. 00:00-02:00
            
            // 1) find all objects with date.hour == sliceHour-1 OR date.hour == sliceHour-2
            //    calc. avg value then
            NSMutableArray *tempValuesForSlice = [[NSMutableArray alloc] init];
            DLog(@"\n calc. for : %@ and %@, for date: %@\n", @(sliceHour-1), @(sliceHour-2), dateFromString);
            /* *********** Inner For-Loop *********** */
            for (id obj in historyArray) {
                if (sliceHour >= 2) {
                    if ( [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == sliceHour-1 ||  [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == sliceHour-2 ) {
                        [tempValuesForSlice addObject: [obj valueForKey:@"tempm"] ];
                    }
                }
                // Sometimes there are no values for 23 and 22 hours (so the tempValuesForSlice is empty) -> add temperature for 21 and 20
                else if (sliceHour == 0) {
                    if ( [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == 23 ||  [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == 22 ||
                        [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == 21 ||  [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == 20) {
                        [tempValuesForSlice addObject: [obj valueForKey:@"tempm"] ];
                    }
                }
                else if (sliceHour == 1) {
                    if ( [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == 0 ||  [[[obj valueForKey:@"date"] valueForKey:@"hour"] integerValue] == 23 ) {
                        [tempValuesForSlice addObject: [obj valueForKey:@"tempm"] ];
                    }
                }
            }
            /* *********** Inner For-Loop END *********** */
            DLog(@"\n tempValuesForSlice: %@ \n", tempValuesForSlice);
            NSAssert([tempValuesForSlice count]>0, @"tempValuesForSlice empty");
            for (int k=0; k<[tempValuesForSlice count]; k++) {
                if ([tempValuesForSlice[k] isEqualToString:@""]) {
                    tempValuesForSlice[k] = @(0);
                }
            }
            NSNumber *avgTemperatureForSlice = [tempValuesForSlice valueForKeyPath:@"@avg.self"];
            daySlice.temperature = avgTemperatureForSlice;
            DLog(@"\n calculated avgTemperatureForSlice: %@", avgTemperatureForSlice);
            
        }
        /* *********** Outer For-Loop END *********** */
        //DLog(@"\n historyArray: %@", historyArray);
        DLog(@"\n historyArray count: %i", [historyArray count]);
        //        for (id obj in historyArray) {
        //
        //            DLog(@"\n obj inside historyArray: %@", obj);
        //            DLog(@"\n filter inside historyArray: %@", [obj filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"date.hour == %i",
        //                                                                                                10]]);
        //            DLog(@"\n obj value for keypath: %@", [obj valueForKeyPath:@"date"]);
        //
        //        }
        //        NSArray *filterResult = [historyArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"%K == %@",
        //                                                                            @"date.hour", @(10)]];
        //NSArray *filterResultSec = [historyArray filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"conds like 'Mist'"]];
        //DLog(@"slice filterResult: %@", filterResult);
        //DLog(@"\nslice filterResult: %@", filterResultSec);
        //DLog(@"\n slice historyArray: %@", historyArray);
        //DLog(@"\n slice test: %@", [historyArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"history.observations.date.hour > %i", 0]]);
        //        DLog(@"slice found Items: %@", foundItems);
        //        DLog(@"slice dateFromString: %@", dateFromString);
        //        DLog(@"slice fullDate: %@", fullDate);
    }
    // Save new temperature values
    [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
        
        //        NSArray *newslices = [EnergyClockSlice findAll];
        //        for (EnergyClockSlice *slice in newslices) {
        //            DLog(@"\n slice-temp: %@", slice.temperature);
        //        } 
        [self retrieveUserTemperatureValues];
        //notify observers (instances of ScrollViewContentVC)
        //[[NSNotificationCenter defaultCenter] postNotificationName:EnergyClockDataSaved object:nil userInfo:nil];
    }];
    
}

@end
