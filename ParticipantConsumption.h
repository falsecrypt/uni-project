//
//  ParticipantConsumption.h
//  uni-project
//
//  Created by Pavel Ermolin on 03.04.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Participant;

@interface ParticipantConsumption : NSManagedObject

@property (nonatomic, retain) NSNumber * sensorid;
@property (nonatomic, retain) NSNumber * hour;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSDecimalNumber * consumption;
@property (nonatomic, retain) Participant *participant;

@end
