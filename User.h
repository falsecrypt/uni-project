//
//  User.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSData * profileImage;
@property (nonatomic, retain) NSManagedObject *weekData;
@property (nonatomic, retain) NSManagedObject *monthData;

@end
