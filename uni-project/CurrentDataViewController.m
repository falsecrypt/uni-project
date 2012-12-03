//
//  CurrentDataViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//
//  TEST: userID = 3

#import "CurrentDataViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "AFAppDotNetAPIClient.h"
#import "DetailViewManager.h"
#import "FirstDetailViewController.h"

@interface CurrentDataViewController ()

@property NSTimer *pendingTimer;
@property NSTimer *continiousTimer;
@property MBProgressHUD *HUD;

@end

@implementation CurrentDataViewController

NSMutableArray *navigationBarItems;

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
    /*
     NSString *NotificationName = @"UserCurrentWattChanged";
     [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(userCurrentWattChanged)
     name:NotificationName
     object:nil];
     */
    
    NSString *secondNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideProfileAfterUserLoggedOff)
     name:secondNotificationName
     object:nil];
    
    self.labelsWithNumbersCollection = [self sortCollection:self.labelsWithNumbersCollection];
    
    [self addMeterViewContents];
    
    [self startSynchronization];
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"calling FirstDetailViewController - viewWillAppear start");
    [super viewWillAppear:animated];
    // NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"userLoggedIn"]) {
        [navigationBarItems removeObject:self.profileBarButtonItem];
        [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:NO];
    }
    
    
    //NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startSynchronization {
    NSLog(@"startSynchronization...");
    
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
	[self.view addSubview:self.HUD];
	//self.HUD.delegate = self;
	self.HUD.labelText = @"Loading";
    self.HUD.yOffset = -125.f;
    [self.HUD show:YES];
    
    // Start this first timer immediately, without delay, getDataFromServer is called once
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimer* firstTimer = [NSTimer timerWithTimeInterval:0.1 
                                                 target:self
                                               selector:@selector(getDataFromServer:)
                                               userInfo:nil
                                                repeats:NO];
        
        [[NSRunLoop currentRunLoop] addTimer:firstTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
    // Start this timer after 120 seconds, getDataFromServer is called every 120 seconds
    // Another possibility: performSelectorInBackground and performSelectorOnMainThread, but its slower
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // This code is running in a different thread
        // After 120 seconds have elapsed, the timer fires, sending the message to target.
        self.continiousTimer = [NSTimer timerWithTimeInterval:20.0 // 2 minutes
                                                 target:self
                                               selector:@selector(getDataFromServer:)
                                               userInfo:nil
                                                repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:self.continiousTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)getDataFromServer:(NSTimer *)timer {
    
    NSLog(@"getDataFromServer...");
    //max consumption is a value, beeing aggregated during a period of time, i.e. 14 days
    // we should store this value in our DB, using Core Data
    // TODO
    [[AFAppDotNetAPIClient sharedClient] getPath:@"rpc.php?userID=3&action=get&what=max" parameters:nil success:^(AFHTTPRequestOperation *operation, id data) {
        NSString *userMaxWattString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (self.userMaximumWatt != [userMaxWattString intValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            self.userMaximumWatt = [userMaxWattString intValue];
            self.maxVal = [userMaxWattString intValue];
            NSLog(@"setting maxVal: %i ", self.maxVal);
            [self changeSpeedometerNumbers];
            [self calculateDeviationAngle];
            
        }
        NSLog(@"Success! user's maximum watt consumption: %i Watt", self.userMaximumWatt);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed during getting maximum watt: %@",[error localizedDescription]);
    }];
    
    
    [[AFAppDotNetAPIClient sharedClient] getPath:@"rpc.php?userID=3&action=get&what=watt" parameters:nil success:^(AFHTTPRequestOperation *operation, id data) {
        NSString *userCurrentWattString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        
        
        if (self.userCurrentWatt != [userCurrentWattString intValue]) {
            self.userCurrentWatt = [userCurrentWattString intValue];
            [self.pendingTimer invalidate];
            _pendingTimer = nil;
            /*
             //value has changed -> send notification to the observers
             NSString *notificationName = @"UserCurrentWattChanged";
             [[NSNotificationCenter defaultCenter]
             postNotificationName:notificationName
             object:nil];
             */
            [self setSpeedometerCurrentValue:self.userCurrentWatt];
            
        }
        else {
            //pendingTimer = [NSTimer  scheduledTimerWithTimeInterval:5 target:self selector:@selector(rotatePendingNeedle) userInfo:nil repeats:YES];
            //[self rotatePendingNeedle];
        }
        NSLog(@"Success! user's current watt consumption: %i Watt", self.userCurrentWatt);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed during getting current watt: %@",[error localizedDescription]);
    }];
    
    
    
}

-(NSArray *)sortCollection:(NSArray *)toSort {
    NSArray *sortedArray;
    sortedArray = [toSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *tag1 = [NSNumber numberWithInt:[(UILabel*)a tag]];
        NSNumber *tag2 = [NSNumber numberWithInt:[(UILabel*)b tag]];
        return [tag1 compare:tag2];
    }];
    
    return sortedArray;
}

- (void)changeSpeedometerNumbers {
    
    int step = self.userMaximumWatt/12;
    step = ((step)/5)*5;
    NSLog(@"changeSpeedometerNumbers, step: %i", step);
    int temp = step;
    //NSLog(@"changeSpeedometerNumbers, step: %i", step);
    for (UILabel *spLabel in self.labelsWithNumbersCollection) {
        NSLog(@"changeSpeedometerNumbers, temp: %i", temp);
        spLabel.text = [NSString stringWithFormat:@"%i", temp];
        temp += step;
        
    }
    self.maxVal = temp - step;
    self.userMaximumWatt = temp - step;
}


#pragma mark -
#pragma mark Public Methods

- (void)addMeterViewContents
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
	//self.speedometerReading.text= @"0";
	//self.speedometerReading.textColor = [UIColor colorWithRed:114/255.f green:146/255.f blue:38/255.f alpha:1.0];
    self.spReadingFirstNumber.text = @"0";
    
	
	// Set Max Value //
    if(self.userMaximumWatt){
        self.maxVal = self.userMaximumWatt;
    }
    else{
        self.maxVal = 0; // get maxVal from DB, TODO
    }
	
    
	[self rotateIt:-120.5];
	self.prevAngleFactor = -120.5;
    
    //[self rotateIt:-120.5];
	//self.prevAngleFactor = 120.5;
    
    
	[self setSpeedometerCurrentValue:0];
}

#pragma mark -
#pragma mark calculateDeviationAngle Method

-(void) calculateDeviationAngle
{
	NSLog(@"calculateDeviationAngle - self.maxVal: %i", self.maxVal);
    
	if(self.maxVal>0)
	{
		self.angle = ((self.speedometerCurrentValue * 241)/self.maxVal-120.5);  // 241 - Total angle between 0 - maxVal
        NSLog(@"calculateDeviationAngle - case 1");
        NSLog(@"with self.speedometerCurrentValue: %i", self.speedometerCurrentValue);
        NSLog(@"with self.maxVal: %i", self.maxVal);
	}
	else
	{
		self.angle = -120.5;
	}
	
	if(self.angle<=-120.5)
	{
		self.angle = -120.5;
	}
	if(self.angle>=120.5)
	{
		self.angle = 120.5;
	}
	
	NSLog(@"self.angle: %f", self.angle);
    
	// If Calculated angle is greater than 180 deg, to avoid the needle to rotate in reverse direction first rotate the needle 1/3 of the calculated angle and then 2/3. //
	if(abs(self.angle-self.prevAngleFactor) >180)
	{
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:2.0f];
		[self rotateIt:self.angle/3];
		[UIView commitAnimations];
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:2.0f];
		[self rotateIt:(self.angle*2)/3];
		[UIView commitAnimations];
		
	}
	
	self.prevAngleFactor = self.angle;
	
	
	// Rotate Needle //
	[self rotateNeedle];
	
	
}

#pragma mark -
#pragma mark rotatePendingNeedle Method
-(void) rotatePendingNeedle
{
    NSLog(@"rotatePendingNeedle...");
    
    [UIView animateWithDuration: 2.0 delay: 0.0 options: UIViewAnimationOptionCurveLinear animations:^{
                        [self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle + 0.02)];
                     }
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration: 2.0 delay: 0.1 options: UIViewAnimationOptionCurveLinear animations:^{
                             [self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle)];
                         }
                                          completion:^(BOOL finished){
                                              
                                          }];

                     }];

}


#pragma mark -
#pragma mark rotateNeedle Method
-(void) rotateNeedle
{
    NSLog(@"rotateNeedle...");
    /*
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:2.5f];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle)];
	[UIView commitAnimations];
     */
    
    if(self.pendingTimer){
        [self.pendingTimer invalidate];
        self.pendingTimer = nil;
     }


    NSLog(@"rotateNeedle...");
    [UIView animateWithDuration: 2.5 delay: 1.0 options: UIViewAnimationOptionCurveLinear animations:^{
        [self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle + 0.02)];
    }
                     completion:^(BOOL finished){
                         
                         [UIView animateWithDuration: 2.0 delay: 0.1 options: UIViewAnimationOptionCurveLinear animations:^{
                             [self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) * self.angle)];
                         }
                                          completion:^(BOOL finished){
                                              
                                          }];
                     }];

    
  self.pendingTimer = [NSTimer  scheduledTimerWithTimeInterval:5 target:self selector:@selector(rotatePendingNeedle) userInfo:nil repeats:YES];
	
}

#pragma mark -
#pragma mark setSpeedometerCurrentValue

-(void) setSpeedometerCurrentValue:(int)value
{
	/*if(self.speedometer_Timer)
     {
     [self.speedometer_Timer invalidate];
     self.speedometer_Timer = nil;
     }*/
	//self.speedometerCurrentValue =  arc4random() % 100; // Generate Random value between 0 to 100. //
	
	//self.speedometer_Timer = [NSTimer  scheduledTimerWithTimeInterval:2 target:self selector:@selector(setSpeedometerCurrentValue) userInfo:nil repeats:YES];
    
	_speedometerCurrentValue = value;
	NSString *currentValueAsString = [NSString stringWithFormat:@"%i", self.speedometerCurrentValue];
    NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[currentValueAsString length]];
    int stringLength = [currentValueAsString length];
    for (int i=0; i < stringLength; i++) {
        NSString *ichar  = [NSString stringWithFormat:@"%c", [currentValueAsString characterAtIndex:i]];
        [characters addObject:ichar];
    }
    //Returns an enumerator object that lets me access each object in the array, in reverse order.
    NSArray* reversedArray = [[characters reverseObjectEnumerator] allObjects];
    for (int i=0; i < [reversedArray count]; i++) {
        if (i==0) {
            self.spReadingFirstNumber.text = [reversedArray objectAtIndex:0];
        }
        else if (i==1){
            self.spReadingSecondNumber.text = [reversedArray objectAtIndex:1];
        }
        else if (i==2){
            self.spReadingThirdNumber.text = [reversedArray objectAtIndex:2];
        }
        else if (i==3){
            self.spReadingFourthNumber.text = [reversedArray objectAtIndex:3];
        }
    }
    
	
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

#pragma mark -
#pragma mark Profile Button Methods

- (void)hideProfileAfterUserLoggedOff {
    if (self.profilePopover)
        [self.profilePopover dismissPopoverAnimated:YES];
    [navigationBarItems removeObject:self.profileBarButtonItem];
    [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:YES];
    if (self.pendingTimer) {
        [self.pendingTimer invalidate];
        _pendingTimer = nil;
    }
    if (self.continiousTimer) {
        [self.continiousTimer invalidate];
        _continiousTimer = nil;
    }
    // Going back
    [[self.splitViewController.viewControllers objectAtIndex:0]popToRootViewControllerAnimated:TRUE];
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    FirstDetailViewController *startDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
    detailViewManager.detailViewController = startDetailViewController;
    startDetailViewController.navigationBar.topItem.title = @"Summary";
    //
    //NSLog(@"self.splitViewController.viewControllers: %@", self.splitViewController.viewControllers);
    

}

- (IBAction)profileButtonTapped:(id)sender {
    if (_userProfile == nil) {
        self.userProfile = [[ProfilePopoverViewController alloc] init];
        //_userProfile.delegate = self;
        self.profilePopover = [[UIPopoverController alloc] initWithContentViewController:_userProfile];
        
    }
    [self.profilePopover presentPopoverFromBarButtonItem:sender
                                permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}
@end
