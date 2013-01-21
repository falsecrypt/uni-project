//
//  MDDetailViewController.m
//  MultipleMasterDetailViews
//
//  Created by Todd Bates on 11/14/11.
//  Copyright (c) 2011 Science At Hand LLC. All rights reserved.
//

#import "MDDetailViewController.h"

@interface MDDetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (nonatomic, strong) CPTGraphHostingView *hostView;
-(void)configureView;
-(void)initPlotForPieChart;
-(void)configureHost;
-(void)configureGraphForPieChart;
-(void)configureChartForPieChart;
-(void)configureLegendForPieChart;

//@property (nonatomic, strong) IBOutlet CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTBarPlot *aaplPlot;
@property (nonatomic, strong) CPTBarPlot *googPlot;
@property (nonatomic, strong) CPTBarPlot *msftPlot;
@property (nonatomic, strong) CPTPlotSpaceAnnotation *priceAnnotation;

-(IBAction)aaplSwitched:(id)sender;
-(IBAction)googSwitched:(id)sender;
-(IBAction)msftSwitched:(id)sender;

-(void)initPlotForBarGraph;
-(void)configureGraphForBarGraph;
-(void)configurePlotsForBarGraph;
-(void)configureAxesForBarGraph;
-(void)hideAnnotationForBarGraph:(CPTGraph *)graph;

@end

@implementation MDDetailViewController

@synthesize detailItem = _detailItem;
@synthesize switchAAPL = _switchAAPL;
@synthesize switchGOOG = _switchGOOG;
@synthesize switchMSFT = _switchMSFT;
@synthesize hostView = _hostView;
@synthesize detailDescriptionLabel = _detailDescriptionLabel;
@synthesize hostViewForBarGraph = _hostViewForBarGraph;
@synthesize masterPopoverController = _masterPopoverController;

CGFloat const CPDBarWidth = 0.25f;
CGFloat const CPDBarInitialX = 0.25f;

UIPopoverController *masterPopoverController;
//@synthesize toolbar = _toolbar;

@synthesize aaplPlot = _aaplPlot;
@synthesize googPlot = _googPlot;
@synthesize msftPlot = _msftPlot;
@synthesize priceAnnotation = _priceAnnotation;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    //NSLog(@"setDetailItem:newDetailItem: %@", newDetailItem);
    //NSLog(@"setDetailItem:self.detailItem: %@", self.detailItem);
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        NSLog(@"Calling setDetailItem");

        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }        
}

-(void)hideAnnotationForBarGraph:(CPTGraph *)graph {
    if ((graph.plotAreaFrame.plotArea) && (self.priceAnnotation)) {
        [graph.plotAreaFrame.plotArea removeAnnotation:self.priceAnnotation];
        self.priceAnnotation = nil;
    }
    NSLog(@"hideAnnotationForBarGraph");
}

-(void)configureAxesForBarGraph {
    // 1 - Configure styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor whiteColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:1];
    // 2 - Get the graph's axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostViewForBarGraph.hostedGraph.axisSet;
    // 3 - Configure the x-axis
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    axisSet.xAxis.title = @"Days of Week (Mon - Fri)";
    axisSet.xAxis.titleTextStyle = axisTitleStyle;
    axisSet.xAxis.titleOffset = 10.0f;
    axisSet.xAxis.axisLineStyle = axisLineStyle;
    // 4 - Configure the y-axis
    //axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    /*
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    axisSet.yAxis.title = @"Price";
    axisSet.yAxis.titleTextStyle = axisTitleStyle;
    axisSet.yAxis.titleOffset = 5.0f;
    axisSet.yAxis.axisLineStyle = axisLineStyle;
    axisSet.yAxis.minorTickLength = 100.0f;
     */
    
    // Create grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 1.0;
    majorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.75];
    
    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 1.0;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.25];

    CPTXYAxis *y = axisSet.yAxis;
    {
        y.majorIntervalLength         = CPTDecimalFromInteger(30);
        y.minorTicksPerInterval       = 2;
        y.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
        y.preferredNumberOfMajorTicks = 10;
        y.majorGridLineStyle          = majorGridLineStyle;
        y.minorGridLineStyle          = minorGridLineStyle;
        y.axisLineStyle               = nil;
        y.majorTickLineStyle          = nil;
        y.minorTickLineStyle          = nil;
        y.labelOffset                 = 3.0;
        y.labelRotation               = M_PI / 2;
        y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
        y.title       = @"Price";
        y.titleOffset = 30.0f;
        y.titleTextStyle = axisTitleStyle;
    }

    //y.majorIntervalLength = CPTDecimalFromDouble(100.00);
    //y.minorTicksPerInterval = 100;
    //y.minorTickLength = 100.0f;
    NSLog(@"configureAxesForBarGraph");
}

-(void)configureAxesForScatterPlot {
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor whiteColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor whiteColor];
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor whiteColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 11.0f;
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor whiteColor];
    tickLineStyle.lineWidth = 2.0f;
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor blackColor];
    tickLineStyle.lineWidth = 1.0f;
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    // 3 - Configure x-axis
    CPTAxis *x = axisSet.xAxis;
    x.title = @"Day of Month";
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 15.0f;
    x.axisLineStyle = axisLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.tickDirection = CPTSignNegative;
    CGFloat dateCount = [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
    NSMutableSet *xLabels = [NSMutableSet setWithCapacity:dateCount];
    NSMutableSet *xLocations = [NSMutableSet setWithCapacity:dateCount];
    NSInteger i = 0;
    for (NSString *date in [[CPDStockPriceStore sharedInstance] datesInMonth]) {
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:date  textStyle:x.labelTextStyle];
        CGFloat location = i++;
        label.tickLocation = CPTDecimalFromCGFloat(location);
        label.offset = x.majorTickLength;
        if (label) {
            [xLabels addObject:label];
            [xLocations addObject:@(location)];
        }
    }
    x.axisLabels = xLabels;
    x.majorTickLocations = xLocations;
    // 4 - Configure y-axis
    CPTAxis *y = axisSet.yAxis;
    y.title = @"Price";
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = -40.0f;
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = 16.0f;
    y.majorTickLineStyle = axisLineStyle;
    y.majorTickLength = 4.0f;
    y.minorTickLength = 2.0f;
    y.tickDirection = CPTSignPositive;
    NSInteger majorIncrement = 100;
    NSInteger minorIncrement = 50;
    CGFloat yMax = 700.0f;  // should determine dynamically based on max price
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    for (NSInteger j = minorIncrement; j <= yMax; j += minorIncrement) {
        NSUInteger mod = j % majorIncrement;
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", j] textStyle:y.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger(j);
            label.tickLocation = location;
            label.offset = -y.majorTickLength - y.labelOffset;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        } else {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    y.axisLabels = yLabels;    
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
}

- (void)configureView
{
    //self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    // Update the user interface for the detail item.
    
    //self.detailDescriptionLabel.text = [self.detailItem description];
    
    // *************** PIE CHART ***************
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        
        [self initPlotForPieChart];
    }
    // *************** BAR GRAPH ***************
    else if ([barGraph isEqualToString:[self.detailItem description] ] ){
        NSLog(@"Calling configureView, Case bar graph");
        [self initPlotForBarGraph];
    }
    // *************** SCATTER PLOT ***************
    else if ([scatterPlot isEqualToString:[self.detailItem description] ] ){
        [self initPlotForScatterPlot];
        
    }
    // der benutzer kommt ueber tabbar -> zuerst pieChart anzeigen
   /* else {
        self.detailItem = @"Pie Chart";
        [self initPlotForPieChart];
    } */
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad, frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
    NSLog(@"viewDidLoad, bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);
	// Do any additional setup after loading the view, typically from a nib.
    //[self configureView];
}

- (void)viewDidUnload
{
    [self setDetailDescriptionLabel:nil];
    [self setHostView:nil];
    [self setSwitchAAPL:nil];
    [self setSwitchGOOG:nil];
    [self setSwitchMSFT:nil];
    [self setHostViewForBarGraph:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self configureView]; // ich rufe hier mal configureView auf, weil
    // in viewDidLoad bounds und frame size anscheindend noch nicht gesetzt werden
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}
/*
- (NSString *)description{
    NSString *descriptionString =
    [NSString stringWithFormat:@"\nObject MDDetailViewController - detailItem: %@; detailDescriptionLabel: %@;", self.detailItem, self.detailDescriptionLabel];
    return descriptionString;
}
 */

#pragma mark - Chart behavior
-(void)initPlotForPieChart {
    [self configureHost];
    [self configureGraphForPieChart];
    [self configureChartForPieChart];
    [self configureLegendForPieChart];
}

-(void)initPlotForBarGraph {
    //[self configureHost];
    self.hostViewForBarGraph.allowPinchScaling = NO;
    [self configureGraphForBarGraph];
    [self configurePlotsForBarGraph];
    [self configureAxesForBarGraph];
    //NSLog(@"initPlotForBarGraph");
}

-(void)initPlotForScatterPlot {
    NSLog(@"Calling initPlotForScatterPlot");
    [self configureHost];
    [self configureGraphForScatterPlot];
    [self configurePlotsForScatterPlot];
    [self configureAxesForScatterPlot];
    
}

-(IBAction)aaplSwitched:(id)sender {
    BOOL on = [((UISwitch *) sender) isOn];
    if (!on) {
        [self hideAnnotationForBarGraph:self.aaplPlot.graph];
    }
    [self.aaplPlot setHidden:!on];
}

-(IBAction)googSwitched:(id)sender {
    BOOL on = [((UISwitch *) sender) isOn];
    if (!on) {
        [self hideAnnotationForBarGraph:self.googPlot.graph];
    }
    [self.googPlot setHidden:!on];
}

-(IBAction)msftSwitched:(id)sender {
    BOOL on = [((UISwitch *) sender) isOn];
    if (!on) {
        [self hideAnnotationForBarGraph:self.msftPlot.graph];
    }
    [self.msftPlot setHidden:!on];
}

-(void)configurePlotsForBarGraph {
    // 1 - Set up the three plots
    self.aaplPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor redColor] horizontalBars:NO];
    self.aaplPlot.identifier = CPDTickerSymbolAAPL;
    self.googPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor greenColor] horizontalBars:NO];
    self.googPlot.identifier = CPDTickerSymbolGOOG;
    self.msftPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor blueColor] horizontalBars:NO];
    self.msftPlot.identifier = CPDTickerSymbolMSFT;
    // 2 - Set up line style
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineColor = [CPTColor lightGrayColor];
    barLineStyle.lineWidth = 0.5;
    // 3 - Add plots to graph
    CPTGraph *graph = self.hostViewForBarGraph.hostedGraph;
    CGFloat barX = CPDBarInitialX;
    NSArray *plots = @[self.aaplPlot, self.googPlot, self.msftPlot];
    for (CPTBarPlot *plot in plots) {
        plot.dataSource = self;
        plot.delegate = self;
        plot.barWidth = CPTDecimalFromDouble(CPDBarWidth);
        plot.barOffset = CPTDecimalFromDouble(barX);
        NSLog(@"barOffset: %f", barX);
        plot.lineStyle = barLineStyle;
        [graph addPlot:plot toPlotSpace:graph.defaultPlotSpace];
        barX += CPDBarWidth;
    }
}

-(void)configurePlotsForScatterPlot {
    NSLog(@"Calling configurePlotsForScatterPlot");
    // 1 - Get graph and plot space
    CPTGraph *graph = self.hostView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    // 2 - Create the three plots
    CPTScatterPlot *aaplPlot = [[CPTScatterPlot alloc] init];
    aaplPlot.dataSource = self;
    aaplPlot.identifier = CPDTickerSymbolAAPL;
    CPTColor *aaplColor = [CPTColor redColor];
    [graph addPlot:aaplPlot toPlotSpace:plotSpace];
    CPTScatterPlot *googPlot = [[CPTScatterPlot alloc] init];
    googPlot.dataSource = self;
    googPlot.identifier = CPDTickerSymbolGOOG;
    CPTColor *googColor = [CPTColor greenColor];
    [graph addPlot:googPlot toPlotSpace:plotSpace];
    CPTScatterPlot *msftPlot = [[CPTScatterPlot alloc] init];
    msftPlot.dataSource = self;
    msftPlot.identifier = CPDTickerSymbolMSFT;
    CPTColor *msftColor = [CPTColor blueColor];
    [graph addPlot:msftPlot toPlotSpace:plotSpace];
    
    // 3 - Set up plot space
    [plotSpace scaleToFitPlots:@[aaplPlot, googPlot, msftPlot]];
    CPTMutablePlotRange *xRange = [plotSpace.xRange copy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];
    plotSpace.xRange = xRange;
    CPTMutablePlotRange *yRange = [plotSpace.yRange copy];
    [yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    plotSpace.yRange = yRange;
    
    // 4 - Create styles and symbols
    CPTMutableLineStyle *aaplLineStyle = [aaplPlot.dataLineStyle mutableCopy];
    aaplLineStyle.lineWidth = 2.5;
    aaplLineStyle.lineColor = aaplColor;
    aaplPlot.dataLineStyle = aaplLineStyle;
    CPTMutableLineStyle *aaplSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    aaplSymbolLineStyle.lineColor = aaplColor;
    CPTPlotSymbol *aaplSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    aaplSymbol.fill = [CPTFill fillWithColor:aaplColor];
    aaplSymbol.lineStyle = aaplSymbolLineStyle;
    aaplSymbol.size = CGSizeMake(6.0f, 6.0f);
    aaplPlot.plotSymbol = aaplSymbol;
    CPTMutableLineStyle *googLineStyle = [googPlot.dataLineStyle mutableCopy];
    googLineStyle.lineWidth = 1.0;
    googLineStyle.lineColor = googColor;
    googPlot.dataLineStyle = googLineStyle;
    CPTMutableLineStyle *googSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    googSymbolLineStyle.lineColor = googColor;
    CPTPlotSymbol *googSymbol = [CPTPlotSymbol starPlotSymbol];
    googSymbol.fill = [CPTFill fillWithColor:googColor];
    googSymbol.lineStyle = googSymbolLineStyle;
    googSymbol.size = CGSizeMake(6.0f, 6.0f);
    googPlot.plotSymbol = googSymbol;
    CPTMutableLineStyle *msftLineStyle = [msftPlot.dataLineStyle mutableCopy];
    msftLineStyle.lineWidth = 2.0;
    msftLineStyle.lineColor = msftColor;
    msftPlot.dataLineStyle = msftLineStyle;
    CPTMutableLineStyle *msftSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    msftSymbolLineStyle.lineColor = msftColor;
    CPTPlotSymbol *msftSymbol = [CPTPlotSymbol diamondPlotSymbol];
    msftSymbol.fill = [CPTFill fillWithColor:msftColor];
    msftSymbol.lineStyle = msftSymbolLineStyle;
    msftSymbol.size = CGSizeMake(6.0f, 6.0f);
    msftPlot.plotSymbol = msftSymbol;
}

-(void)configureHost {
    NSLog(@"Calling configureHost");
    //self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    //[self.view sizeToFit];
    // 1 - Set up view frame
    CGRect parentRect = self.view.bounds;
    //NSLog(@"self.view: %@", self.view);
    //NSLog(@"self: %@", self);
    //NSLog(@"frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
    //NSLog(@"bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);

    //CGSize toolbarSize = self.toolbar.bounds.size;
    parentRect = CGRectMake(parentRect.origin.x,
                            (parentRect.origin.y  /*toolbarSize.height*/),
                           parentRect.size.width,
                            (parentRect.size.height  /*toolbarSize.height*/));
    // 2 - Create host view
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:parentRect];
    self.hostView.allowPinchScaling = NO;
    if ([scatterPlot isEqualToString:[self.detailItem description] ] ) {
        self.hostView.allowPinchScaling = YES;
    }
    [self.view addSubview:self.hostView];
}

-(void)configureGraphForPieChart {
    NSLog(@"Calling configureGraphForPieChart");
    // 1 - Create and initialize graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    self.hostView.hostedGraph = graph;
    graph.paddingLeft = 0.0f;
    graph.paddingTop = 0.0f;
    graph.paddingRight = 0.0f;
    graph.paddingBottom = 0.0f;
    graph.axisSet = nil;
    // 2 - Set up text style
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor whiteColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 16.0f;
    // 3 - Configure title
    NSString *title = @"Portfolio Prices: May 1, 2012";
    graph.title = title;
    graph.titleTextStyle = textStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, -12.0f);
    // 4 - Set theme
    //[graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
}

-(void)configureGraphForBarGraph{
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostViewForBarGraph.bounds];
    graph.plotAreaFrame.masksToBorder = NO;
    //graph.plotAreaFrame.paddingLeft = 30.0;
    //graph.plotAreaFrame.paddingRight = 30.0;
    //graph.plotAreaFrame.paddingTop = 30.0;
    //graph.plotAreaFrame.paddingBottom = 30.0;
    self.hostViewForBarGraph.hostedGraph = graph;
   // NSLog(@"configureGraphForBarGraph, self.hostView: %@", self.hostViewForBarGraph);
    // 2 - Configure the graph
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    graph.paddingBottom = 30.0f;
    graph.paddingLeft  = 45.0f;
    graph.paddingTop    = 30.0f;
    graph.paddingRight  = 0.0f;
    //graph.paddingTop    = -1.0f;
    //graph.paddingRight  = -5.0f;
    // 3 - Set up styles
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    // 4 - Set up title
    NSString *title = @"Portfolio Prices: April 23 - 27, 2012";
    graph.title = title;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    
    // 5 - Set up plot space
    CGFloat xMin = 0.0f;
    CGFloat xMax = [[[CPDStockPriceStore sharedInstance] datesInWeek] count];
    CGFloat yMin = 0.0f;
    CGFloat yMax = 800.0f;  // (def: 800.0f) should determine dynamically based on max price
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];

}

-(void)configureGraphForScatterPlot{
    NSLog(@"Calling configureGraphForScatterPlot");
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    self.hostView.hostedGraph = graph;
    // 2 - Set graph title
    NSString *title = @"Portfolio Prices: April 2012";
    graph.title = title;
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:30.0f];
    [graph.plotAreaFrame setPaddingBottom:30.0f];
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
}

-(void)configureChartForPieChart {
    NSLog(@"Calling configureChartForPieChart");
    // 1 - Get reference to graph
    CPTGraph *graph = self.hostView.hostedGraph;
    // 2 - Create chart
    CPTPieChart *pieChart = [[CPTPieChart alloc] init];
    pieChart.dataSource = self;
    pieChart.delegate = self;
    pieChart.pieRadius = (self.hostView.bounds.size.height * 0.7) / 2;
    pieChart.identifier = graph.title;
    pieChart.startAngle = M_PI_4;
    pieChart.sliceDirection = CPTPieDirectionClockwise;
    // 3 - Create gradient
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
    overlayGradient.gradientType = CPTGradientTypeRadial;
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.9];
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.4] atPosition:1.0];
    pieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
    // 4 - Add chart to graph
    [graph addPlot:pieChart];
}

-(void)configureLegendForPieChart {
    NSLog(@"Calling configureLegendForPieChart");
    // 1 - Get graph instance
    CPTGraph *graph = self.hostView.hostedGraph;
    // 2 - Create legend
    CPTLegend *theLegend = [CPTLegend legendWithGraph:graph];
    // 3 - Configure legend
    theLegend.numberOfColumns = 1;
    theLegend.fill = [CPTFill fillWithColor:[CPTColor whiteColor]];
    theLegend.borderLineStyle = [CPTLineStyle lineStyle];
    theLegend.cornerRadius = 5.0;
    // 4 - Add legend to graph
    graph.legend = theLegend;
    graph.legendAnchor = CPTRectAnchorRight;
    CGFloat legendPadding = -(self.view.bounds.size.width / 25);
    graph.legendDisplacement = CGPointMake(legendPadding, 0.0);
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        //NSLog(@"numberOfRecordsForPlot: %i", [[[CPDStockPriceStore sharedInstance] tickerSymbols] count]);
        return [[[CPDStockPriceStore sharedInstance] tickerSymbols] count];
    }
    else if ([barGraph isEqualToString:[self.detailItem description]]){
        return [[[CPDStockPriceStore sharedInstance] datesInWeek] count];
    }
    else if ([scatterPlot isEqualToString:[self.detailItem description]]){
        return [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
    }
    else {
        return 0;
    }
}


// Gets a plot data value for the given plot and field.
-(NSNumber *)numberForPlot:(CPTPlot *)plot
                     field:(NSUInteger)fieldEnum
               recordIndex:(NSUInteger)index
{
    // *************** PIE CHART ***************
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        if (CPTPieChartFieldSliceWidth == fieldEnum)
            return [[CPDStockPriceStore sharedInstance] dailyPortfolioPrices][index];
    }
    // *************** BAR GRAPH ***************
    else if ([barGraph isEqualToString:[self.detailItem description]]){
        if ((fieldEnum == 3 || fieldEnum == CPTBarPlotFieldBarTip) && (index < [[[CPDStockPriceStore sharedInstance] datesInWeek] count])) {
            //NSLog(@"numberForPlot:field:recordIndex:, fieldEnum = %i, CPTBarPlotFieldBarTip = %i, index = %i", fieldEnum, CPTBarPlotFieldBarTip, index);
            if ([plot.identifier isEqual:CPDTickerSymbolAAPL]) {
                //NSLog(@"numberForPlot:field:recordIndex return: %@",[[[CPDStockPriceStore sharedInstance] weeklyPrices:CPDTickerSymbolAAPL] objectAtIndex:index]);
                return [[CPDStockPriceStore sharedInstance] weeklyPrices:CPDTickerSymbolAAPL][index];
            } else if ([plot.identifier isEqual:CPDTickerSymbolGOOG]) {
                //NSLog(@"numberForPlot:field:recordIndex return: %@",[[[CPDStockPriceStore sharedInstance] weeklyPrices:CPDTickerSymbolGOOG] objectAtIndex:index]);
                return [[CPDStockPriceStore sharedInstance] weeklyPrices:CPDTickerSymbolGOOG][index];
            } else if ([plot.identifier isEqual:CPDTickerSymbolMSFT]) {
                //NSLog(@"numberForPlot:field:recordIndex return: %@",[[[CPDStockPriceStore sharedInstance] weeklyPrices:CPDTickerSymbolMSFT] objectAtIndex:index]);
                return [[CPDStockPriceStore sharedInstance] weeklyPrices:CPDTickerSymbolMSFT][index];
            }
        }

        return [NSDecimalNumber numberWithUnsignedInteger:index];
    }
    // *************** SCATTER PLOT ***************
    else if ([scatterPlot isEqualToString:[self.detailItem description]]){
        NSInteger valueCount = [[[CPDStockPriceStore sharedInstance] datesInMonth] count];
        switch (fieldEnum) {
            case CPTScatterPlotFieldX:
                if (index < valueCount) {
                    return @(index);
                }
                break;
                
            case CPTScatterPlotFieldY:
                if ([plot.identifier isEqual:CPDTickerSymbolAAPL] == YES) {
                    return [[CPDStockPriceStore sharedInstance] monthlyPrices:CPDTickerSymbolAAPL][index];
                } else if ([plot.identifier isEqual:CPDTickerSymbolGOOG] == YES) {
                    return [[CPDStockPriceStore sharedInstance] monthlyPrices:CPDTickerSymbolGOOG][index];
                } else if ([plot.identifier isEqual:CPDTickerSymbolMSFT] == YES) {
                    return [[CPDStockPriceStore sharedInstance] monthlyPrices:CPDTickerSymbolMSFT][index];
                }
                break;
        }
        return [NSDecimalNumber zero];
    }

    return [NSDecimalNumber zero];
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot
                  recordIndex:(NSUInteger)index {
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        // 1 - Define label text style
        static CPTMutableTextStyle *labelText = nil;
        if (!labelText) {
            labelText= [[CPTMutableTextStyle alloc] init];
            labelText.color = [CPTColor whiteColor];
        }
        // 2 - Calculate portfolio total value
        NSDecimalNumber *portfolioSum = [NSDecimalNumber zero];
        for (NSDecimalNumber *price in [[CPDStockPriceStore sharedInstance] dailyPortfolioPrices]) {
            portfolioSum = [portfolioSum decimalNumberByAdding:price];
        }
        // 3 - Calculate percentage value
        NSDecimalNumber *price =
        [[CPDStockPriceStore sharedInstance] dailyPortfolioPrices][index];
        NSDecimalNumber *percent = [price decimalNumberByDividingBy:portfolioSum];
        // 4 - Set up display label
        NSString *labelValue = [NSString stringWithFormat:@"$%0.2f USD (%0.1f %%)",
                                [price floatValue], ([percent floatValue] * 100.0f)];
        // 5 - Create and return layer with label text
        return [[CPTTextLayer alloc] initWithText:labelValue style:labelText];
    }
    else {
        return nil;
    }
}

-(NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index {
    if (index < [[[CPDStockPriceStore sharedInstance] tickerSymbols] count]) {
        return [[CPDStockPriceStore sharedInstance] tickerSymbols][index];
    }
    return @"N/A";
}

#pragma mark - UIActionSheetDelegate methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
}

#pragma mark - CPTBarPlotDelegate methods
-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index {
    // 1 - Is the plot hidden?
    if (plot.isHidden == YES) {
        return;
    }
    // 2 - Create style, if necessary
    static CPTMutableTextStyle *style = nil;
    if (!style) {
        style = [CPTMutableTextStyle textStyle];
        style.color= [CPTColor yellowColor];
        style.fontSize = 16.0f;
        style.fontName = @"Helvetica-Bold";
    }
    // 3 - Create annotation, if necessary
    NSNumber *price = [self numberForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    //NSLog(@"barPlot:barWasSelectedAtRecordIndex: price: %@", price);
    if (!self.priceAnnotation) {
        NSNumber *x = @0;
        NSNumber *y = @0;
        NSArray *anchorPoint = @[x, y];
        self.priceAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:anchorPoint];
        
    }
    // 4 - Create number formatter, if needed
    static NSNumberFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setMaximumFractionDigits:2];
    }
    // 5 - Create text layer for annotation
    NSString *priceValue = [formatter stringFromNumber:price];
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:priceValue style:style];
    self.priceAnnotation.contentLayer = textLayer;
    // 6 - Get plot index based on identifier
    NSInteger plotIndex = 0;
    if ([plot.identifier isEqual:CPDTickerSymbolAAPL] == YES) {
        plotIndex = 0;
    } else if ([plot.identifier isEqual:CPDTickerSymbolGOOG] == YES) {
        plotIndex = 1;
    } else if ([plot.identifier isEqual:CPDTickerSymbolMSFT] == YES) {
        plotIndex = 2;
    }
    // 7 - Get the anchor point for annotation
    CGFloat x = index + CPDBarInitialX + (plotIndex * CPDBarWidth);
    NSNumber *anchorX = @(x);
    CGFloat y = [price floatValue] + (40.0f); //+ 10.0f; //(40.0f)
    NSNumber *anchorY = @(y);
    
    self.priceAnnotation.anchorPlotPoint = @[anchorX, anchorY];
    
    // 8 - Add the annotation 
    [plot.graph.plotAreaFrame.plotArea addAnnotation:self.priceAnnotation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[self.view sizeToFit];
    
    //NSLog(@"DETAIL frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
    //NSLog(@"DETAIL bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);
    
    

}







@end
