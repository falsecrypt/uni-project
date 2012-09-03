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
-(void)configureHostForPieChart;
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
@synthesize hostView = _hostView;
@synthesize detailDescriptionLabel = _detailDescriptionLabel;
@synthesize masterPopoverController = _masterPopoverController;

CGFloat const CPDBarWidth = 0.25f;
CGFloat const CPDBarInitialX = 0.25f;

UIPopoverController *masterPopoverController;
//@synthesize toolbar = _toolbar;
//@synthesize switchAAPL = _switchAAPL;
//@synthesize switchGOOG = _switchGOOG;
//@synthesize switchMSFT = _sswitchMSFT;

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

- (void)configureView
{
    //self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    // Update the user interface for the detail item.
    
    //self.detailDescriptionLabel.text = [self.detailItem description];
    
    // *************** PIE CHART ***************
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        NSLog(@"Calling configureView, Case pie chart");
        [self initPlotForPieChart];
    }
    // *************** BAR GRAPH ***************
    else if ([barGraph isEqualToString:[self.detailItem description] ] ){
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
    [self configureHostForPieChart];
    [self configureGraphForPieChart];
    [self configureChartForPieChart];
    [self configureLegendForPieChart];
}

-(void)initPlotForBarGraph {
    self.hostView.allowPinchScaling = NO;
    [self configureGraphForBarGraph];
    [self configurePlotsForBarGraph];
    [self configureLegendForPieChart];
}

-(void)initPlotForScatterPlot {
    
    
}

-(IBAction)aaplSwitched:(id)sender {
}

-(IBAction)googSwitched:(id)sender {
}

-(IBAction)msftSwitched:(id)sender {
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
    CPTGraph *graph = self.hostView.hostedGraph;
    CGFloat barX = CPDBarInitialX;
    NSArray *plots = [NSArray arrayWithObjects:self.aaplPlot, self.googPlot, self.msftPlot, nil];
    for (CPTBarPlot *plot in plots) {
        plot.dataSource = self;
        plot.delegate = self;
        plot.barWidth = CPTDecimalFromDouble(CPDBarWidth);
        plot.barOffset = CPTDecimalFromDouble(barX);
        plot.lineStyle = barLineStyle;
        [graph addPlot:plot toPlotSpace:graph.defaultPlotSpace];
        barX += CPDBarWidth;
    }
}

-(void)configureHostForPieChart {
    NSLog(@"Calling configureHostForPieChart");
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
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 16.0f;
    // 3 - Configure title
    NSString *title = @"Portfolio Prices: May 1, 2012";
    graph.title = title;
    graph.titleTextStyle = textStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, -12.0f);
    // 4 - Set theme
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
}

-(void)configureGraphForBarGraph{
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    graph.plotAreaFrame.masksToBorder = NO;
    self.hostView.hostedGraph = graph;
    // 2 - Configure the graph
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];
    graph.paddingBottom = 30.0f;
    graph.paddingLeft  = 30.0f;
    graph.paddingTop    = -1.0f;
    graph.paddingRight  = -5.0f;
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
    graph.titleDisplacement = CGPointMake(0.0f, -16.0f);
    // 5 - Set up plot space
    CGFloat xMin = 0.0f;
    CGFloat xMax = [[[CPDStockPriceStore sharedInstance] datesInWeek] count];
    CGFloat yMin = 0.0f;
    CGFloat yMax = 800.0f;  // should determine dynamically based on max price
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];
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
        NSLog(@"numberOfRecordsForPlot: %i", [[[CPDStockPriceStore sharedInstance] tickerSymbols] count]);
        return [[[CPDStockPriceStore sharedInstance] tickerSymbols] count];
    }
    else {
        return 0;
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot
                     field:(NSUInteger)fieldEnum
               recordIndex:(NSUInteger)index
{
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        if (CPTPieChartFieldSliceWidth == fieldEnum)
        {
            return [[[CPDStockPriceStore sharedInstance] dailyPortfolioPrices]
                    objectAtIndex:index];
        }
        else if ([barGraph isEqualToString:[self.detailItem description]]){
            return [NSDecimalNumber numberWithUnsignedInteger:index];
        }
        return [NSDecimalNumber zero];
    }
    else {
        return 0;
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot
                  recordIndex:(NSUInteger)index {
    if ([pieChart isEqualToString:[self.detailItem description] ] ) {
        // 1 - Define label text style
        static CPTMutableTextStyle *labelText = nil;
        if (!labelText) {
            labelText= [[CPTMutableTextStyle alloc] init];
            labelText.color = [CPTColor grayColor];
        }
        // 2 - Calculate portfolio total value
        NSDecimalNumber *portfolioSum = [NSDecimalNumber zero];
        for (NSDecimalNumber *price in [[CPDStockPriceStore sharedInstance] dailyPortfolioPrices]) {
            portfolioSum = [portfolioSum decimalNumberByAdding:price];
        }
        // 3 - Calculate percentage value
        NSDecimalNumber *price =
        [[[CPDStockPriceStore sharedInstance] dailyPortfolioPrices] objectAtIndex:index];
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
        return [[[CPDStockPriceStore sharedInstance] tickerSymbols] objectAtIndex:index];
    }
    return @"N/A";
}

#pragma mark - UIActionSheetDelegate methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
}

#pragma mark - CPTBarPlotDelegate methods
-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index {
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //[self.view sizeToFit];
    
    //NSLog(@"DETAIL frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
    //NSLog(@"DETAIL bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);
    

}







@end
