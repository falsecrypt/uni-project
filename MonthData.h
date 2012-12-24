//
//  MonthData.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface MonthData : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * consumption;
@property (nonatomic, retain) NSNumber * month;
@property (nonatomic, retain) NSNumber * year;
@property (nonatomic, retain) NSNumber * circleradius;
@property (nonatomic, retain) User *user;

@end
