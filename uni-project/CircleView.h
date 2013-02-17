//
//  CircleView.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol circleViewDelegate<NSObject>
- (void)setLabelsWithMonth:(NSString *)month andConsumption:(NSString *)kwh;
@end

@interface CircleView : UIView

@property (strong, nonatomic) NSArray *monthDataObjects;
@property (strong, nonatomic) NSMutableDictionary *monthColors;
@property (strong, nonatomic) NSMutableDictionary *circleObjectsDictionary;
@property (nonatomic,weak) id <circleViewDelegate> delegate;
@property (strong, nonatomic) NSArray *circleObjectsColors;

@end
