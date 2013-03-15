//
//  ScrollViewContentVC.m
//  uni-project
//
//  Created by Pavel Ermolin on 01.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "ScrollViewContentVC.h"
#import "EnergyClockViewController.h"
#import "EnergyClockDataManager.h"
#import "Reachability.h"
#import "EcoMeterAppDelegate.h"
#import "AggregatedDay.h"
#import "CPTAnimationPeriod.h"

static const int firstPageNumber    = 0;
static const int secondPageNumber   = 1;

@interface ScrollViewContentVC ()

// container views for a CPTGraph instances
@property (strong, nonatomic) CPTGraphHostingView *firstPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *secondPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *thirdPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *fourthPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *fifthPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *sixthPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *seventhPieChartView;

@property (strong, nonatomic) CPTXYGraph *firstPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *secondPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *thirdPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *fourthPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *fifthPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *sixthPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *seventhPieChartGraph;

@property (strong, nonatomic) CPTPieChart *firstPieChart;
@property (strong, nonatomic) CPTPieChart *secondPieChart;
@property (strong, nonatomic) CPTPieChart *thirdPieChart;
@property (strong, nonatomic) CPTPieChart *fourthPieChart;
@property (strong, nonatomic) CPTPieChart *fifthPieChart;
@property (strong, nonatomic) CPTPieChart *sixthPieChart;
@property (strong, nonatomic) CPTPieChart *seventhPieChart;

@property (assign, nonatomic) int pageNumber;
@property (weak, nonatomic) UIViewController *targetViewController; //EnergyClockViewController

@property (strong, nonatomic) NSArray *firstPageHostingViews;
@property (strong, nonatomic) NSArray *firstPageGraphs;
@property (strong, nonatomic) NSArray *firstPagePieCharts;

@property (strong, nonatomic) NSArray *secondPageHostingViews;
@property (strong, nonatomic) NSArray *secondPageGraphs;
@property (strong, nonatomic) NSArray *secondPagePieCharts;
@property (strong, nonatomic) NSArray *weekdays;

@property (nonatomic, strong) Reachability *reachabilityObj;
@property (nonatomic, strong) EnergyClockDataManager *ecDataManager;
@property (nonatomic, strong) NSArray *aggrDayObjects; //will be filled with objects from DB
@property (nonatomic, strong) NSMutableDictionary *weekdaysDates; //will be filled with objects from DB

@end

@implementation ScrollViewContentVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithPageNumber:(NSUInteger)page andUIViewController:(UIViewController*)viewController
{
    if (self = [super initWithNibName:nil bundle:nil])
    {
        //NSLog(@"initWithPageNumber: %i", page);
        self.pageNumber = page;
        self.targetViewController = viewController;
        EcoMeterAppDelegate *appDelegate = (EcoMeterAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.deviceIsOnline = appDelegate.deviceIsOnline;
        
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
	// Do any additional setup after loading the view.
    
    [self.reachabilityObj startNotifier];
    
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale: [[NSLocale alloc] initWithLocaleIdentifier:@"de"]]; // [NSLocale currentLocale] would be better ;)
    NSArray *weekdays_temp = [df weekdaySymbols];
    NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    //NSInteger today = componentsToday.weekday;
    NSInteger yesterday = (componentsToday.weekday)-1;
    // last 7 days from today
    self.weekdays = [[weekdays_temp subarrayWithRange:NSMakeRange(yesterday, 7-yesterday)]
                     arrayByAddingObjectsFromArray:[weekdays_temp subarrayWithRange:NSMakeRange(0, yesterday)]];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(initPlotsAfterSavingData) // when the data has been saved we will be notified
     name:AggregatedDaysSaved
     object:nil];
    self.weekdaysDates = [[NSMutableDictionary alloc] init];
    //self.aggrDayObjects = [AggregatedDay findAllSortedBy:@"date" ascending:NO];
    
    NSLog(@"viewDidLoad ScrollViewContent self: %@", self);
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //NSLog(@"viewDidAppear...");
    
    /*  IMPORTANT: CALL THE INITIALIZATION METHOD HERE 
        The plots are initialized here, since the view bounds have not transformed for landscape until now
     */
    // Get last sync date, =today? -> then do nothing!
    NSDateComponents *todayComponents =
    [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
    NSAssert(systemObj!=nil, @"System Object with id=primary doesnt exist");
    NSLog(@"viewDidAppear systemObj: %@", systemObj);
    NSDate *lastSyncDate = systemObj.daysupdated;
    NSLog(@"viewDidAppear lastSyncDate: %@", lastSyncDate);
    NSLog(@"viewDidAppear todayComponents: %@", todayComponents);
    if (lastSyncDate) { // we have synced today already
        NSDateComponents *lastSyncComponents =
        [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:lastSyncDate];
        
        if(([todayComponents year]  == [lastSyncComponents year])  &&
           ([todayComponents month] == [lastSyncComponents month]) &&
           ([todayComponents day]   == [lastSyncComponents day]))
        {
            NSLog(@"viewDidAppear, we synced already");
            // init the AggregatedDay-Objects Array
            self.aggrDayObjects = [AggregatedDay findAllSortedBy:@"date" ascending:NO];
            
            NSDateFormatter * df = [[NSDateFormatter alloc] init];
            [df setLocale: [[NSLocale alloc] initWithLocaleIdentifier:@"de"]]; // [NSLocale currentLocale] would be better ;)
            [df setDateFormat:@"EEEE"];
            NSLog(@"viewDidLoad aggrDayObjects retrieved in ScrollViewContent : %@", self.aggrDayObjects);
            // init the aggrDayObjects-Array
            for (AggregatedDay *obj in self.aggrDayObjects)
            {
                [self.weekdaysDates setObject:obj.date forKey:[df stringFromDate:obj.date]];
            }
            NSLog(@"viewDidLoad weekdaysDates retrieved in ScrollViewContent : %@", self.weekdaysDates);
            /////////////////
            [self initPlots];
            ////////////////
        }
    } 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initPlotsAfterSavingData
{
    NSLog(@"initPlotsAfterSavingData");
    self.aggrDayObjects = [AggregatedDay findAllSortedBy:@"date" ascending:NO]; // the DB is up to date now!
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale: [[NSLocale alloc] initWithLocaleIdentifier:@"de"]]; // [NSLocale currentLocale] would be better ;)
    [df setDateFormat:@"EEEE"];
    
    NSLog(@"initPlotsAfterSavingData aggrDayObjects retrieved in ScrollViewContent : %@", self.aggrDayObjects);
    
    for (AggregatedDay *obj in self.aggrDayObjects)
    {
        [self.weekdaysDates setObject:obj.date forKey:[df stringFromDate:obj.date]];
    }
    [self initPlots];
}

#pragma mark - Lazy instantiation getters
-(NSArray*)firstPageHostingViews
{
    if(!_firstPageHostingViews)
    {
        _firstPageHostingViews = [[NSArray alloc] initWithObjects:
                                  self.firstPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                  self.secondPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                  self.thirdPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                  self.fourthPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init], nil];
    }
    return _firstPageHostingViews;
}

-(NSArray*)secondPageHostingViews
{
    if(!_secondPageHostingViews)
    {
        _secondPageHostingViews = [[NSArray alloc] initWithObjects:
                                   self.fifthPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                   self.sixthPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                   self.seventhPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init], nil];
    }
    return _secondPageHostingViews;
}

-(NSArray*)firstPageGraphs
{
    if(!_firstPageGraphs)
    {
        _firstPageGraphs = [[NSArray alloc] initWithObjects:
                            self.firstPieChartGraph = [[CPTXYGraph alloc] init],
                            self.secondPieChartGraph = [[CPTXYGraph alloc] init],
                            self.thirdPieChartGraph = [[CPTXYGraph alloc] init],
                            self.fourthPieChartGraph = [[CPTXYGraph alloc] init], nil];
    }
    return _firstPageGraphs;
}

-(NSArray*)secondPageGraphs
{
    if(!_secondPageGraphs)
    {
        _secondPageGraphs = [[NSArray alloc] initWithObjects:
                             self.fifthPieChartGraph = [[CPTXYGraph alloc] init],
                             self.sixthPieChartGraph = [[CPTXYGraph alloc] init],
                             self.seventhPieChartGraph = [[CPTXYGraph alloc] init], nil];
    }
    return _secondPageGraphs;
}

-(NSArray*)firstPagePieCharts
{
    if(!_firstPagePieCharts)
    {
        _firstPagePieCharts = [[NSArray alloc] initWithObjects:
                            self.firstPieChart = [[CPTPieChart alloc] init],
                            self.secondPieChart = [[CPTPieChart alloc] init],
                            self.thirdPieChart = [[CPTPieChart alloc] init],
                            self.fourthPieChart = [[CPTPieChart alloc] init], nil];
    }
    return _firstPagePieCharts;
}

-(NSArray*)secondPagePieCharts
{
    if(!_secondPagePieCharts)
    {
        _secondPagePieCharts = [[NSArray alloc] initWithObjects:
                             self.fifthPieChart = [[CPTPieChart alloc] init],
                             self.sixthPieChart = [[CPTPieChart alloc] init],
                             self.seventhPieChart = [[CPTPieChart alloc] init], nil];
    }
    return _secondPagePieCharts;
}

#pragma mark - CPTPlotDataSource methods

// how many slices should be displayed
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    //NSLog(@"numberOfRecordsForPlot...");
    return 2;
}


// Gets a plot data value for the given plot and field.
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    //NSLog(@"numberForPlot, field: %i, recordIndex: %i", fieldEnum, index);
    NSNumber *num = nil;
    NSLog(@"START: numberForPlot... plot: %@, field: %i, recordIndex: %i, pieChart.identifier: %@", plot, fieldEnum, index, plot.identifier);
    NSLog(@"weekdaysDates = %@", self.weekdaysDates);
    // last day comes first
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) { // The field index
        //num = [NSNumber numberWithFloat:(arc4random()%8)+1.0];
        NSLog(@"[self.weekdaysDates objectForKey:plot.identifier] = %@", [self.weekdaysDates objectForKey:plot.identifier]);
        for (NSUInteger i=0; i<[self.aggrDayObjects count]; i++) {
            AggregatedDay *aggday = self.aggrDayObjects[i];
            NSLog(@"aggday.date = %@", aggday.date);
            NSLog(@"[self.weekdaysDates objectForKey:plot.identifier] = %@", [self.weekdaysDates objectForKey:plot.identifier]);
            
            if ([aggday.date compare:[self.weekdaysDates objectForKey:plot.identifier]] == NSOrderedSame) {
                if (index == 0) { // sure? TODO
                    num = [NSNumber numberWithFloat:[aggday.nightconsumption floatValue]];
                    NSLog(@"num 1 = %@", num);
                }
                else if (index == 1) {
                    num = [NSNumber numberWithFloat:[aggday.dayconsumption floatValue]];
                    NSLog(@"num 2 = %@", num);
                }
                
            }
            else if ([self.weekdaysDates objectForKey:plot.identifier] == NULL){
                num = [NSNumber numberWithFloat:(arc4random()%8)+1.0];
                NSLog(@"num 3 = %@", num);
            }
        }
        
    }
    else {
        return [NSNumber numberWithInt:index];
    }
    
    
    NSLog(@"numberForPlot returning num = %@", num);
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    //NSLog(@"dataLabelForPlot...");
    // Define label text style
    static CPTMutableTextStyle *labelText = nil;
    static NSString *labelValue = nil;
    if (!labelText) {
        labelText= [[CPTMutableTextStyle alloc] init];
        labelText.color = [CPTColor blackColor];
    }
    AggregatedDay *ADay = [self.aggrDayObjects objectAtIndex:0];
    if (index == 0) {
        labelValue = ADay.sunrise;
    }
    else if (index == 1){
        labelValue = ADay.sunset;
    }
    // Set up display label
    //NSString *labelValue = @"00:00 h";
    // Create and return layer with label text
    CPTTextLayer *layer =[[CPTTextLayer alloc] initWithText:labelValue style:labelText];
    //layer.paddingRight = 20;
    //layer.position
    //layer.position = CGPointMake(100, 150);
    return layer;
}

-(NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    return @"";
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    
    NSLog(@"calling sliceFillForPieChart: %@", pieChart);
    
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
    CPTColor *fillColor = [[CPTColor alloc] init];
    if (index==0) {
        fillColor = [CPTColor colorWithComponentRed:107/255.0f green:107/255.0f blue:107/255.0f alpha:1.0f];
    }
    else {
        fillColor = [CPTColor colorWithComponentRed:229/255.0f green:229/255.0f blue:229/255.0f alpha:1.0f];
    }
    
    
    sector=[CPTFill fillWithColor:(CPTColor *)fillColor];
    return sector;
}


#pragma mark - Chart behavior
-(void)initPlots
{
    NSLog(@"initPlots...");
    NSArray *days = [AggregatedDay findAllSortedBy:@"date" ascending:YES];
    NSLog(@"number of days from DB: %i", [days count]);
    for (AggregatedDay *day in days) {
        NSLog(@"date: %@, dayconsumption: %@, nightconsumption: %@", day.date, day.dayconsumption, day.nightconsumption);
    }
    [self configureHostViews];
    [self configureGraphs];
    [self configureCharts];
    //[self configureLegend];
}

-(void)configureHostViews
{
    //NSLog(@"configureHostViews...");
    
    EnergyClockViewController *ecViewController = (EnergyClockViewController *)self.targetViewController;
    
    // 1 - Set up view frame
    CGRect parentRect = self.view.bounds;
    CGSize navBarSize = ecViewController.navigationBar.bounds.size;
    parentRect = CGRectMake(parentRect.origin.x,
                            parentRect.origin.y, //+ navBarSize.height
                            navBarSize.width/4,
                            (ecViewController.scrollView.bounds.size.height));
    
    // 2 - Create host views according to current page
    NSMutableArray *pageHostingViewsMutable = [[NSMutableArray alloc] init];
    
    if(self.pageNumber == firstPageNumber)
    {
        pageHostingViewsMutable = [self.firstPageHostingViews mutableCopy];
    }
    else if(self.pageNumber == secondPageNumber)
    {
        pageHostingViewsMutable = [self.secondPageHostingViews mutableCopy];
    }
    //NSLog(@"self.secondPageHostingViews: %@", self.secondPageHostingViews);
    //NSLog(@"firstPageHostingViews: %@", self.firstPageHostingViews);
    //NSLog(@"pagenumber: %i", self.pageNumber);
    NSAssert([pageHostingViewsMutable count]>0, @"pageHostingViewsMutable is empty");
    
    for (int i=0; i<[pageHostingViewsMutable count]; i++) {
        CPTGraphHostingView *hostingView = pageHostingViewsMutable[i];
        hostingView.frame = parentRect;
        parentRect.origin.x += 170.0f;
        hostingView.allowPinchScaling = NO;
        hostingView.backgroundColor =
        //[UIColor colorWithRed:(arc4random()%11*0.1) green:(arc4random()%11*0.1) blue:(arc4random()%11*0.1) alpha:0.8]; // TEST
        [UIColor clearColor];
        pageHostingViewsMutable[i] = hostingView;
    }
    
    if(self.pageNumber == firstPageNumber)
    {
        self.firstPageHostingViews = pageHostingViewsMutable; // put back
        for (CPTGraphHostingView *hostView in self.firstPageHostingViews)
        {
            [self.view addSubview:hostView];
        }
    }
    else if(self.pageNumber == secondPageNumber)
    {
        self.secondPageHostingViews = pageHostingViewsMutable;
        for (CPTGraphHostingView *hostView in self.secondPageHostingViews)
        {
            [self.view addSubview:hostView];
        }
    }
    
}

-(void)configureGraphs
{
    NSLog(@"configureGraphs...");
    
    NSMutableArray *pageHostingViewsMutable = [[NSMutableArray alloc] init];
    NSMutableArray *pageGraphsMutable       = [[NSMutableArray alloc] init];
    
    if(self.pageNumber == firstPageNumber)
    {
        pageHostingViewsMutable = [self.firstPageHostingViews mutableCopy];
        pageGraphsMutable       = [self.firstPageGraphs mutableCopy];
    }
    else if(self.pageNumber == secondPageNumber)
    {
        pageHostingViewsMutable = [self.secondPageHostingViews mutableCopy];
        pageGraphsMutable       = [self.secondPageGraphs mutableCopy];
    }
    
    for (int i=0; i<[pageGraphsMutable count]; i++) {
        CPTGraphHostingView *hostingView = pageHostingViewsMutable[i];
        CPTXYGraph *graph = pageGraphsMutable[i];
        graph.frame = hostingView.bounds;
        graph.delegate = self;
        graph.paddingLeft = 0.0f;
        graph.paddingTop = 0.0f;
        graph.paddingRight = 0.0f;
        graph.paddingBottom = 0.0f;
        graph.axisSet = nil;
        if (self.pageNumber == 1) {
            graph.title = self.weekdays[i+4];
        }
        else {
            graph.title = self.weekdays[i];
        }
        NSLog(@"configureGraphs, setting title: %@", graph.title);
        CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
        textStyle.color                = [CPTColor grayColor];
        textStyle.fontName             = @"Helvetica-Bold";
        textStyle.fontSize             = 15.0f;
        graph.titleTextStyle           = textStyle;
        graph.titleDisplacement        = CGPointMake(0.0f, -12.0f);
        graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
        pageGraphsMutable[i] = graph;
        hostingView.hostedGraph = graph;
        pageHostingViewsMutable[i] = hostingView;
    }
    
    if(self.pageNumber == firstPageNumber)
    {
        self.firstPageHostingViews = pageHostingViewsMutable; // put back
        self.firstPageGraphs = pageGraphsMutable;
    }
    else if(self.pageNumber == secondPageNumber)
    {
        self.secondPageHostingViews = pageHostingViewsMutable;
        self.secondPageGraphs = pageGraphsMutable;
    }
    
}

-(void)configureCharts
{
    
    //NSLog(@"configureCharts...");
    bool animated = YES;
    
    NSMutableArray *pageHostingViewsMutable = [[NSMutableArray alloc] init];
    NSMutableArray *pageGraphsMutable       = [[NSMutableArray alloc] init];
    NSMutableArray *pieChartsMutable        = [[NSMutableArray alloc] init];
    
    if(self.pageNumber == firstPageNumber)
    {
        pageHostingViewsMutable = [self.firstPageHostingViews mutableCopy];
        pageGraphsMutable       = [self.firstPageGraphs mutableCopy];
        pieChartsMutable        = [self.firstPagePieCharts mutableCopy];
    }
    else if(self.pageNumber == secondPageNumber)
    {
        pageHostingViewsMutable = [self.secondPageHostingViews mutableCopy];
        pageGraphsMutable       = [self.secondPageGraphs mutableCopy];
        pieChartsMutable        = [self.secondPagePieCharts mutableCopy];
    }
    
    for (int i=0; i<[pieChartsMutable count]; i++) {
        CPTGraphHostingView *hostingView = pageHostingViewsMutable[i];
        CPTGraph *graph = hostingView.hostedGraph;
        CPTPieChart *pieChart = pieChartsMutable[i];
        pieChart.dataSource = self;
        pieChart.delegate = self;
        pieChart.plotSpace.delegate = self;
        pieChart.plotSpace.allowsUserInteraction = YES;
        //pieChart.pieRadius = (hostingView.bounds.size.height * 0.7) / 2;
        pieChart.pieRadius = animated ? 0.0 : ((hostingView.bounds.size.height * 0.7) / 2);
        pieChart.identifier = graph.title;
        pieChart.startAngle = -M_PI_4;
        //pieChart.startAngle = animated ? -M_PI_2 : M_PI_4;
        //pieChart.endAngle = animated ? M_PI_2 : 3.0 * M_PI_4;
        pieChart.sliceDirection = CPTPieDirectionClockwise;
        
        //pieChart.labelRotationRelativeToRadius = YES;
        //pieChart.labelRotation                 = -M_PI_2;
        pieChart.labelOffset                   = -5.0;
        //pieChart.labelRotation = M_PI_4;
        
        
        // Create gradient
        CPTGradient *overlayGradient = [[CPTGradient alloc] init];
        overlayGradient.gradientType = CPTGradientTypeRadial;
        overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.9];
        overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.4] atPosition:1.0];
        pieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
        pieChartsMutable[i] = pieChart;
        // Add chart to graph
        [graph addPlot:pieChart];
        
        if ( animated ) {
            /*[CPTAnimation animate:pieChart
                         property:@"startAngle"
                             from:-M_PI_2
                               to:M_PI_2
                         duration:0.25];
            [CPTAnimation animate:pieChart
                         property:@"endAngle"
                             from:M_PI_2
                               to:[pieChart medianAngleForPieSliceIndex: 1]
                         duration:0.25]; */
        }
        
        if ( animated ) {
            [CPTAnimation animate:pieChart
                         property:@"pieRadius"
                             from:0.0
                               to:((hostingView.bounds.size.height * 0.7) / 2)
                         duration:0.5
                        withDelay:0.1
                   animationCurve:CPTAnimationCurveBounceOut
                         delegate:nil];
        }
        
    }
    
    if(self.pageNumber == firstPageNumber)
    {
        self.firstPagePieCharts = pieChartsMutable;
    }
    else if(self.pageNumber == secondPageNumber)
    {
        self.secondPagePieCharts = pieChartsMutable;
    }
    
}

-(void)configureLegend
{
    
}

@end
