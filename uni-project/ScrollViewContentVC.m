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
@property (strong, nonatomic) CPTGraphHostingView *mondayPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *tuesdayPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *wednesdayPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *thursdayPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *fridayPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *saturdayPieChartView;
@property (strong, nonatomic) CPTGraphHostingView *sundayPieChartView;

@property (strong, nonatomic) CPTXYGraph *mondayPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *tuesdayPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *wednesdayPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *thursdayPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *fridayPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *saturdayPieChartGraph;
@property (strong, nonatomic) CPTXYGraph *sundayPieChartGraph;

@property (strong, nonatomic) CPTPieChart *mondayPieChart;
@property (strong, nonatomic) CPTPieChart *tuesdayPieChart;
@property (strong, nonatomic) CPTPieChart *wednesdayPieChart;
@property (strong, nonatomic) CPTPieChart *thursdayPieChart;
@property (strong, nonatomic) CPTPieChart *fridayPieChart;
@property (strong, nonatomic) CPTPieChart *saturdayPieChart;
@property (strong, nonatomic) CPTPieChart *sundayPieChart;

@property (assign, nonatomic) int pageNumber;
@property (weak, nonatomic) UIViewController *targetViewController; //EnergyClockViewController

@property (strong, nonatomic) NSArray *firstPageHostingViews;
@property (strong, nonatomic) NSArray *firstPageGraphs;
@property (strong, nonatomic) NSArray *firstPagePieCharts;

@property (strong, nonatomic) NSArray *secondPageHostingViews;
@property (strong, nonatomic) NSArray *secondPageGraphs;
@property (strong, nonatomic) NSArray *secondPagePieCharts;


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
        NSLog(@"initWithPageNumber: %i", page);
        self.pageNumber = page;
        self.targetViewController = viewController;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSLog(@"viewDidAppear...");
    
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
                                  self.mondayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                  self.tuesdayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                  self.wednesdayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                  self.thursdayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init], nil];
    }
    return _firstPageHostingViews;
}

-(NSArray*)secondPageHostingViews
{
    if(!_secondPageHostingViews)
    {
        _secondPageHostingViews = [[NSArray alloc] initWithObjects:
                                   self.fridayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                   self.saturdayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init],
                                   self.sundayPieChartView=[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init], nil];
    }
    return _secondPageHostingViews;
}

-(NSArray*)firstPageGraphs
{
    if(!_firstPageGraphs)
    {
        _firstPageGraphs = [[NSArray alloc] initWithObjects:
                            self.mondayPieChartGraph = [[CPTXYGraph alloc] init],
                            self.tuesdayPieChartGraph = [[CPTXYGraph alloc] init],
                            self.wednesdayPieChartGraph = [[CPTXYGraph alloc] init],
                            self.thursdayPieChartGraph = [[CPTXYGraph alloc] init], nil];
    }
    return _firstPageGraphs;
}

-(NSArray*)secondPageGraphs
{
    if(!_secondPageGraphs)
    {
        _secondPageGraphs = [[NSArray alloc] initWithObjects:
                             self.fridayPieChartGraph = [[CPTXYGraph alloc] init],
                             self.saturdayPieChartGraph = [[CPTXYGraph alloc] init],
                             self.sundayPieChartGraph = [[CPTXYGraph alloc] init], nil];
    }
    return _secondPageGraphs;
}

-(NSArray*)firstPagePieCharts
{
    if(!_firstPagePieCharts)
    {
        _firstPagePieCharts = [[NSArray alloc] initWithObjects:
                            self.mondayPieChart = [[CPTPieChart alloc] init],
                            self.tuesdayPieChart = [[CPTPieChart alloc] init],
                            self.wednesdayPieChart = [[CPTPieChart alloc] init],
                            self.thursdayPieChart = [[CPTPieChart alloc] init], nil];
    }
    return _firstPagePieCharts;
}

-(NSArray*)secondPagePieCharts
{
    if(!_secondPagePieCharts)
    {
        _secondPagePieCharts = [[NSArray alloc] initWithObjects:
                             self.fridayPieChart = [[CPTPieChart alloc] init],
                             self.saturdayPieChart = [[CPTPieChart alloc] init],
                             self.sundayPieChart = [[CPTPieChart alloc] init], nil];
    }
    return _secondPagePieCharts;
}

#pragma mark - CPTPlotDataSource methods

// how many slices should be displayed
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSLog(@"numberOfRecordsForPlot...");
    return 2;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSLog(@"numberForPlot...");
    NSNumber *num;
    
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        num = [NSNumber numberWithFloat:(arc4random()%8)+1.0];
    }
    else {
        return [NSNumber numberWithInt:index];
    }
    
    NSLog(@"numberForPlot returning num = %@", num);
    return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    NSLog(@"dataLabelForPlot...");
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
    NSLog(@"configureHostViews...");
    
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
        [UIColor colorWithRed:(arc4random()%11*0.1) green:(arc4random()%11*0.1) blue:(arc4random()%11*0.1) alpha:0.8]; // TEST
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
        graph.title = @"Day";
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
    
    NSLog(@"configureCharts...");
    
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
