//
//  System.h
//  uni-project
//
//  Created by Pavel Ermolin on 11.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface System : NSManagedObject

@property (nonatomic, retain) NSDate * daysupdated;
@property (nonatomic, retain) NSNumber * lastweeklog;
@property (nonatomic, retain) NSNumber * currentdatalog;
@property (nonatomic, retain) NSNumber * lastmonthslog;
@property (nonatomic, retain) NSNumber * energyclocklog;
@property (nonatomic, retain) NSNumber * energylabellog;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * appstartlog;
@property (nonatomic, retain) NSDate * energyclockupdated;

@end
