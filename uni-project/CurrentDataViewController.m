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
@property UIImageView *meterImageViewDot;

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
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self;
    
    // -setNavigationPaneBarButtonItem may have been invoked when before the
    // interface was loaded.  This will occur when setNavigationPaneBarButtonItem
    // is called as part of DetailViewManager preparing this view controller
    // for presentation as this is before the view is unarchived from the NIB.
    // When viewidLoad is invoked, the interface is loaded and hooked up.
    // Check if we are supposed to be displaying a navigationPaneBarButtonItem
    // and if so, add it to the navigationBar.
    if (self.navigationPaneBarButtonItem)
        [self.navigationBar.topItem setLeftBarButtonItem:self.navigationPaneBarButtonItem
                                                animated:NO];
    
    NSString *secondNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideProfileAfterUserLoggedOff)
     name:secondNotificationName
     object:nil];
    
    self.labelsWithNumbersCollection = [self sortCollection:self.labelsWithNumbersCollection];
    
    [self startSynchronization];
    
    [self initPlotForScatterPlot];
}

-(void)initPlotForScatterPlot {
    
    NSLog(@"Calling initPlotForScatterPlot");
    self.hostingView.allowPinchScaling = NO;
    [self createScatterPlot];
    
}

-(void)createScatterPlot {
    
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = self.hostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(self.hostingView.bounds);
#endif
    BOOL drawAxis = YES;
    if ( bounds.size.width < 200.0f ) {
        drawAxis = NO;
    }
    self.scatterPlot = [[CPTXYGraph alloc] initWithFrame:bounds];
    self.hostingView.hostedGraph = self.scatterPlot;
    
    [self.scatterPlot applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    if ( drawAxis ) {
        self.scatterPlot.paddingLeft   = 70.0;
        self.scatterPlot.paddingTop    = 20.0;
        self.scatterPlot.paddingRight  = 20.0;
        self.scatterPlot.paddingBottom = 80.0;
    }
    else {
        [self setPaddingDefaultsForGraph:self.scatterPlot withBounds:bounds];
    }
    
    // Setup plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.scatterPlot.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.xRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(2.0)];
    plotSpace.yRange                = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.0) length:CPTDecimalFromFloat(3.0)];
    
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)self.scatterPlot.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromString(@"0.5");
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval       = 2;
    NSArray *exclusionRanges = [NSArray arrayWithObjects:
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.99) length:CPTDecimalFromFloat(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.99) length:CPTDecimalFromFloat(0.02)],
                                [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(2.99) length:CPTDecimalFromFloat(0.02)],
                                nil];
    x.labelExclusionRanges = exclusionRanges;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromString(@"0.5");
    y.minorTicksPerInterval       = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    exclusionRanges               = [NSArray arrayWithObjects:
                                     [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(1.99) length:CPTDecimalFromFloat(0.02)],
                                     [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.99) length:CPTDecimalFromFloat(0.02)],
                                     [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(3.99) length:CPTDecimalFromFloat(0.02)],
                                     nil];
    y.labelExclusionRanges = exclusionRanges;
    
    // Create a blue plot area
    CPTScatterPlot *boundLinePlot = [[CPTScatterPlot alloc] init];
    boundLinePlot.identifier = @"Blue Plot";
    
    CPTMutableLineStyle *lineStyle = [boundLinePlot.dataLineStyle mutableCopy];
    lineStyle.miterLimit        = 1.0f;
    lineStyle.lineWidth         = 3.0f;
    lineStyle.lineColor         = [CPTColor blueColor];
    boundLinePlot.dataLineStyle = lineStyle;
    boundLinePlot.dataSource    = self;
    [self.scatterPlot addPlot:boundLinePlot];
    
    // Do a blue gradient
    CPTColor *areaColor1       = [CPTColor colorWithComponentRed:0.3 green:0.3 blue:1.0 alpha:0.8];
    CPTGradient *areaGradient1 = [CPTGradient gradientWithBeginningColor:areaColor1 endingColor:[CPTColor clearColor]];
    areaGradient1.angle = -90.0f;
    CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient1];
    boundLinePlot.areaFill      = areaGradientFill;
    boundLinePlot.areaBaseValue = [[NSDecimalNumber zero] decimalValue];
    
    // Add plot symbols
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill          = [CPTFill fillWithColor:[CPTColor blueColor]];
    plotSymbol.lineStyle     = symbolLineStyle;
    plotSymbol.size          = CGSizeMake(10.0, 10.0);
    boundLinePlot.plotSymbol = plotSymbol;
    
    // Add some initial data
    NSMutableArray *contentArray = [NSMutableArray arrayWithCapacity:100];
    NSUInteger i;
    for ( i = 0; i < 60; i++ ) {
        id x = [NSNumber numberWithFloat:1 + i * 0.05];
        id y = [NSNumber numberWithFloat:1.2 * rand() / (float)RAND_MAX + 1.2];
        [contentArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y, @"y", nil]];
    }
    self.dataForPlot = contentArray;
    
    
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
//    if ( [plot isKindOfClass:[CPTPieChart class]] ) {
//        return [self.dataForChart count];
//    }
//    else if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
//        return 16;
//    }
    
    return [self.dataForPlot count];
    
}

/*-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = nil;

    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    num = [[self.dataForPlot objectAtIndex:index] valueForKey:key];
    
    return num;
}*/

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y");
    NSNumber *num = [[self.dataForPlot objectAtIndex:index] valueForKey:key];
    
    if ( fieldEnum == CPTScatterPlotFieldY ) {
        num = [NSNumber numberWithDouble:[num doubleValue]];
    }
    
    return num;
}

-(void)setPaddingDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
    CGFloat boundsPadding = round(bounds.size.width / (CGFloat)20.0); // Ensure that padding falls on an integral pixel
    
    graph.paddingLeft = boundsPadding;
    
    if ( graph.titleDisplacement.y > 0.0 ) {
        graph.paddingTop = graph.titleDisplacement.y * 2;
    }
    else {
        graph.paddingTop = boundsPadding;
    }
    
    graph.paddingRight  = boundsPadding;
    graph.paddingBottom = boundsPadding;
}


// -------------------------------------------------------------------------------
//	viewWillAppear:
//  Called when the view has been fully transitioned onto the screen
// -------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    [self addMeterViewContents];
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
//  Called when the view is about to made visible
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"calling FirstDetailViewController - viewWillAppear start");
    [super viewWillAppear:animated];
    // NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"userLoggedIn"]) {
        //[navigationBarItems removeObject:self.profileBarButtonItem];
        [self.navigationBar.topItem setRightBarButtonItem:self.profileBarButtonItem animated:NO];
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
        self.continiousTimer = [NSTimer timerWithTimeInterval:60.0 // 1 minute
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
            NSLog(@"Max Watt changed! setting maxVal: %i, setting userMaximumWatt: %i ", self.maxVal, self.userMaximumWatt);
            [self changeSpeedometerNumbers];
            [self calculateDeviationAngle];
            
        }
        NSLog(@"Success! user's maximum watt consumption(userMaximumWatt): %i Watt, maxVal: %i Watt", self.userMaximumWatt, self.maxVal);
        
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
    
    int step = (int)floorf(self.userMaximumWatt/12);
    step = ((step+2)/5)*5;
    //NSLog(@"changeSpeedometerNumbers, step: %i", step);
    int temp = step;
    NSLog(@"changeSpeedometerNumbers, step: %i", step);
    for (UILabel *spLabel in self.labelsWithNumbersCollection) {
        NSLog(@"changeSpeedometerNumbers, temp: %i", temp);
        spLabel.text = [NSString stringWithFormat:@"%i", temp];
        temp += step;
    }
//    self.maxVal = temp - step;
//    NSLog(@"changeSpeedometerNumbers, setting new maxVal: %i", self.maxVal);
    self.userMaximumWatt = temp - step;
    NSLog(@"changeSpeedometerNumbers, setting new userMaximumWatt: %i", self.userMaximumWatt);
}


#pragma mark -
#pragma mark Public Methods

- (void)addMeterViewContents {
	//  Needle //
    // CGRectMake : x,  y,  width,  height
	//UIImageView *imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake(340, 168, 19, 147)];
    
    //[self.speedometerImageView setCenter:CGPointMake((self.view.frame.size.width/2), 246.0)];

//    NSLog(@"self.view.frame.size.width/2: %f", (self.view.frame.size.width/2));
//     NSLog(@"self.view.frame.size.width: %f", self.view.frame.size.width);
//    NSLog(@"self.view.bounds.size.width: %f", self.view.bounds.size.width);
    
    //UIImageView *imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake(340, 168, 19, 147)];
    UIImageView *imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(175), 168, 19, 147)];
	self.needleImageView = imgNeedle;
    [self.needleImageView setAutoresizingMask:UIViewAutoresizingNone];
	self.needleImageView.layer.anchorPoint = CGPointMake(self.needleImageView.layer.anchorPoint.x, self.needleImageView.layer.anchorPoint.y*2);
	self.needleImageView.backgroundColor = [UIColor clearColor];
	self.needleImageView.image = [UIImage imageNamed:@"speedometerArrow.png"];
	[self.view addSubview:self.needleImageView];

    // Needle Dot //
	//UIImageView *meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake(320, 213, 57, 57)];
    //self.meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake(320, 213, 57, 57)];
    self.meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(155), 213, 57, 57)];
    
    [self.meterImageViewDot setAutoresizingMask:UIViewAutoresizingNone];
	self.meterImageViewDot.image = [UIImage imageNamed:@"speedometerCenterWheel.png"];
	[self.view addSubview:self.meterImageViewDot];
	
	// Speedometer Reading //
	//self.speedometerReading.textColor = [UIColor colorWithRed:114/255.f green:146/255.f blue:38/255.f alpha:1.0];
    self.spReadingFirstNumber.text = @"0";
    
	
	// 
    if(!self.userMaximumWatt){
        
        self.maxVal = 0; // get maxVal from DB, TODO
        [self rotateIt:-120.5];
        self.prevAngleFactor = -120.5;
        [self setSpeedometerCurrentValue:0];
    }
}

#pragma mark -
#pragma mark calculateDeviationAngle Method

-(void) calculateDeviationAngle
{
	NSLog(@"calculateDeviationAngle - self.maxVal: %i", self.maxVal);
    NSLog(@"calculateDeviationAngle - userMaximumWatt: %i", self.userMaximumWatt);
    
	if(self.userMaximumWatt>0){
		self.angle = ((self.speedometerCurrentValue * 241)/self.userMaximumWatt-120.5);  // 241 - Total angle between 0 - maxVal
        //NSLog(@"calculateDeviationAngle - case 1");
        //NSLog(@"with self.speedometerCurrentValue: %i", self.speedometerCurrentValue);
        //NSLog(@"with self.maxVal: %i", self.maxVal);
	}
	else{
		self.angle = -120.5;
	}
	if(self.angle<=-120.5){
		self.angle = -120.5;
	}
	if(self.angle>=120.5){
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
    //NSLog(@"rotatePendingNeedle...");
    
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
   // NSLog(@"rotateNeedle...");
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


   // NSLog(@"rotateNeedle...");
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
    NSLog(@"hideProfileAfterUserLoggedOff...");
    if (self.profilePopover){
        [self.profilePopover dismissPopoverAnimated:YES];
        NSLog(@"profile popover dissmissed...");
    }
    [navigationBarItems removeObject:self.profileBarButtonItem];
    [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    NSLog(@"rightBarButtonItems: %@", [self.navigationBar.topItem rightBarButtonItems]);
    NSLog(@"navigationBarItems: %@", navigationBarItems);
    NSLog(@"self.profileBarButtonItem: %@", self.profileBarButtonItem);
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


#pragma mark -
#pragma mark SubstitutableDetailViewController

// -------------------------------------------------------------------------------
//	setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the navigationBar to either show or hide the
//  navigationPaneBarButtonItem.
// -------------------------------------------------------------------------------
- (void)setNavigationPaneBarButtonItem:(UIBarButtonItem *)navigationPaneBarButtonItem
{
    if (navigationPaneBarButtonItem != _navigationPaneBarButtonItem) {
        // Add the popover button to the left navigation item.
        [self.navigationBar.topItem setLeftBarButtonItem:navigationPaneBarButtonItem
                                                animated:NO];
        
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

    NSLog(@"DETAIL frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
    NSLog(@"DETAIL bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);
    
//    UILabel *firstLabel = [self.labelsWithNumbersCollection objectAtIndex:0];
    
//    for (UILabel *spLabel in self.labelsWithNumbersCollection) {
//        NSLog(@"spLabel height: %f", spLabel.frame.size.height);
//        NSLog(@"spLabel width: %f", spLabel.frame.size.width);
//        NSLog(@"spLabel: x=%f, y=%f", spLabel.frame.origin.x, spLabel.frame.origin.y);
//    }
//
//    NSLog(@"firstLabel height: %f", firstLabel.frame.size.height);
//    NSLog(@"firstLabel width: %f", firstLabel.frame.size.width);
//    NSLog(@"firstLabel: x=%f, y=%f", firstLabel.frame.origin.x, firstLabel.frame.origin.y);
//    
//    NSLog(@"speedometerImageView height: %f", self.speedometerImageView.frame.size.height);
//    NSLog(@"speedometerImageView width: %f", self.speedometerImageView.frame.size.width);
//    NSLog(@"speedometerImageView: x=%f, y=%f", self.speedometerImageView.frame.origin.x, self.speedometerImageView.frame.origin.y);

    
}

// Faster one-part variant, called from within a rotating animation block
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    
    if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        NSLog(@"Rotating to Landscape");
        [self.needleImageView setCenter:self.speedometerImageView.center];
        [self.meterImageViewDot setFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(155), 213, 57, 57)];
    }
    else {
        NSLog(@"Rotating to Portrait");
        [self.needleImageView setCenter:self.speedometerImageView.center];
        [self.meterImageViewDot setFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(155), 213, 57, 57)];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
