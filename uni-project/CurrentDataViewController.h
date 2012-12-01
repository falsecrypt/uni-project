//
//  CurrentDataViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentDataViewController : UIViewController


@property (strong, nonatomic) UIImageView *needleImageView;
@property (nonatomic,assign) int speedometerCurrentValue;
@property (nonatomic,assign) float prevAngleFactor;
@property (nonatomic,assign) float angle;
//@property (strong, nonatomic) NSTimer *speedometer_Timer;
//@property(nonatomic,retain) UILabel *speedometerReading;
@property (assign, nonatomic) int maxVal;
@property (strong, nonatomic) IBOutlet UIImageView *speedometerImageView;
//@property (strong, nonatomic) IBOutlet UILabel *speedometerReading;
@property (assign, nonatomic) int userMaximumWatt;
@property (assign, nonatomic) int userCurrentWatt;


@property (strong, nonatomic) IBOutlet UILabel *spReadingFirstNumber;
@property (strong, nonatomic) IBOutlet UILabel *spReadingSecondNumber;
@property (strong, nonatomic) IBOutlet UILabel *spReadingThirdNumber;
@property (strong, nonatomic) IBOutlet UILabel *spReadingFourthNumber;



// for (UILabel *spLabel in labelsWithNumbersCollection) { ...
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labelsWithNumbersCollection;

-(void) addMeterViewContents;
-(void) rotateIt:(float)angl;
-(void) rotateNeedle;
-(void) setSpeedometerCurrentValue;

@end
