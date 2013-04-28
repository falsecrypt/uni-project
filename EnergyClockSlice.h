//
//  EnergyClockSlice.h
//  uni-project
//
//  Created by Pavel Ermolin on 28.04.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EnergyClockSlice : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * consumption;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSNumber * hour;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSData * slotValues;
@property (nonatomic, retain) NSNumber * temperature;

@end
