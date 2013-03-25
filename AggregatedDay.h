//
//  AggregatedDay.h
//  uni-project
//
//  Created by Pavel Ermolin on 22.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AggregatedDay : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDecimalNumber * dayconsumption;
@property (nonatomic, retain) NSDecimalNumber * nightconsumption;
@property (nonatomic, retain) NSString * sunrise;
@property (nonatomic, retain) NSString * sunset;
@property (nonatomic, retain) NSDecimalNumber * totalconsumption;

@end
