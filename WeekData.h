//
//  WeekData.h
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface WeekData : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * consumption;
@property (nonatomic, retain) NSDate * day;
@property (nonatomic, retain) User *user;

@end
