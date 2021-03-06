//
//  CurrentDataViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//
//  TEST: userID = 3

#import "CurrentDataViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "EMNetworkManager.h"
#import "DetailViewManager.h"
#import "FirstDetailViewController.h"
#import "Reachability.h"
#import "KeychainItemWrapper.h"
#import "SSKeychain.h"

// Real Time Plot
static const double kFrameRate         = 5.0;  // frames per second
static const double kAlpha             = 0.25; // smoothing constant
static const NSUInteger kMaxDataPoints = 10;
static const NSString *kPlotIdentifier = @"Data Source Plot";

@interface CurrentDataViewController ()

@property (nonatomic, strong) NSTimer *pendingTimer;
@property (nonatomic, strong) NSTimer *continiousTimer;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) UIImageView *meterImageViewDot;
@property (nonatomic, strong) NSMutableArray *lastWattValues;
@property (nonatomic, assign) NSUInteger currentIndex;
@property (nonatomic, strong) NSTimer *dataTimer;
@property (nonatomic, assign) BOOL deviceIsOnline;

// Top Area, Speedometer
@property (nonatomic, strong) UIImageView *needleImageView;
@property (nonatomic, assign) int speedometerCurrentValue;
@property (nonatomic, assign) float prevAngleFactor;
@property (nonatomic, assign) float angle;
@property (nonatomic, assign) int maxVal;
@property (nonatomic, weak)   IBOutlet UIImageView *speedometerImageView;
@property (nonatomic, assign) NSUInteger userMaximumWatt;
@property (nonatomic, assign) NSUInteger userCurrentWatt;
@property (nonatomic, weak)   IBOutlet UILabel *spReadingFirstNumber;
@property (nonatomic, weak)   IBOutlet UILabel *spReadingSecondNumber;
@property (nonatomic, weak)   IBOutlet UILabel *spReadingThirdNumber;
@property (nonatomic, weak)   IBOutlet UILabel *spReadingFourthNumber;

// must be strong! IBOutletCollection isn't retained by the view, because its not a subview 
@property (nonatomic, strong) IBOutletCollection(UILabel) NSArray *labelsWithNumbersCollection;

// Bottom Main View
@property (nonatomic, weak)   IBOutlet UIView *bottomMainView;

// Bottom Area, Scatter Plot on the left side
@property (nonatomic, weak)   IBOutlet CPTGraphHostingView *hostingView;
@property (nonatomic, strong) CPTGraphHostingView *scatterPlotView;
@property (nonatomic, strong) CPTGraph *scatterGraph;
@property (nonatomic, strong) NSMutableArray *dataForPlot;

// Bottom Area, Current Day - total power consumption and Total Cost on the right side
@property (nonatomic, weak)   IBOutlet UIView *dataDisplayView;
@property (nonatomic, weak)   IBOutlet UILabel *kwhDataLabel;
@property (nonatomic, weak)   IBOutlet UILabel *eurDataLabel;

@property (nonatomic, strong) ProfilePopoverViewController *userProfile;
@property (nonatomic, strong) UIPopoverController *profilePopover;
@property (nonatomic, weak)   IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, weak)   IBOutlet UINavigationBar *navigationBar;

@property (nonatomic, strong) Reachability* reachabilityObj;

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

// Lazy instantiation
- (Reachability *) reachabilityObj
{
    if(!_reachabilityObj)
    {
        _reachabilityObj = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    }
    return _reachabilityObj;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    DLog(@"viewDidLoad...");
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
    
    self.bottomMainView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"currentDataBottomViewBackg.png"]];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"patternBg"]];

    __block MBProgressHUD *hud;
    
    NSString *secondNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideProfileAfterUserLoggedOff)
     name:secondNotificationName
     object:nil];
    
    self.labelsWithNumbersCollection = [self sortCollection:self.labelsWithNumbersCollection];
    self.lastWattValues = [[NSMutableArray alloc] init];
    // avoiding retain cycle
    __weak CurrentDataViewController *weakSelf = self;
    self.reachabilityObj.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"Block Says Reachable");
            weakSelf.deviceIsOnline = YES;
            if (hud) {
                [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
                [hud removeFromSuperview];
                hud = nil;
            }
            [weakSelf startSynchronization];
        });
    };
    
    self.reachabilityObj.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"Block Says Unreachable");
            weakSelf.deviceIsOnline = NO;
            hud = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
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
    
    [self.reachabilityObj startNotifier];
    
    [self initDataDisplayView];
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
//  Called when the view has been fully transitioned onto the screen
// -------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated {
    if (!self.instanceWasCached) {
        DLog(@"viewDidAppear...");
        [self addMeterViewContents];
        [self initPlotForScatterPlot];
    }
    /* LOGGING START
     ****************/
    System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext){
        
        System *localSystem = [systemObj inContext:localContext];
        NSNumber *currentdatalogNumber = @(1);
        if (localSystem.currentdatalog < 0) { // something went wrong
        }
        else {
            NSNumber *currentdatalogNumberTemp = localSystem.currentdatalog;
            currentdatalogNumber = [NSNumber numberWithInt:[currentdatalogNumberTemp integerValue] +1 ];
        }
        localSystem.currentdatalog = currentdatalogNumber;
    } completion:^{
        
        System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
        DLog(@"saved System Object :%@", systemObj);
        DLog(@"saved System Object, currentdatalog :%@", systemObj.currentdatalog);
        
    }];
    /* LOGGING END
     ****************/
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
//  Called when the view is about to made visible
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    DLog(@"calling CurrentDataViewController - viewWillAppear start");
    [super viewWillAppear:animated];
    // DLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
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
    
    //DLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    
}



//----------------------------------------------------------------------------------------
//                              Real Time Plot Methods - START
//----------------------------------------------------------------------------------------

-(void)initPlotForScatterPlot {
    
    DLog(@"Calling initPlotForScatterPlot");
    self.hostingView.allowPinchScaling = YES;
    self.dataForPlot  = [[NSMutableArray alloc] initWithCapacity:kMaxDataPoints];
    [self createScatterPlot];
    DLog(@"<initPlotForScatterPlot> self.deviceIsOnline: %i",self.deviceIsOnline);
    if (self.deviceIsOnline) {
        [self generateData];
    }
}

-(void)generateData
{
    DLog(@"Calling generateData");
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
    DLog(@"Calling createScatterPlot");
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = self.hostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(self.hostingView.bounds);
#endif
    BOOL drawAxis = YES;
    if ( bounds.size.width < 200.0f ) {
        drawAxis = NO;
        //DLog(@"drawAxis=NO");
    }
    self.scatterGraph = [[CPTXYGraph alloc] initWithFrame:bounds];
    self.hostingView.hostedGraph = self.scatterGraph;
    
    //[self.scatterGraph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    if ( drawAxis ) {
        //DLog(@"drawAxis=YES");
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
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.numberStyle = kCFNumberFormatterDecimalStyle;
    labelFormatter.maximumFractionDigits = 0;
    
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
    
    // Rotate the labels by 45 degrees
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
     DLog(@"self.userCurrentWatt: %i", self.userCurrentWatt);
    
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
    DLog(@"Calling numberForPlot");
    switch ( fieldEnum ) {
        case CPTScatterPlotFieldX:
            num = @(index + self.currentIndex - self.dataForPlot.count);
            DLog(@"X Value, num = %@, index = %i", num, index);
            break;
            
        case CPTScatterPlotFieldY:
            num = (self.dataForPlot)[index];
            DLog(@"Y value, num = %@, index = %i", num, index);
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
    DLog(@"---newData:theTimer---");
    CPTGraph *theGraph = self.scatterGraph;
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];
    
    if ( thePlot ) {
        if ( self.dataForPlot.count >= kMaxDataPoints ) {
            [self.dataForPlot removeObjectAtIndex:0];
            [thePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
        }
        
        DLog(@"---newData:theTimer---setting yRange");
        
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
    
    DLog(@"self.dataForPlot: %@", self.dataForPlot);
    
}



//----------------------------------------------------------------------------------------
//                              Real Time Plot Methods - END
//----------------------------------------------------------------------------------------

- (void) initDataDisplayView {
    DLog(@"calling initDataDisplayView");
    DLog(@"lastWattValues count: %i", [self.lastWattValues count]);
    if ([self.lastWattValues count] > 0) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH"];
        int hours = [[dateFormatter stringFromDate:[NSDate date]] intValue]; // hours can be 0 !
        if (hours==0) {
            hours = 1;
        }
        //DLog(@"hours: %i", hours);
        //NSNumber *total = [self.lastWattValues valueForKeyPath:@"@sum.value"];
        float total = 0.00;
        for(NSNumber *wattValue in self.lastWattValues){
            total += [wattValue floatValue];
        }
        total = total/[self.lastWattValues count]; // calculate average value
        float averageKwhTemp = (total/1000)*hours;
         DLog(@"averageKwhTemp: %f", averageKwhTemp);
        averageKwhTemp = (ceil(averageKwhTemp * 100.0)) / 100.0;
        DLog(@"total: %f", total);
        DLog(@"averageKwhTemp: %f", averageKwhTemp);
        NSString *averageKwh = [NSString stringWithFormat:@"%.2f", averageKwhTemp];
        
        DLog(@"averageKwh: %@", averageKwh);
        self.kwhDataLabel.text = averageKwh;
        
        // electricity tariff: Stadtwerke Strom Basis, over 10000 kWh
        float averageCostsTemp = averageKwhTemp * (28.77/100.0);
        NSString *averageCosts = [NSString stringWithFormat:@"%.2f", averageCostsTemp];
        DLog(@"averageCosts: %@", averageCosts);
        self.eurDataLabel.text = averageCosts;
    }
    else {
        //DLog(@"setting kwhDataLabel and eurDataLabel = 0");
        self.kwhDataLabel.text = @"0.00";
        self.eurDataLabel.text = @"0.00";
    }
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startSynchronization
{
    DLog(@"startSynchronization...");
    //self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
    //[self.view addSubview:self.HUD];
	//self.HUD.delegate = self;
	self.HUD.labelText = @"Loading";
    self.HUD.yOffset = -125.f;
    //[self.HUD show:YES];
    
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

- (void)getDataFromServer:(NSTimer *)timer
{
    
    __block NSTimer *checkForTimeOutTimer;
    
    DLog(@"getDataFromServer...");
    //max consumption is a value, beeing aggregated during a period of time, i.e. 14 days
    // we should store this value in our DB, using Core Data
    // TODO
    NSString *getPath = @"rpc.php?userID=";
    getPath = [getPath stringByAppendingString: [NSString stringWithFormat:@"%i", MySensorID] ];
    getPath = [getPath stringByAppendingString:@"&action=get&what=max"];
    [[EMNetworkManager sharedClient] getPath:getPath parameters:nil success:^(AFHTTPRequestOperation *operation, id data) {
        if(checkForTimeOutTimer){
            [checkForTimeOutTimer invalidate];
            checkForTimeOutTimer = nil;
            [self generateData];
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
        NSString *userMaxWattString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        //if (self.userMaximumWatt != [userMaxWattString intValue]) {
        if (self.maxVal != [userMaxWattString intValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            self.userMaximumWatt = [userMaxWattString intValue];
            self.maxVal = [userMaxWattString intValue];
            DLog(@"Max Watt changed! setting maxVal: %i, setting userMaximumWatt: %i ", self.maxVal, self.userMaximumWatt);
            [self changeSpeedometerNumbers];
            [self calculateDeviationAngle];
            
        }
        DLog(@"Success! user's maximum watt consumption(userMaximumWatt): %i Watt, maxVal: %i Watt", self.userMaximumWatt, self.maxVal);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        DLog(@"Failed during getting maximum watt: %ld",(long)[error code]);
        if (USEDUMMYDATA) {
            // stop the timer
            if(self.continiousTimer){
                [self.continiousTimer invalidate];
                self.continiousTimer = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            self.userMaximumWatt = 600;
            self.maxVal = 600;
            DLog(@"USING DUMMY DATA: Max Watt changed! setting maxVal: %i, setting userMaximumWatt: %i ", self.maxVal, self.userMaximumWatt);
            [self changeSpeedometerNumbers];
            [self calculateDeviationAngle];
        }
        else {
            // =='The request timed out'
            if ([error code]==-1001) {
                if(self.dataTimer){
                    [self.dataTimer invalidate];
                    self.dataTimer = nil;
                }
                if(self.continiousTimer){
                    [self.continiousTimer invalidate];
                    self.continiousTimer = nil;
                }
                [MBProgressHUD hideHUDForView:self.view animated:YES];
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                //[self.HUD show:NO];
                //self.HUD = nil;
                self.HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                // Configure for text only and offset down
                self.HUD.labelText = @"Verbindung fehlgeschlagen";
                NSString *_detailsLabelText = [NSString stringWithFormat:@"Bei der Verbindung zum Server  \n"
                                               "ist eine Zeitüberschreitung aufgetreten.  \n"];
                self.HUD.detailsLabelText = _detailsLabelText;
                self.HUD.square = YES;
                self.HUD.mode = MBProgressHUDModeText;
                self.HUD.margin = 10.f;
                self.HUD.yOffset = 20.f;
                [self.HUD show:YES];
                
                // check every 10 min. if we can connect to the server
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    checkForTimeOutTimer = [NSTimer timerWithTimeInterval:60.0*10.0 // 10 minutes
                                                                   target:self
                                                                 selector:@selector(getDataFromServer:)
                                                                 userInfo:nil
                                                                  repeats:YES];
                    
                    [[NSRunLoop currentRunLoop] addTimer:checkForTimeOutTimer forMode:NSRunLoopCommonModes];
                    [[NSRunLoop currentRunLoop] run];
                });
            }
        }
        
    }];
    
    
    [[EMNetworkManager sharedClient] getPath:@"rpc.php?userID=3&action=get&what=watt" parameters:nil success:^(AFHTTPRequestOperation *operation, id data) {
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
                //DLog(@"__lastWattValues: %@", self.lastWattValues);
                //DLog(@"__object: %@", [self.lastWattValues objectAtIndex:0]);
            }
            else {
                [self.lastWattValues removeObjectAtIndex:0];
                [self.lastWattValues addObject:@(self.userCurrentWatt)];
                //[self.lastWattValues addObject:[NSNull null]];
                //DLog(@"_lastWattValues: %@", self.lastWattValues);
            }
            
            // Update the dataDisplayView
            [self initDataDisplayView];
        
            
        }
        else {
            //pendingTimer = [NSTimer  scheduledTimerWithTimeInterval:5 target:self selector:@selector(rotatePendingNeedle) userInfo:nil repeats:YES];
            //[self rotatePendingNeedle];
        }
        DLog(@"Success! user's current watt consumption: %i Watt", self.userCurrentWatt);
        // Update the dataDisplayView
        [self initDataDisplayView];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DLog(@"Failed during getting current watt: %@",[error localizedDescription]);
        if (USEDUMMYDATA) {
            // stop the timer
            if(self.continiousTimer){
                [self.continiousTimer invalidate];
                self.continiousTimer = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideHUDForView:self.view animated:YES];
            });
            
            self.userCurrentWatt = 230;
            [self setSpeedometerCurrentValue:self.userCurrentWatt];
            [self.lastWattValues addObject:@(self.userCurrentWatt)];
            
            DLog(@"USING DUMMY DATA: Max Watt changed! setting maxVal: %i, setting userMaximumWatt: %i ", self.maxVal, self.userMaximumWatt);
            [self initDataDisplayView];
        }
    }];
     
}

-(NSArray *)sortCollection:(NSArray *)toSort
{
    NSArray *sortedArray;
    sortedArray = [toSort sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *tag1 = @([(UILabel*)a tag]);
        NSNumber *tag2 = @([(UILabel*)b tag]);
        return [tag1 compare:tag2];
    }];
    return sortedArray;
}

- (void)changeSpeedometerNumbers
{
    DLog(@"changeSpeedometerNumbers, self.labelsWithNumbersCollection: %@", self.labelsWithNumbersCollection);
    int step = (int)floorf(self.userMaximumWatt/12);
    step = ((step+2)/5)*5;
    DLog(@"changeSpeedometerNumbers, step: %i", step);
    int temp = step;
    DLog(@"changeSpeedometerNumbers, step: %i", step);
    for (UILabel *spLabel in self.labelsWithNumbersCollection) {
        DLog(@"changeSpeedometerNumbers, temp: %i", temp);
        spLabel.text = [NSString stringWithFormat:@"%i", temp];
        temp += step;
    }
    DLog(@"changeSpeedometerNumbers, setting new maxVal: %i", self.maxVal);
    self.userMaximumWatt = temp - step;
    DLog(@"changeSpeedometerNumbers, setting new userMaximumWatt: %i", self.userMaximumWatt);
}


#pragma mark -
#pragma mark Public Methods

- (void)addMeterViewContents
{
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
    
    if (self.HUD) {
        [self.view addSubview:self.HUD];
        [self.HUD show:YES];
    }
}

#pragma mark -
#pragma mark calculateDeviationAngle Method

-(void) calculateDeviationAngle
{
	DLog(@"calculateDeviationAngle - self.maxVal: %i", self.maxVal);
    DLog(@"calculateDeviationAngle - userMaximumWatt: %i", self.userMaximumWatt);
    
	if(self.userMaximumWatt>0){
		self.angle = ((self.speedometerCurrentValue * 241)/self.userMaximumWatt-120.5);  // 241 - Total angle between 0 - maxVal
        //DLog(@"calculateDeviationAngle - case 1");
        //DLog(@"with self.speedometerCurrentValue: %i", self.speedometerCurrentValue);
        //DLog(@"with self.maxVal: %i", self.maxVal);
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
	
	DLog(@"self.angle: %f", self.angle);
    
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
    //DLog(@"rotatePendingNeedle...");
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

    DLog(@"rotateNeedle...");
    DLog(@"self.needleImageView: %@", self.needleImageView);
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
    DLog(@"setSpeedometerCurrentValue...");
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
    // DLog(@"rotateIt...");
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.01f];
	[self.needleImageView setTransform: CGAffineTransformMakeRotation((M_PI / 180) *angl)];
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Profile Button Methods

- (void)hideProfileAfterUserLoggedOff {
    DLog(@"hideProfileAfterUserLoggedOff...");
    if (self.profilePopover){
        [self.profilePopover dismissPopoverAnimated:YES];
        DLog(@"profile popover dissmissed...");
    }
    [navigationBarItems removeObject:self.profileBarButtonItem];
    [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    DLog(@"rightBarButtonItems: %@", [self.navigationBar.topItem rightBarButtonItems]);
    DLog(@"navigationBarItems: %@", navigationBarItems);
    DLog(@"self.profileBarButtonItem: %@", self.profileBarButtonItem);
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
    startDetailViewController.navigationBar.topItem.title = @"Home";

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

//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//
//    DLog(@"DETAIL frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
//    DLog(@"DETAIL bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);
//    
//}

// Faster one-part variant, called from within a rotating animation block
//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
//    
//    if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight)
//    {
//        DLog(@"Rotating to Landscape");
//        [self.needleImageView setCenter:self.speedometerImageView.center];
//        [self.meterImageViewDot setFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(155), 213, 57, 57)];
//    }
//    else {
//        DLog(@"Rotating to Portrait");
//        [self.needleImageView setCenter:self.speedometerImageView.center];
//        [self.meterImageViewDot setFrame:CGRectMake((self.speedometerImageView.frame.origin.x)+(155), 213, 57, 57)];
//    }
//}

/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}*/

@end
