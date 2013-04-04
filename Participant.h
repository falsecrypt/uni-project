//
//  Participant.h
//  uni-project
//
//  Created by Pavel Ermolin on 03.04.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ParticipantConsumption;

@interface Participant : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * profileimage;
@property (nonatomic, retain) NSNumber * rank;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSNumber * sensorid;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) NSSet *consumption;
@end

@interface Participant (CoreDataGeneratedAccessors)

- (void)addConsumptionObject:(ParticipantConsumption *)value;
- (void)removeConsumptionObject:(ParticipantConsumption *)value;
- (void)addConsumption:(NSSet *)values;
- (void)removeConsumption:(NSSet *)values;

@end
