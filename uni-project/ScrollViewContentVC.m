//
//  ScrollViewContentVC.m
//  uni-project
//
//  Created by Pavel Ermolin on 01.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "ScrollViewContentVC.h"
#import "EnergyClockViewController.h"

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
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSDateFormatter * df = [[NSDateFormatter alloc] init];
    [df setLocale: [[NSLocale alloc] initWithLocaleIdentifier:@"de"]]; // [NSLocale currentLocale] would be better ;)
    NSArray *weekdays_temp = [df weekdaySymbols];
    NSDateComponents *componentsToday = [[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
    NSInteger today = componentsToday.weekday;
    NSInteger yesterday = today-1;
    // last 7 days from today
    self.weekdays = [[weekdays_temp subarrayWithRange:NSMakeRange(yesterday, 7-yesterday)]
                     arrayByAddingObjectsFromArray:[weekdays_temp subarrayWithRange:NSMakeRange(0, yesterday)]];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    //NSLog(@"viewDidAppear...");
    
    /*  IMPORTANT: CALL THE INITIALIZATION METHOD HERE 
        The plots are initialized here, since the view bounds have not transformed for landscape until now
     */
    [self initPlots];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) { // The field index
        num = [NSNumber numberWithFloat:(arc4random()%8)+1.0];
    }
    else {
        return [NSNumber numberWithInt:index];
    }
    
    
    //NSLog(@"numberForPlot returning num = %@", num);
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    //NSLog(@"dataLabelForPlot...");
    // Define label text style
    static CPTMutableTextStyle *labelText = nil;
    if (!labelText) {
        labelText= [[CPTMutableTextStyle alloc] init];
        labelText.color = [CPTColor grayColor];
    }
    // Set up display label
    NSString *labelValue = @"00:00 h";
    // Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:labelValue style:labelText];
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
        pieChart.pieRadius = (hostingView.bounds.size.height * 0.7) / 2;
        pieChart.identifier = graph.title;
        pieChart.startAngle = M_PI_4;
        pieChart.sliceDirection = CPTPieDirectionClockwise;
        // Create gradient
        CPTGradient *overlayGradient = [[CPTGradient alloc] init];
        overlayGradient.gradientType = CPTGradientTypeRadial;
        overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.9];
        overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.4] atPosition:1.0];
        pieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
        pieChartsMutable[i] = pieChart;
        // Add chart to graph
        [graph addPlot:pieChart];
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
