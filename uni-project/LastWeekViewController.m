//
//  LastWeekViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "LastWeekViewController.h"
#import "DetailViewManager.h"
#import "FirstDetailViewController.h"
#import "MBProgressHUD.h"
#import "AFAppDotNetAPIClient.h"
#import "WeekData.h"
#import "Reachability.h"

NSString *const pieChartName = @"7DaysPieChart";
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

CGPoint lastLocation;
CPTPieChart *piePlot;
BOOL selecting;
BOOL repeatingTouch;
BOOL firstTime;
BOOL deviceIsOnline;
NSUInteger currentSliceIndex;
NSMutableDictionary *dayDataDictionary;

@interface LastWeekViewController ()

@property MBProgressHUD *HUD;

@end

@implementation LastWeekViewController

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
    
    if (!self.instanceWasCached) {
    
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        detailViewManager.detailViewController = self;
        
        if (self.navigationPaneBarButtonItem)
            [self.navigationBar.topItem setLeftBarButtonItem:self.navigationPaneBarButtonItem
                                                    animated:NO];
        
        NSString *secondNotificationName = @"UserLoggedOffNotification";
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(hideProfileAfterUserLoggedOff)
         name:secondNotificationName
         object:nil];
        
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
        //self.HUD.delegate = self;
        self.HUD.labelText = @"Loading";
        self.HUD.yOffset = -125.f;
        [self.HUD show:YES];
        
        // allocate a reachability object
        Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
        
        reach.reachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Block Says Reachable");
                deviceIsOnline = YES;
                [self initPieChartOnline];
            });
        };
        
        reach.unreachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Block Says Unreachable");
                deviceIsOnline = NO;
                [self initPieChartOffline];
            });
        };
        
        // tell the reachability that we DONT want to be reachable on 3G/EDGE/CDMA
        // reach.reachableOnWWAN = NO;
        
        // here we set up a NSNotification observer. The Reachability that caused the notification
        // is passed in the object parameter
        /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kReachabilityChangedNotification
                                                   object:nil]; */
        
        [reach startNotifier];
        
        NSLog(@"calling viewDidLoad - Last Week!");
        
    }
}
/*
-(void)reachabilityChanged:(NSNotification*)note {
    Reachability * reach = [note object];
    
    if([reach isReachable])
    {
        NSLog(@"Notification Says Reachable");
    }
    else
    {
        NSLog(@"Notification Says Unreachable");
    }
}
 */

- (void) initPieChartOnline {
    NSLog(@"calling initPieChartOnline!");
    // Prepare Data for the 7-Days-Pie Chart TODO
    
    if ( dayDataDictionary == nil ) {
        /*
         plotData = [[NSMutableArray alloc] initWithObjects:
         [NSNumber numberWithDouble:20.0],
         [NSNumber numberWithDouble:30.0],
         [NSNumber numberWithDouble:60.0],
         nil];
         */
        // Lets look for Week Data in our DB
        NSNumber *numberofentities = [WeekData numberOfEntities];
        
        // We are online
        NSLog(@"deviceIsOnline : %i", deviceIsOnline);
        
        // No Data, our App has been started for the first time
        if ([numberofentities intValue]==0) {
            NSLog(@"No Data in the WeekData Table!");
            [self getWeekData];
        }
        // We have some data, we are online so lets sync
        else {
            NSLog(@"number of entities before sync : %@", numberofentities);
            [WeekData truncateAll];
            [self getWeekData];
        }

    }
    else {
        [self readyToMakePieChart];
    }
}

- (void) initPieChartOffline{
    NSLog(@"calling initPieChart!");
    // Prepare Data for the 7-Days-Pie Chart TODO
    
    if ( dayDataDictionary == nil ) {
        /*
         plotData = [[NSMutableArray alloc] initWithObjects:
         [NSNumber numberWithDouble:20.0],
         [NSNumber numberWithDouble:30.0],
         [NSNumber numberWithDouble:60.0],
         nil];
         */
        // Lets look for Week Data in our DB
        NSNumber *numberofentities = [WeekData numberOfEntities];
        
        // We are offline
        // retrieve the data from the DB
        NSLog(@"deviceIsOnline : %i", deviceIsOnline);
        // ooops, No Data. Show error
        if ([numberofentities intValue]==0) {
            NSLog(@"No Data in the WeekData Table! and the Device is not connected to the internet..");
            
        }
        else {
            [self readyToMakePieChart];
            
        }
        
        /* WeekData *newData = [WeekData createEntity];
         [newData setDay:[NSDate date]];
         [newData setConsumption:(NSDecimalNumber *)[NSDecimalNumber numberWithFloat:2.34f]];
         [[NSManagedObjectContext defaultContext] saveNestedContexts];
         NSArray *result = [WeekData findAllSortedBy:@"day" ascending:YES];
         NSLog(@"TEST, result: %@", result);*/
        
        NSLog(@"initPieChart END-> dayDataDictionary: %@", dayDataDictionary);
    }
    else {
       [self readyToMakePieChart]; 
    }
    
}

-(void)getWeekData {
    NSLog(@"startSynchronization...");

    // Start this first timer immediately, without delay
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimer* firstTimer = [NSTimer timerWithTimeInterval:0.01
                                                      target:self
                                                    selector:@selector(getDataFromServer:)
                                                    userInfo:nil
                                                     repeats:NO];
        
        [[NSRunLoop currentRunLoop] addTimer:firstTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

-(void)readyToMakePieChart {
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    NSArray *results = [WeekData findAllSortedBy:@"day" ascending:YES];
    NSLog(@"readyToMakePieChart -> results: %@", results);
    WeekData *weekdata = [results objectAtIndex:0];
    NSLog(@"readyToMakePieChart -> first: %@", [weekdata day]);
    dayDataDictionary = [[NSMutableDictionary alloc] init];
    plotDataConsumption = [[NSMutableArray alloc] init];
    plotDataDates = [[NSMutableArray alloc] init];
    
    for (WeekData *weekdata in results){
        [dayDataDictionary setObject:[weekdata day] forKey:[weekdata consumption]]; //NSMutableDictionary is unordered
        [plotDataConsumption addObject:[weekdata consumption]];
        [plotDataDates addObject:[weekdata day]];
    }
    NSRange r;
    r.location = 7;
    r.length = [plotDataConsumption count]-7;
    [plotDataConsumption removeObjectsInRange:r]; // delete the last 7 days
    
    [self createPieChart];
    
    NSLog(@"readyToMakePieChart -> dayDataDictionary: %@", dayDataDictionary);
    NSLog(@"readyToMakePieChart -> plotDataConsumption: %@", plotDataConsumption);
    NSLog(@"readyToMakePieChart -> plotDataDates: %@", plotDataDates);
}

- (void)getDataFromServer:(NSTimer *)timer {
    
    NSLog(@"getDataFromServer...");
    //Get user's aggregated kilowatt values per day (max 14 days, semicolon separated, latest first).
    [[AFAppDotNetAPIClient sharedClient] getPath:@"rpc.php?userID=3&action=get&what=aggregation_d" parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, id data) {
                                             NSString *oneWeekData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                             NSArray *components   = [oneWeekData componentsSeparatedByString:@";"];
                                             
                                             for (NSString *obj in components) {
                                                 NSArray *day = [obj componentsSeparatedByString:@"="];
                                                 NSLog(@"day : %@", day);
                                                 NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                                                 [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                                                 [dateFormatter setDateFormat:@"yy-MM-dd"];
                                                 NSDate *date = [dateFormatter dateFromString:[day objectAtIndex:0]];
                                                 NSString *withoutComma = [[day objectAtIndex:1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                                                 double temp = [withoutComma doubleValue];
                                                 NSDecimalNumber *dayConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                                                 NSLog(@"dayConsumption : %@", dayConsumption);

                                                 WeekData *newData = [WeekData createEntity];
                                                 [newData setDay:date];
                                                 [newData setConsumption:dayConsumption];

                                             }

                                             [[NSManagedObjectContext defaultContext] saveNestedContexts];
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 //[MBProgressHUD hideHUDForView:self.view animated:YES];
                                                 [self readyToMakePieChart];
                                             });

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed during getting 7-Weeks-Data: %@",[error localizedDescription]);
    }];
    

    
}

-(void)createPieChart
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = self.graphHostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(self.graphHostingView.bounds);
#endif
    
    
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    self.graphHostingView.hostedGraph = self.graph;
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    self.graph.delegate = self;
    
    
    self.graph.title = @"Pie Chart";
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color                = [CPTColor grayColor];
    textStyle.fontName             = @"Helvetica-Bold";
    textStyle.fontSize             = bounds.size.height / 20.0f;
    self.graph.titleTextStyle           = textStyle;
    self.graph.titleDisplacement        = CGPointMake(0.0f, bounds.size.height / 18.0f);
    self.graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    // Graph padding
    float boundsPadding = bounds.size.width / 20.0f;
    self.graph.paddingLeft   = boundsPadding;
    self.graph.paddingTop    = self.graph.titleDisplacement.y * 2;
    self.graph.paddingRight  = boundsPadding;
    self.graph.paddingBottom = boundsPadding;
    
    self.graph.axisSet = nil;
    
    CPTMutableLineStyle *whiteLineStyle = [CPTMutableLineStyle lineStyle];
    whiteLineStyle.lineColor = [CPTColor whiteColor];
    
    CPTMutableShadow *whiteShadow = [CPTMutableShadow shadow];
    whiteShadow.shadowOffset     = CGSizeMake(2.0, -4.0);
    whiteShadow.shadowBlurRadius = 4.0;
    whiteShadow.shadowColor      = [[CPTColor whiteColor] colorWithAlphaComponent:0.25];
    
    // Add pie chart
    /*piePlot = [[CPTPieChart alloc] init];
     piePlot.dataSource = self;
     piePlot.pieRadius  = MIN(0.7 * (layerHostingView.frame.size.height - 2 * graph.paddingLeft) / 2.0,
     0.7 * (layerHostingView.frame.size.width - 2 * graph.paddingTop) / 2.0);
     CGFloat innerRadius = piePlot.pieRadius / 2.0;
     piePlot.pieInnerRadius  = innerRadius + 5.0;
     piePlot.identifier      = outerChartName;
     piePlot.borderLineStyle = whiteLineStyle;
     piePlot.startAngle      = M_PI_4;
     piePlot.endAngle        = 3.0 * M_PI_4;
     piePlot.sliceDirection  = CPTPieDirectionCounterClockwise;
     piePlot.shadow          = whiteShadow;
     piePlot.delegate        = self;
     
     [graph addPlot:piePlot];
     [piePlot release];*/
    
    // Overlay gradient for pie chart
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
    overlayGradient.gradientType = CPTGradientTypeRadial;
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.0];
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.3] atPosition:0.9];
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.7] atPosition:1.0];
    
    
    
    // Add another pie chart
    piePlot                 = [[CPTPieChart alloc] init];
    piePlot.dataSource      = self;
    piePlot.pieRadius  = MIN(0.7 * (self.graphHostingView.frame.size.height - 2 * self.graph.paddingLeft) / 2.0,
                             0.7 * (self.graphHostingView.frame.size.width - 2 * self.graph.paddingTop) / 2.0);
    piePlot.identifier      = pieChartName;
    piePlot.borderLineStyle = whiteLineStyle;
    piePlot.startAngle      = M_PI_4;
    piePlot.sliceDirection  = CPTPieDirectionClockwise;
    piePlot.shadow          = whiteShadow;
    piePlot.delegate        = self;
    piePlot.plotSpace.delegate = self;
    piePlot.plotSpace.allowsUserInteraction = YES;
    piePlot.overlayFill    = [CPTFill fillWithGradient:overlayGradient];
    [self.graph addPlot:piePlot];
    
    selecting = FALSE;
    repeatingTouch = FALSE;
    currentSliceIndex = 999;
}

-(void)pieChart:(CPTPieChart *)plot sliceWasSelectedAtRecordIndex:(NSUInteger)index
{
    NSLog(@"%@ slice was selected at index %lu. Value = %@", plot.identifier, (unsigned long)index, [plotDataConsumption objectAtIndex:index]);
    
    selecting = TRUE;
    if (currentSliceIndex==index && !repeatingTouch) {
        repeatingTouch = YES;
    }
    else {
        repeatingTouch = NO;
    }
    currentSliceIndex = index;
    
    //[self radialOffsetForPieChart:plot recordIndex:index];
    
    [plot reloadData];
    
    [plot setNeedsDisplay];
    
    /*CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.duration = 1.0f;
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
    [piePlot addAnimation:fadeInAnimation forKey:@"animateOpacity"];*/
    
    
    /*CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"startAngle"];
     
     rotation.removedOnCompletion = NO;
     
     rotation.fillMode = kCAFillModeForwards;
     
     rotation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
     
     rotation.delegate = self;
     
     rotation.fromValue = [NSNumber numberWithFloat:M_PI_4];
     
     rotation.toValue = [NSNumber numberWithFloat:M_PI_4+0.5];
     
     rotation.duration = 0.5f;
     
     [plot addAnimation:rotation forKey:@"start_angle"];*/
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    
    CPTFill *sector=[[CPTFill alloc]init];
    UIColor *color1 = [UIColor clearColor];
    UIColor *color2 =[UIColor clearColor];
    
    if (index==currentSliceIndex) {
        color1 = [UIColor colorWithRed:35/255.0f green:82/255.0f blue:0/255.0f alpha:1.0f];
        color2 = [UIColor colorWithRed:35/255.0f green:205/255.0f blue:0/255.0f alpha:1.0f];
        
    }
    else {
        color1=[UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0];
        color2=[UIColor colorWithRed:0.0 green:0.1 blue:0.2 alpha:1.0];
    }
    
    //filling with gradient color with CPTColor
    CPTGradient *areaGradientUI = [CPTGradient gradientWithBeginningColor:(CPTColor *)color1 endingColor:(CPTColor *)color2];
    
    areaGradientUI.gradientType = CPTGradientTypeAxial;
    
    //sector=[CPTFill fillWithGradient:areaGradientUI];
    
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
    overlayGradient.gradientType = CPTGradientTypeRadial;
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor redColor] colorWithAlphaComponent:0.5] atPosition:0.0];
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor greenColor] colorWithAlphaComponent:0.9] atPosition:0.3];
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor greenColor] colorWithAlphaComponent:0.9] atPosition:0.5];
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor blueColor] colorWithAlphaComponent:0.6] atPosition:0.8];
    
    sector=[CPTFill fillWithGradient:overlayGradient];
    
    return sector;
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSLog(@"[plotDataConsumption count]: %i", [plotDataConsumption count]);
    return [plotDataConsumption count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num;
    
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        num = [plotDataConsumption objectAtIndex:index];
    }
    else {
        return [NSNumber numberWithInt:index];
    }
    
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    static CPTMutableTextStyle *whiteText = nil;
    
    CPTTextLayer *newLayer = nil;
    
    if ( [(NSString *)plot.identifier isEqualToString:pieChartName] ) {
        if ( !whiteText ) {
            whiteText       = [[CPTMutableTextStyle alloc] init];
            whiteText.color = [CPTColor whiteColor];
        }
        
        newLayer                 = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", [[plotDataConsumption objectAtIndex:index] floatValue]] style:whiteText];
        newLayer.fill            = [CPTFill fillWithColor:[CPTColor darkGrayColor]];
        newLayer.cornerRadius    = 5.0;
        newLayer.paddingLeft     = 3.0;
        newLayer.paddingTop      = 3.0;
        newLayer.paddingRight    = 3.0;
        newLayer.paddingBottom   = 3.0;
        newLayer.borderLineStyle = [CPTLineStyle lineStyle];
    }
    
    return newLayer;
}

/** @brief @optional Offsets the slice radially from the center point. Can be used to @quote{explode} the chart.
 *  This method will not be called if
 *  @link CPTPieChartDataSource::radialOffsetsForPieChart:recordIndexRange: -radialOffsetsForPieChart:recordIndexRange: @endlink
 *  is also implemented in the datasource.
 *  @param pieChart The pie chart.
 *  @param idx The data index of interest.
 *  @return The radial offset in view coordinates. Zero is no offset.
 **/
-(CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    CGFloat result = 0.0;
    
    NSLog(@"radialOffsetForPieChart: recordIndex %i, currentSliceIndex %i, selecting %i, repeatingTouch %i", index, currentSliceIndex, selecting, repeatingTouch);
    
    if ( [(NSString *)pieChart.identifier isEqualToString:pieChartName] && selecting && index==currentSliceIndex) {
        result = 20.0;
        if (repeatingTouch) {
            result = 0.0;
        }
    }
    return result;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
//    NSLog(@"rightBarButtonItems: %@", [self.navigationBar.topItem rightBarButtonItems]);
//    NSLog(@"navigationBarItems: %@", navigationBarItems);
//    NSLog(@"self.profileBarButtonItem: %@", self.profileBarButtonItem);
    // Going back
    [[self.splitViewController.viewControllers objectAtIndex:0]popToRootViewControllerAnimated:TRUE];
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    FirstDetailViewController *startDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
    detailViewManager.detailViewController = startDetailViewController;
    startDetailViewController.navigationBar.topItem.title = @"Summary";
    
}

@end
