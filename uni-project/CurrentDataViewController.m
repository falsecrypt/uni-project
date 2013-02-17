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
#import "Reachability.h"
#import "KeychainItemWrapper.h"

// Real Time Plot
const double kFrameRate         = 5.0;  // frames per second
const double kAlpha             = 0.25; // smoothing constant
const NSUInteger kMaxDataPoints = 10;
const NSString *kPlotIdentifier = @"Data Source Plot";

@interface CurrentDataViewController ()

@property (nonatomic, strong) NSTimer *pendingTimer;
@property (nonatomic, strong) NSTimer *continiousTimer;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) UIImageView *meterImageViewDot;
@property (nonatomic, strong) NSMutableArray *lastWattValues;
@property (nonatomic) NSUInteger currentIndex;
@property (nonatomic) NSTimer *dataTimer;
@property (nonatomic) BOOL deviceIsOnline;

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
    NSLog(@"viewDidLoad...");
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
    
    self.bottomMainView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"currentDataBottomViewBackg.png"]];
    self.view.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"patternBg"]];
    
    // allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    __block MBProgressHUD *hud;
    
    NSString *secondNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideProfileAfterUserLoggedOff)
     name:secondNotificationName
     object:nil];
    
    self.labelsWithNumbersCollection = [self sortCollection:self.labelsWithNumbersCollection];
    self.lastWattValues = [[NSMutableArray alloc] init];
    
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Reachable");
            self.deviceIsOnline = YES;
            if (hud) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [hud removeFromSuperview];
                hud = nil;
            }
            [self startSynchronization];
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Unreachable");
            self.deviceIsOnline = NO;
            hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            // Configure for text only and offset down
            hud.labelText = @"Verbindung fehlgeschlagen";
            hud.detailsLabelText = @"Bitte überprüfen Sie Ihre Internetverbindung";
            hud.square = YES;
            hud.mode = MBProgressHUDModeText;
            hud.margin = 10.f;
            hud.yOffset = 20.f;
            //hud.removeFromSuperViewOnHide = YES;
        });
    };
    
    [reach startNotifier];
    
    [self initDataDisplayView];
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
//  Called when the view has been fully transitioned onto the screen
// -------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    if (!self.instanceWasCached) {
        NSLog(@"viewDidAppear...");
        [self addMeterViewContents];
        [self initPlotForScatterPlot];
    }

}

// -------------------------------------------------------------------------------
//	viewWillAppear:
//  Called when the view is about to made visible
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"calling CurrentDataViewController - viewWillAppear start");
    [super viewWillAppear:animated];
    // NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if (!(BOOL)[keychain objectForKey:(__bridge id)(kSecAttrLabel)]) {
        //[navigationBarItems removeObject:self.profileBarButtonItem];
        [self.navigationBar.topItem setRightBarButtonItem:self.profileBarButtonItem animated:NO];
    }
    
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd.MM.yyyy"];
    NSString *dateString = [dateFormat stringFromDate:today];
    NSString *startText = @"Daten für heute, ";
    self.navigationBar.topItem.title = [startText stringByAppendingString:dateString];
    
    //NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    
}



//----------------------------------------------------------------------------------------
//                              Real Time Plot Methods - START
//----------------------------------------------------------------------------------------

-(void)initPlotForScatterPlot {
    
    NSLog(@"Calling initPlotForScatterPlot");
    self.hostingView.allowPinchScaling = YES;
    self.dataForPlot  = [[NSMutableArray alloc] initWithCapacity:kMaxDataPoints];
    [self createScatterPlot];
    if (self.deviceIsOnline) {
        [self generateData];
    }
}

-(void)generateData
{
    NSLog(@"Calling generateData");
    [self.dataForPlot removeAllObjects];
    [self.dataForPlot addObject:@0];
    self.currentIndex = 1; //0
    /*NSTimer* firstTimer = [NSTimer timerWithTimeInterval:0.1
                                                  target:self
                                                selector:@selector(newData:)
                                                userInfo:nil
                                                 repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:firstTimer forMode:NSDefaultRunLoopMode]; */
    
    self.dataTimer = [NSTimer timerWithTimeInterval:60.0 //60.0
                                         target:self
                                       selector:@selector(newData:)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.dataTimer forMode:NSDefaultRunLoopMode];
}

-(void)createScatterPlot {
    NSLog(@"Calling createScatterPlot");
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = self.hostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(self.hostingView.bounds);
#endif
    BOOL drawAxis = YES;
    if ( bounds.size.width < 200.0f ) {
        drawAxis = NO;
        //NSLog(@"drawAxis=NO");
    }
    self.scatterGraph = [[CPTXYGraph alloc] initWithFrame:bounds];
    self.hostingView.hostedGraph = self.scatterGraph;
    
    //[self.scatterGraph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    if ( drawAxis ) {
        //NSLog(@"drawAxis=YES");
        self.scatterGraph.paddingLeft   = 1.0;
        self.scatterGraph.paddingTop    = 1.0;
        self.scatterGraph.paddingRight  = 1.0;
        self.scatterGraph.paddingBottom = 1.0;
    }
    else {
        [self setPaddingDefaultsForGraph:self.scatterGraph withBounds:bounds];
    }
    
    self.scatterGraph.plotAreaFrame.paddingTop    = 15.0;
    self.scatterGraph.plotAreaFrame.paddingRight  = 10.0;
    self.scatterGraph.plotAreaFrame.paddingBottom = 45.0;
    self.scatterGraph.plotAreaFrame.paddingLeft   = 45.0;
    
    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.50;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];
    
    // Axes
    // X axis
    CPTXYAxisSet *axisSet         = (CPTXYAxisSet *)self.scatterGraph.axisSet;
    CPTXYAxis *x                  = axisSet.xAxis;
    x.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    x.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    x.majorGridLineStyle          = majorGridLineStyle;
    x.minorGridLineStyle          = minorGridLineStyle;
    x.minorTicksPerInterval       = 1;
    x.title                       = @"Zeit (Min.)";
    x.titleOffset                 = 23.0;
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.numberStyle = kCFNumberFormatterDecimalStyle;
    labelFormatter.maximumFractionDigits = 0;
    x.labelFormatter              = labelFormatter;
    
    // Y axis
    CPTXYAxis *y                  = axisSet.yAxis;
    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    y.majorGridLineStyle          = majorGridLineStyle;
    y.minorGridLineStyle          = minorGridLineStyle;
    y.minorTicksPerInterval       = 2;
    y.labelOffset                 = 1.0;
    y.title                       = @"Leistung (Watt)";
    y.titleOffset                 = 26.0;
    y.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
    y.labelFormatter              = labelFormatter;
    
    // Rotate the labels by 45 degrees, just to show it can be done.
    x.labelRotation = M_PI * 0.25;
    
    // Create the plot
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier     = kPlotIdentifier;
    dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionAuto;
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 2.0;
    lineStyle.lineColor              = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [self.scatterGraph addPlot:dataSourceLinePlot];
    
    // Plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)self.scatterGraph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 1)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(100)];
     NSLog(@"self.userCurrentWatt: %i", self.userCurrentWatt);
    
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [self.dataForPlot count];
}


-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num = nil;
    NSLog(@"Calling numberForPlot");
    switch ( fieldEnum ) {
        case CPTScatterPlotFieldX:
            num = @(index + self.currentIndex - self.dataForPlot.count);
            NSLog(@"X Value, num = %@, index = %i", num, index);
            break;
            
        case CPTScatterPlotFieldY:
            num = (self.dataForPlot)[index];
            NSLog(@"Y value, num = %@, index = %i", num, index);
            break;
            
        default:
            break;
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

#pragma mark -
#pragma mark Timer callback

-(void)newData:(NSTimer *)theTimer
{
    NSLog(@"---newData:theTimer---");
    CPTGraph *theGraph = self.scatterGraph;
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];
    
    if ( thePlot ) {
        if ( self.dataForPlot.count >= kMaxDataPoints ) {
            [self.dataForPlot removeObjectAtIndex:0];
            [thePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
        }
        
        NSLog(@"---newData:theTimer---setting yRange");
        
        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)theGraph.defaultPlotSpace;
        NSUInteger location       = (self.currentIndex >= kMaxDataPoints ? self.currentIndex - kMaxDataPoints + 1 : 0);
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
                                                        length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 1)];
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(self.userMaximumWatt)];
        
        self.currentIndex++;
        //float kWhrData = (self.userCurrentWatt/1000.00)*(1.0/60.0);
        [self.dataForPlot addObject:@(self.userCurrentWatt)];
        //[self.dataForPlot addObject:[NSNumber numberWithDouble:(1.0 - kAlpha) * [[self.dataForPlot lastObject] doubleValue] + kAlpha * rand() / (double)RAND_MAX]];
        [thePlot insertDataAtIndex:self.dataForPlot.count - 1 numberOfRecords:1];
    }
    
    NSLog(@"self.dataForPlot: %@", self.dataForPlot);
    
}



//----------------------------------------------------------------------------------------
//                              Real Time Plot Methods - END
//----------------------------------------------------------------------------------------

- (void) initDataDisplayView {
    NSLog(@"calling initDataDisplayView");
    //NSLog(@"count: %i", [self.lastWattValues count]);
    if ([self.lastWattValues count] > 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"HH"];
        int hours = [[dateFormatter stringFromDate:[NSDate date]] intValue];
        //NSLog(@"hours: %i", hours);
        //NSNumber *total = [self.lastWattValues valueForKeyPath:@"@sum.value"];
        float total = 0.00;
        for(int i=0;i<[self.lastWattValues count];i++){
            total += [(self.lastWattValues)[i] floatValue];
        }
        total = total/[self.lastWattValues count]; // calculate average value
        float averageKwhTemp = (total/1000)*hours;
         //NSLog(@"averageKwhTemp: %f", averageKwhTemp);
        averageKwhTemp = (ceil(averageKwhTemp * 100.0)) / 100.0;
        //NSLog(@"total: %f", total);
        //NSLog(@"averageKwhTemp: %f", averageKwhTemp);
        //NSString *averageKwh = [NSString stringWithFormat:@"%.2f", averageKwhTemp];
        NSString *averageKwh = [NSString stringWithFormat:@"%.2f", averageKwhTemp];
        
        //NSLog(@"averageKwh: %@", averageKwh);
        self.kwhDataLabel.text = averageKwh;
        
        // electricity tariff: Stadtwerke Strom Basis, over 10000 kWh
        float averageCostsTemp = averageKwhTemp * (28.77/100.0);
        NSString *averageCosts = [NSString stringWithFormat:@"%.2f", averageCostsTemp];
        //NSLog(@"averageCosts: %@", averageCosts);
        self.eurDataLabel.text = averageCosts;
    }
    else {
        //NSLog(@"setting kwhDataLabel and eurDataLabel = 0");
        self.kwhDataLabel.text = @"0.00";
        self.eurDataLabel.text = @"0.00";
    }
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

            [self setSpeedometerCurrentValue:self.userCurrentWatt];
            
            // store the new value in this array, but max 20 values
            if ([self.lastWattValues count] <= 20) {
                [self.lastWattValues addObject:@(self.userCurrentWatt)];
                //[self.lastWattValues addObject:[NSNull null]];
                //NSLog(@"__lastWattValues: %@", self.lastWattValues);
                //NSLog(@"__object: %@", [self.lastWattValues objectAtIndex:0]);
            }
            else {
                [self.lastWattValues removeObjectAtIndex:0];
                [self.lastWattValues addObject:@(self.userCurrentWatt)];
                //[self.lastWattValues addObject:[NSNull null]];
                //NSLog(@"_lastWattValues: %@", self.lastWattValues);
            }
            
            // Update the dataDisplayView
            [self initDataDisplayView];
        
            
        }
        else {
            //pendingTimer = [NSTimer  scheduledTimerWithTimeInterval:5 target:self selector:@selector(rotatePendingNeedle) userInfo:nil repeats:YES];
            //[self rotatePendingNeedle];
        }
        NSLog(@"Success! user's current watt consumption: %i Watt", self.userCurrentWatt);
        // Update the dataDisplayView
        [self initDataDisplayView];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed during getting current watt: %@",[error localizedDescription]);
    }];
     
}

-(NSArray *)sortCollection:(NSArray *)toSort {
    NSArray *sortedArray;
    sortedArray = [toSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *tag1 = @([(UILabel*)a tag]);
        NSNumber *tag2 = @([(UILabel*)b tag]);
        return [tag1 compare:tag2];
    }];
    return sortedArray;
}

- (void)changeSpeedometerNumbers {
    
    int step = (int)floorf(self.userMaximumWatt/12);
    step = ((step+2)/5)*5;
    //NSLog(@"changeSpeedometerNumbers, step: %i", step);
    int temp = step;
    //NSLog(@"changeSpeedometerNumbers, step: %i", step);
    for (UILabel *spLabel in self.labelsWithNumbersCollection) {
        //NSLog(@"changeSpeedometerNumbers, temp: %i", temp);
        spLabel.text = [NSString stringWithFormat:@"%i", temp];
        temp += step;
    }
//    NSLog(@"changeSpeedometerNumbers, setting new maxVal: %i", self.maxVal);
    self.userMaximumWatt = temp - step;
    NSLog(@"changeSpeedometerNumbers, setting new userMaximumWatt: %i", self.userMaximumWatt);
}


#pragma mark -
#pragma mark Public Methods

- (void)addMeterViewContents {
	//  Needle //
    // CGRectMake : x,  y,  width,  height
    UIImageView *imgNeedle = [[UIImageView alloc]initWithFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(175), 168, 19, 147)];
	self.needleImageView = imgNeedle;
    [self.needleImageView setAutoresizingMask:UIViewAutoresizingNone];
	self.needleImageView.layer.anchorPoint = CGPointMake(self.needleImageView.layer.anchorPoint.x, self.needleImageView.layer.anchorPoint.y*2);
	self.needleImageView.backgroundColor = [UIColor clearColor];
	self.needleImageView.image = [UIImage imageNamed:@"speedometerArrow.png"];
	[self.view addSubview:self.needleImageView];

    // Needle Dot //
    self.meterImageViewDot = [[UIImageView alloc]initWithFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(155), 213, 57, 57)];
    
    [self.meterImageViewDot setAutoresizingMask:UIViewAutoresizingNone];
	self.meterImageViewDot.image = [UIImage imageNamed:@"speedometerCenterWheel.png"];
	[self.view addSubview:self.meterImageViewDot];
	
	// Speedometer Reading //
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
            self.spReadingFirstNumber.text = reversedArray[0];
        }
        else if (i==1){
            self.spReadingSecondNumber.text = reversedArray[1];
        }
        else if (i==2){
            self.spReadingThirdNumber.text = reversedArray[2];
        }
        else if (i==3){
            self.spReadingFourthNumber.text = reversedArray[3];
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
    [(self.splitViewController.viewControllers)[0]popToRootViewControllerAnimated:TRUE];
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
