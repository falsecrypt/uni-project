//
//  EnergyClockSlice.h
//  uni-project
//
//  Created by Pavel Ermolin on 09.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface EnergyClockSlice : NSManagedObject

@property (nonatomic, retain) NSNumber * hour;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDecimalNumber * consumption;
@property (nonatomic, retain) NSData * slotValues;

@end
