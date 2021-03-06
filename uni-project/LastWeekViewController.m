//
//  LastWeekViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "LastWeekViewController.h"
#import "DetailViewManager.h"
#import "FirstDetailViewController.h"
#import "MBProgressHUD.h"
#import "EMNetworkManager.h"
#import "WeekData.h"
#import "Reachability.h"
#import "CPTAnimationPeriod.h"

static NSString *const pieChartName = @"7DaysPieChart";
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface LastWeekViewController ()

@property (strong, nonatomic) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (strong, nonatomic) IBOutlet UILabel *consumptionMonthLabel;
@property (strong, nonatomic) IBOutlet UILabel *dayNameLabel;

@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, assign) CGPoint lastLocation;
@property (nonatomic, strong) CPTPieChart *piePlot;
@property (nonatomic, assign) BOOL selecting;
@property (nonatomic, assign) BOOL repeatingTouch;
@property (nonatomic, assign) BOOL firstTime;
@property (nonatomic, assign) BOOL deviceIsOnline;
@property (nonatomic, assign) BOOL newDataSuccess;
@property (nonatomic, assign) NSUInteger currentSliceIndex;
@property (nonatomic, strong) NSMutableDictionary *dayDataDictionary;
@property (nonatomic, strong) MBProgressHUD *permanentHud;

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
        
        self.dayNameLabel.text = @" ";
        self.consumptionMonthLabel.text = @" ";
        self.newDataSuccess = NO;
        //self.graphHostingView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"mainViewHistoryBackg.png"]];
        self.mainView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"mainHistotyViewBG.png"]];
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
        //self.HUD.delegate = self;
        self.HUD.labelText = @"Loading";
        self.HUD.yOffset = -125.f;
        [self.HUD show:YES];
        
        self.firstTime = YES;
        
        // allocate a reachability object
        Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
        
        reach.reachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                DLog(@"Block Says Reachable");
                self.deviceIsOnline = YES;
                [self initPieChartOnline];
            });
        };
        
        reach.unreachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                DLog(@"Block Says Unreachable");
                self.deviceIsOnline = NO;
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
        
        DLog(@"calling viewDidLoad - Last Week!");
        
    }
}
/*
 -(void)reachabilityChanged:(NSNotification*)note {
 Reachability * reach = [note object];
 
 if([reach isReachable])
 {
 DLog(@"Notification Says Reachable");
 }
 else
 {
 DLog(@"Notification Says Unreachable");
 }
 }
 */

- (void) initPieChartOnline {
    DLog(@"calling initPieChartOnline!");
    // Prepare Data for the 7-Days-Pie Chart TODO
    
    if (self.permanentHud) {
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self.permanentHud removeFromSuperview];
        self.permanentHud = nil;
    }
    
    if ( self.dayDataDictionary == nil ) {
        /*
         plotData = [[NSMutableArray alloc] initWithObjects:
         [NSNumber numberWithDouble:20.0],
         [NSNumber numberWithDouble:30.0],
         [NSNumber numberWithDouble:60.0],
         nil];
         */
        // Lets look for Week Data in our DB
        
        // We are online
        DLog(@"deviceIsOnline : %i", self.deviceIsOnline);
        
        // No Data, our App has been started for the first time
        if ([WeekData countOfEntities]==0) {
            DLog(@"No Data in the WeekData Table!");
            [self getWeekData];
        }
        // We have some data, we are online so lets sync
        else {
            DLog(@"number of entities before sync : %i", [WeekData countOfEntities]);
            //[WeekData truncateAll];
            [self getWeekData];
        }
        
    }
    else {
        [self readyToMakePieChart];
    }
    
}

- (void) initPieChartOffline{
    DLog(@"calling initPieChart!");
    // Prepare Data for the 7-Days-Pie Chart TODO
    
    if ( self.dayDataDictionary == nil ) {
        /*
         plotData = [[NSMutableArray alloc] initWithObjects:
         [NSNumber numberWithDouble:20.0],
         [NSNumber numberWithDouble:30.0],
         [NSNumber numberWithDouble:60.0],
         nil];
         */
        // Lets look for Week Data in our DB
        // We are offline
        // retrieve the data from the DB
        DLog(@"deviceIsOnline : %i", self.deviceIsOnline);
        // ooops, No Data. Show error message
        if ([WeekData countOfEntities]==0) {
            if (self.HUD) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [self.HUD removeFromSuperview];
                self.HUD = nil;
            }
            DLog(@"No Data in the WeekData Table! and the Device is not connected to the internet..");
            self.permanentHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            // Configure for text only and offset down
            self.permanentHud.labelText = @"Keine Daten vorhanden";
            self.permanentHud.detailsLabelText = @"Bitte überprüfen Sie Ihre Internetverbindung";
            self.permanentHud.square = YES;
            self.permanentHud.mode = MBProgressHUDModeText;
            self.permanentHud.margin = 10.f;
            self.permanentHud.yOffset = 20.f;
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self readyToMakePieChart];
            });
        }
        
        /* WeekData *newData = [WeekData createEntity];
         [newData setDay:[NSDate date]];
         [newData setConsumption:(NSDecimalNumber *)[NSDecimalNumber numberWithFloat:2.34f]];
         [[NSManagedObjectContext defaultContext] saveNestedContexts];
         NSArray *result = [WeekData findAllSortedBy:@"day" ascending:YES];
         DLog(@"TEST, result: %@", result);*/
        
        [self.piePlot reloadData];
        
        DLog(@"initPieChart END-> dayDataDictionary: %@", self.dayDataDictionary);
    }
    else {
        [self readyToMakePieChart];
    }
    
}

-(void)getWeekData {
    DLog(@"startSynchronization...");
    
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
    DLog(@"readyToMakePieChart -> results: %@", results);
    WeekData *weekdata = results[0];
    DLog(@"readyToMakePieChart -> first: %@", [weekdata day]);
    self.dayDataDictionary = [[NSMutableDictionary alloc] init];
    plotDataConsumption = [[NSMutableArray alloc] init];
    plotDataDates = [[NSMutableArray alloc] init];
    
    for (WeekData *weekdata in results){
        self.dayDataDictionary[[weekdata consumption]] = [weekdata day]; //NSMutableDictionary is unordered
        [plotDataConsumption addObject:[weekdata consumption]];
        [plotDataDates addObject:[weekdata day]];
        DLog(@"adding [weekdata day]: %@", [weekdata day]);
    }
    if (USEDUMMYDATA == NO || self.newDataSuccess) {
        [plotDataConsumption removeObjectsInRange:NSMakeRange(0, 7)]; // delete the first 7 days
        [plotDataDates removeObjectsInRange:NSMakeRange(0, 7)]; // start at position 0, length = 7
    }
    DLog(@"readyToMakePieChart -> plotDataDates: %@", plotDataDates);
    [self calculateColorValuesForDays];
    [self createPieChart];
    
    DLog(@"readyToMakePieChart -> dayDataDictionary: %@", self.dayDataDictionary);
    DLog(@"readyToMakePieChart -> plotDataConsumption: %@", plotDataConsumption);
    
}

- (void)getDataFromServer:(NSTimer *)timer {
    
    DLog(@"getDataFromServer...");
    //Get user's aggregated kilowatt values per day (max 14 days, semicolon separated, latest first).
    // userID should be set by the user! TODO
    NSString *getPath = @"rpc.php?userID=";
    getPath = [getPath stringByAppendingString: [NSString stringWithFormat:@"%i", MySensorID] ];
    getPath = [getPath stringByAppendingString:@"&action=get&what=aggregation_d"];
    [[EMNetworkManager sharedClient] getPath:getPath parameters:nil
                                     success:^(AFHTTPRequestOperation *operation, id data) {
                                         self.newDataSuccess = YES;
                                         [WeekData truncateAll];
                                         NSString *oneWeekData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                         NSArray *components   = [oneWeekData componentsSeparatedByString:@";"];
                                         
                                         for (NSString *obj in components) {
                                             
                                             NSArray *day = [obj componentsSeparatedByString:@"="];
                                             DLog(@"day : %@", day);
                                             NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                                             [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                                             [dateFormatter setDateFormat:@"yy-MM-dd"];
                                             NSDate *date = [dateFormatter dateFromString:day[0]];
                                             NSString *withoutComma = [day[1] stringByReplacingOccurrencesOfString:@"," withString:@"."];
                                             double temp = [withoutComma doubleValue];
                                             NSDecimalNumber *dayConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                                             DLog(@"dayConsumption : %@", dayConsumption);
                                             
                                             WeekData *newData = [WeekData createEntity];
                                             [newData setDay:date];
                                             [newData setConsumption:dayConsumption];
                                             
                                         }
                                         
                                         [[NSManagedObjectContext defaultContext] saveNestedContexts];
                                         
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [self readyToMakePieChart];
                                         });
                                         
                                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         DLog(@"Failed during getting 7-Weeks-Data: %@",[error localizedDescription]);
                                         if (USEDUMMYDATA)
                                         {
                                             [WeekData truncateAll]; // OK, Lets remove all old DB-Objects and generate new ones..
                                                                     // create 7 Dummy WeekData Objects
                                             for (int i=0; i<7; i++) {
                                                 
                                                 NSDateComponents *componentsToSubtract = [[NSDateComponents alloc] init];
                                                 [componentsToSubtract setDay:(-i-1)];
                                                 
                                                 NSDate *day = [[NSCalendar currentCalendar] dateByAddingComponents:componentsToSubtract toDate:[NSDate date] options:0];
                                                 WeekData *newData = [WeekData createEntity];
                                                 [newData setDay:day];
                                                 [newData setConsumption:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:(double)(arc4random() % 51 * 0.1)+0.6]];
                                                 
                                             }
                                             [[NSManagedObjectContext defaultContext] saveNestedContexts];
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self readyToMakePieChart];
                                             });
                                         }
                                         else
                                         {
                                             self.deviceIsOnline = NO;
                                             [self initPieChartOffline];
                                         }
                                     }];
    
    
    
}

-(void)createPieChart
{
    CGRect bounds = self.graphHostingView.bounds;
    
    DLog(@"__calling createPieChart");
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    self.graphHostingView.hostedGraph = self.graph;
    //[self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    
    self.graph.delegate = self;
    
    self.graph.title = @"";
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color                = [CPTColor grayColor];
    textStyle.fontName             = @"Helvetica-Bold";
    textStyle.fontSize             = bounds.size.height / 20.0f;
    self.graph.titleTextStyle           = textStyle;
    self.graph.titleDisplacement        = CGPointMake(0.0f, bounds.size.height / 18.0f);
    self.graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    // Graph padding
    float boundsPadding = bounds.size.width / 30.0f;
    self.graph.paddingLeft   = boundsPadding;
    self.graph.paddingTop    = boundsPadding; //self.graph.titleDisplacement.y * 2;
    self.graph.paddingRight  = boundsPadding;
    self.graph.paddingBottom = boundsPadding;
    
    self.graph.axisSet = nil;
    
    CPTMutableLineStyle *whiteLineStyle = [CPTMutableLineStyle lineStyle];
    whiteLineStyle.lineColor = [CPTColor whiteColor];
    
    CPTMutableShadow *greenShadow = [CPTMutableShadow shadow];
    greenShadow.shadowOffset     = CGSizeMake(2.0, -4.0);
    greenShadow.shadowBlurRadius = 4.0;
    greenShadow.shadowColor      = [CPTColor blackColor];
    
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
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.2] atPosition:0.9];
    overlayGradient              = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.5] atPosition:1.0];
    
    // Add pie chart
    self.piePlot                 = [[CPTPieChart alloc] init];
    self.piePlot.dataSource      = self;
    CGFloat radius  = MIN(0.7 * (self.graphHostingView.frame.size.height - 2 * self.graph.paddingLeft) / 2.0,
                          0.7 * (self.graphHostingView.frame.size.width - 2 * self.graph.paddingTop) / 2.0);
    self.piePlot.pieRadius       = 0.0;
    self.piePlot.identifier      = pieChartName;
    self.piePlot.borderLineStyle = whiteLineStyle;
    self.piePlot.startAngle      = M_PI_4;
    self.piePlot.sliceDirection  = CPTPieDirectionClockwise;
    self.piePlot.shadow          = greenShadow;
    self.piePlot.delegate        = self;
    self.piePlot.plotSpace.delegate = self;
    self.piePlot.plotSpace.allowsUserInteraction = YES;
    self.piePlot.overlayFill    = [CPTFill fillWithGradient:overlayGradient];
    [self.graph addPlot:self.piePlot];
    
    
    [CPTAnimation animate:self.piePlot
                 property:@"pieRadius"
                     from:0.0
                       to:radius
                 duration:0.5
                withDelay:0.1
           animationCurve:CPTAnimationCurveBounceOut
                 delegate:nil];
    
    DLog(@"createPieChart: graph: %@, piePlot: %@", self.graph, self.piePlot);
    
    self.selecting = FALSE;
    self.repeatingTouch = FALSE;
    self.currentSliceIndex = 999;
}

-(void)selectSliceOnFirstLaunch {
    DLog(@"calling selectSliceOnFirstLaunch");
    /*selecting = TRUE;
     repeatingTouch = NO;
     firstTime = NO;
     NSUInteger index = [plotDataConsumption count]-1;
     currentSliceIndex = index;
     DLog(@"selectSliceOnFirstLaunch: graph: %@, piePlot: %@", self.graph, piePlot);
     [piePlot reloadData];
     
     [piePlot setNeedsDisplay];*/
    self.firstTime = NO;
    int64_t delayInSeconds = 1.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self pieChart:self.piePlot sliceWasSelectedAtRecordIndex:[plotDataConsumption count]-1];
    });
    
}

-(void)pieChart:(CPTPieChart *)plot sliceWasSelectedAtRecordIndex:(NSUInteger)index
{
    DLog(@"%@ slice was selected at index %lu. Value = %@", plot.identifier, (unsigned long)index, plotDataConsumption[index]);
    
    self.selecting = TRUE;
    if (self.currentSliceIndex==index && !self.repeatingTouch) {
        self.repeatingTouch = YES;
    }
    else {
        self.repeatingTouch = NO;
    }
    self.currentSliceIndex = index;
    
    //NSDate *dayDate = [dayDataDictionary objectForKey:[plotDataConsumption objectAtIndex:index]];
    NSDate *dayDate = plotDataDates[index];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    [formatter setDateFormat:@"EEEE, dd.MM.yy"];
    NSLocale *deLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
    formatter.locale = deLocale;
    NSString *dayNameLong = [formatter stringFromDate:dayDate];
    self.dayNameLabel.text = dayNameLong;
    NSString *consumptionAndKwh = [[NSString alloc] initWithString:[plotDataConsumption[index] stringValue]];
    consumptionAndKwh = [consumptionAndKwh stringByAppendingString:@" kWh"];
    self.consumptionMonthLabel.text = consumptionAndKwh;
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
    
    DLog(@"calling sliceFillForPieChart: %@", pieChart);
    
    CPTFill *sector = [[CPTFill alloc] init];
    
    /*
     UIColor *color1;
     UIColor *color2;
     
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
     
     */
    //CPTColor *startColor = [CPTColor colorWithComponentRed:1/255.0f green:56/255.0f blue:1/255.0f alpha:1.0f];
    //CPTColor *endColor = [CPTColor colorWithComponentRed:2/255.0f green:96/255.0f blue:2/255.0f alpha:1.0f];
    //CPTGradient *areaGradientUI = [CPTGradient gradientWithBeginningColor:startColor
    //                                                         endingColor:endColor];
    //sector=[CPTFill fillWithGradient:areaGradientUI];
    NSNumber *consumption = plotDataConsumption[index];
    DLog(@"consumption: %@", consumption);
    UIColor *sliceColor = (self.daysColors)[[consumption stringValue]];
    DLog(@"sliceColor: %@", sliceColor);
    sector=[CPTFill fillWithColor:(CPTColor *)sliceColor];
    return sector;
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    DLog(@"[plotDataConsumption count]: %i", [plotDataConsumption count]);
    return [plotDataConsumption count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num;
    
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        num = plotDataConsumption[index];
    }
    else {
        DLog(@"numberForPlot returning index = %i", index);
        return [NSNumber numberWithInt:index];
    }
    DLog(@"numberForPlot returning num = %@", num);
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    DLog(@"calling dataLabelForPlot");
    static CPTMutableTextStyle *whiteText = nil;
    
    CPTTextLayer *newLayer = nil;
    
    if ( [(NSString *)plot.identifier isEqualToString:pieChartName] ) {
        if ( !whiteText ) {
            whiteText       = [[CPTMutableTextStyle alloc] init];
            whiteText.color = [CPTColor blackColor];
            whiteText.fontSize = 18.0f;
        }
        //NSDate *dayDate = [dayDataDictionary objectForKey:[plotDataConsumption objectAtIndex:index]];
        NSDate *dayDate = plotDataDates[index];
        DLog(@"dayDate: %@", dayDate);
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterLongStyle];
        [formatter setDateFormat:@"EE"];
        NSLocale *deLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
        formatter.locale = deLocale;
        NSString *dayNameShort = [formatter stringFromDate:dayDate];
        
        newLayer                 = [[CPTTextLayer alloc] initWithText:dayNameShort style:whiteText];
        newLayer.fill            = [CPTFill fillWithColor:[CPTColor clearColor]];
        //newLayer.cornerRadius    = 5.0;
        newLayer.paddingLeft     = 3.0;
        newLayer.paddingTop      = 3.0;
        newLayer.paddingRight    = 3.0;
        newLayer.paddingBottom   = 3.0;
        //newLayer.borderLineStyle = [CPTLineStyle lineStyle];
    }
    
    return newLayer;
}

/** Offsets the slice radially from the center point. Can be used to @quote{explode} the chart.
 *  This method will not be called if
 *  CPTPieChartDataSource::radialOffsetsForPieChart:recordIndexRange: -radialOffsetsForPieChart:recordIndexRange: @endlink
 *  is also implemented in the datasource.
 *  @param pieChart The pie chart.
 *  @param idx The data index of interest.
 *  @return The radial offset in view coordinates. Zero is no offset.
 **/
-(CGFloat)radialOffsetForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    CGFloat result = 0.0;
    
    DLog(@"radialOffsetForPieChart: recordIndex %i, currentSliceIndex %i, selecting %i, repeatingTouch %i", index, self.currentSliceIndex, self.selecting, self.repeatingTouch);
    
    if ( [(NSString *)pieChart.identifier isEqualToString:pieChartName] && self.selecting && index==self.currentSliceIndex) {
        result = 20.0;
        if (self.repeatingTouch) {
            result = 0.0;
        }
    }
    
    if (index == [plotDataConsumption count]-1 && !self.instanceWasCached && self.firstTime) {
        [self selectSliceOnFirstLaunch];
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
    DLog(@"hideProfileAfterUserLoggedOff...");
    if (self.profilePopover){
        [self.profilePopover dismissPopoverAnimated:YES];
        DLog(@"profile popover dissmissed...");
    }
    [navigationBarItems removeObject:self.profileBarButtonItem];
    [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    //    DLog(@"rightBarButtonItems: %@", [self.navigationBar.topItem rightBarButtonItems]);
    //    DLog(@"navigationBarItems: %@", navigationBarItems);
    //    DLog(@"self.profileBarButtonItem: %@", self.profileBarButtonItem);
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

- (void) calculateColorValuesForDays{
    if (!self.daysColors) {
        self.daysColors = [[NSMutableDictionary alloc] init];
    }
    DLog(@"calculateColorValuesForDays -> plotDataDates: %@", plotDataDates);
    float avgConsumption = 0.0f;
    float specificYearConsumption = 0.0f;
    float daysNumberInYear = 0.0f;
    NSUInteger currentYear = [[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]] year];
    // check for leap year
    if (( (currentYear % 4 == 0) && (currentYear % 100 != 0) ) || (currentYear % 400 == 0)) {
        // Leap year!
        daysNumberInYear = 366.0f;
    }
    else {
        // Normal year!
        daysNumberInYear = 365.0f;
    }
    // Color Management
    for (NSDecimalNumber *dayConsumption in plotDataConsumption) {
        
        avgConsumption = [dayConsumption floatValue] * daysNumberInYear;
        DLog(@"___avgConsumption: %f", avgConsumption);
        specificYearConsumption = avgConsumption/OfficeArea;
        DLog(@"___specificYearConsumption: %f", specificYearConsumption);
        if (specificYearConsumption <= AvgOfficeEnergyConsumption) {
            float redComponent = 255.0f - ((AvgOfficeEnergyConsumption - specificYearConsumption)*(256.0f/AvgOfficeEnergyConsumption));
            if (redComponent < 0.0) {
                redComponent = 0.0;
            }
            UIColor *dayColor = [UIColor colorWithRed:redComponent/255.0f green:1.0f blue:0.0f alpha:0.7f];
            DLog(@"___redComponent: %f", redComponent);
            DLog(@"___redComponent/255: %f", redComponent/255.0f);
            [self.daysColors setValue:dayColor forKey: [dayConsumption stringValue]];
        }
        else {
            float greenComponent = 255.0f - ((specificYearConsumption - AvgOfficeEnergyConsumption)*(256.0f/25.0f));
            if (greenComponent < 0.0) {
                greenComponent = 0.0;
            }
            UIColor *dayColor = [UIColor colorWithRed:1.0f green:greenComponent/255.0f blue:0.0f alpha:0.7f];
            DLog(@"___greenComponent: %f", greenComponent);
            DLog(@"___greenComponent/255: %f", greenComponent/255.0f);
            [self.daysColors setValue:dayColor forKey: [dayConsumption stringValue]];
        }
        
    }
    
}

@end
