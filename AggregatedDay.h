//
//  AggregatedDay.h
//  uni-project
//
//  Created by Pavel Ermolin on 09.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AggregatedDay : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDecimalNumber * dayconsumption;
@property (nonatomic, retain) NSDecimalNumber * nightconsumtion;

@end
