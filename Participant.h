//
//  Participant.h
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Participant : NSManagedObject

@property (nonatomic, retain) NSNumber * sensorid;
@property (nonatomic, retain) NSData * profileimage;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * name;

@end
