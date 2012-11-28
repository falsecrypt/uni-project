//
//  CurrentDataViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentDataViewController : UIViewController


@property (strong, nonatomic) UIImageView *needleImageView;
@property (nonatomic,assign) float speedometerCurrentValue;
@property (nonatomic,assign) float prevAngleFactor;
@property (nonatomic,assign) float angle;
@property (strong, nonatomic) NSTimer *speedometer_Timer;
//@property(nonatomic,retain) UILabel *speedometerReading;
@property (strong, nonatomic) NSString *maxVal;
@property (strong, nonatomic) IBOutlet UIImageView *speedometerImageView;
@property (strong, nonatomic) IBOutlet UILabel *speedometerReading;
@property (assign, nonatomic) int userMaximumWatt;
@property (assign, nonatomic) int userCurrentWatt;

/*
@property (strong, nonatomic) IBOutlet UILabel *spNumberOne;
@property (strong, nonatomic) IBOutlet UILabel *spNumberTwo;
@property (strong, nonatomic) IBOutlet UILabel *spNumberThree;
@property (strong, nonatomic) IBOutlet UILabel *spNumberFour;
@property (strong, nonatomic) IBOutlet UILabel *spNumberFive;
@property (strong, nonatomic) IBOutlet UILabel *spNumberSix;
@property (strong, nonatomic) IBOutlet UILabel *spNumberSeven;
@property (strong, nonatomic) IBOutlet UILabel *spNumberEight;
@property (strong, nonatomic) IBOutlet UILabel *spNumberNine;
@property (strong, nonatomic) IBOutlet UILabel *spNumberTen;
@property (strong, nonatomic) IBOutlet UILabel *spNumberEleven;
@property (strong, nonatomic) IBOutlet UILabel *spNumberTwelve;
 */


// for (UILabel *spLabel in labelsWithNumbersCollection) { ...
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labelsWithNumbersCollection;

-(void) addMeterViewContents;
-(void) rotateIt:(float)angl;
-(void) rotateNeedle;
-(void) setSpeedometerCurrentValue;

@end
