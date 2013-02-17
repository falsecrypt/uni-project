//
//  User.h
//  uni-project
//
//  Created by Erna on 27.01.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MonthData, WeekData;

@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * profileimage;
@property (nonatomic, retain) NSNumber * sensorid;
@property (nonatomic, retain) NSSet *monthData;
@property (nonatomic, retain) NSSet *weekData;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addMonthDataObject:(MonthData *)value;
- (void)removeMonthDataObject:(MonthData *)value;
- (void)addMonthData:(NSSet *)values;
- (void)removeMonthData:(NSSet *)values;

- (void)addWeekDataObject:(WeekData *)value;
- (void)removeWeekDataObject:(WeekData *)value;
- (void)addWeekData:(NSSet *)values;
- (void)removeWeekData:(NSSet *)values;

@end
