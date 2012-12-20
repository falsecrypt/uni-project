//
//  WeekData.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface WeekData : NSManagedObject

@property (nonatomic, retain) NSDate * day;
@property (nonatomic, retain) NSDecimalNumber * consumption;
@property (nonatomic, retain) User *user;

@end
