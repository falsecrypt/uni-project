//
//  CurrentDataViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CurrentDataViewController : UIViewController {

    UIImageView *needleImageView;
    float speedometerCurrentValue;
    float prevAngleFactor;
    float angle;
    NSTimer *speedometer_Timer;
    //UILabel *speedometerReading;
    NSString *maxVal;
    
}

@property(nonatomic,retain) UIImageView *needleImageView;
@property(nonatomic,assign) float speedometerCurrentValue;
@property(nonatomic,assign) float prevAngleFactor;
@property(nonatomic,assign) float angle;
@property(nonatomic,retain) NSTimer *speedometer_Timer;
//@property(nonatomic,retain) UILabel *speedometerReading;
@property(nonatomic,retain) NSString *maxVal;
@property (strong, nonatomic) IBOutlet UIImageView *speedometerImageView;
@property (strong, nonatomic) IBOutlet UILabel *speedometerReading;

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

-(void) addMeterViewContents;
-(void) rotateIt:(float)angl;
-(void) rotateNeedle;
-(void) setSpeedometerCurrentValue;

@end
