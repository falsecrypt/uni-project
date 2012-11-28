//
//  CurrentDataViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "CurrentDataViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "AFAppDotNetAPIClient.h"

@interface CurrentDataViewController ()

@end

@implementation CurrentDataViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self addMeterViewContents];
    
    // TEST: ID = 3
    [[AFAppDotNetAPIClient sharedClient] getPath:@"rpc.php?userID=3&action=get&what=watt" parameters:nil success:^(AFHTTPRequestOperation *operation, id data) {
        NSString *userCurrentWattString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger userCurrentWatt = [userCurrentWattString intValue];
        NSLog(@"Success! user's current watt consumption: %i Watt",userCurrentWatt);

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed: %@",[error localizedDescription]);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark Public Methods

-(void) addMeterViewContents
{
	//  Needle //
    // CGRectMake : x,  y,  width,  height
	UIImageView *imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake(340, 168, 19, 147)];
	self.needleImageView = imgNeedle;
	self.needleImageView.layer.anchorPoint = CGPointMake(self.needleImageView.layer.anchorPoint.x, self.needleImageView.layer.anchorPoint.y*2);
	self.needleImageView.backgroundColor = [UIColor clearColor];
	self.needleImageView.image = [UIImage imageNamed:@"speedometerArrow.png"];
	[self.view addSubview:self.needleImageView];

    // Needle Dot //
	UIImageView *meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake(320, 213, 57, 57)];
	meterImageViewDot.image = [UIImage imageNamed:@"speedometerCenterWheel.png"];
	[self.view addSubview:meterImageViewDot];
	
	// Speedometer Reading //
	self.speedometerReading.text= @"0";
	self.speedometerReading.textColor = [UIColor colorWithRed:114/255.f green:146/255.f blue:38/255.f alpha:1.0];
	
	// Set Max Value //
	self.maxVal = @"100";
	
	/// Set Needle pointer initialy at zero //
	//[self rotateIt:-118.4];
	[self rotateIt:-120];
	// Set previous angle //
	//self.prevAngleFactor = -118.4;
	self.prevAngleFactor = -120;
	// Set Speedometer Value //
    // Not Yet =)
	[self setSpeedometerCurrentValue];
}

#pragma mark -
#pragma mark calculateDeviationAngle Method

-(void) calculateDeviationAngle
{
	
	if([self.maxVal floatValue]>0)
	{
		self.angle = ((self.speedometerCurrentValue *237.4)/[self.maxVal floatValue])-118.4;  // 237.4 - Total angle between 0 - 100 //
	}
	else
	{
		self.angle = 0;
	}
	
	if(self.angle<=-118.4)
	{
		self.angle = -118.4;
	}
	if(self.angle>=119)
	{
		self.angle = 119;
	}
	
	
	// If Calculated angle is greater than 180 deg, to avoid the needle to rotate in reverse direction first rotate the needle 1/3 of the calculated angle and then 2/3. //
	if(abs(self.angle-self.prevAngleFactor) >180)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5f];
		[self rotateIt:self.angle/3];
		[UIView commitAnimations];
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.5f];
		[self rotateIt:(self.angle*2)/3];
		[UIView commitAnimations];
		
	}
	
	self.prevAngleFactor = self.angle;
	
	
	// Rotate Needle //
	[self rotateNeedle];
	
	
}


#pragma mark -
#pragma mark rotateNeedle Method
-(void) rotateNeedle
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5f];
	[self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle)];
	[UIView commitAnimations];
	
}

#pragma mark -
#pragma mark setSpeedometerCurrentValue

-(void) setSpeedometerCurrentValue
{
	if(self.speedometer_Timer)
	{
		[self.speedometer_Timer invalidate];
		self.speedometer_Timer = nil;
	}
	self.speedometerCurrentValue =  arc4random() % 100; // Generate Random value between 0 to 100. //
	
	self.speedometer_Timer = [NSTimer  scheduledTimerWithTimeInterval:2 target:self selector:@selector(setSpeedometerCurrentValue) userInfo:nil repeats:YES];
	
	self.speedometerReading.text = [NSString stringWithFormat:@"%.2f",self.speedometerCurrentValue];
	
	// Calculate the Angle by which the needle should rotate //
	[self calculateDeviationAngle];
}
#pragma mark -
#pragma mark Speedometer needle Rotation View Methods

-(void) rotateIt:(float)angl
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.01f];
	
	[self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) *angl)];
	
	[UIView commitAnimations];
}
@end
