//
//  LastWeekViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "LastWeekViewController.h"
#import "DetailViewManager.h"

NSString *const pieChartName = @"7WeeksPieChart";
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

CGPoint lastLocation;
CPTPieChart *piePlot;
BOOL selecting;
BOOL repeatingTouch;
BOOL firstTime;
NSUInteger currentSliceIndex;

@interface LastWeekViewController ()

@end

@implementation LastWeekViewController

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
	// Do any additional setup after loading the view.
    
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    detailViewManager.detailViewController = self;
    
    firstTime = YES;
    
    if (self.navigationPaneBarButtonItem)
        [self.navigationBar.topItem setLeftBarButtonItem:self.navigationPaneBarButtonItem
                                                animated:NO];
    
    NSString *secondNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideProfileAfterUserLoggedOff)
     name:secondNotificationName
     object:nil];
    
    [self initPieChart];
}

- (void) initPieChart {
    // NSLog(@"calling initDataDisplayView");
    // Prepare Data for the 7-Weeks-Pie Chart TODO
    
    if ( plotData == nil ) {
        plotData = [[NSMutableArray alloc] initWithObjects:
                    [NSNumber numberWithDouble:20.0],
                    [NSNumber numberWithDouble:30.0],
                    [NSNumber numberWithDouble:60.0],
                    nil];
    }

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
    NSLog(@"%@ slice was selected at index %lu. Value = %@", plot.identifier, (unsigned long)index, [plotData objectAtIndex:index]);
    
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
    
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.duration = 1.0f;
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.toValue = [NSNumber numberWithFloat:1.0];
    [piePlot addAnimation:fadeInAnimation forKey:@"animateOpacity"];
    
    
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
    return [plotData count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num;
    
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        num = [plotData objectAtIndex:index];
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
        
        newLayer                 = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", [[plotData objectAtIndex:index] floatValue]] style:whiteText];
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
        result = 15.0;
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

@end
