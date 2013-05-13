//
//  SliceDetailsView.m
//  uni-project
//
//  Created by Pavel Ermolin on 01.04.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "SliceDetailsView.h"
#import "ScrollViewContentVC.h"
#import "CPTAnimationPeriod.h"
#import "CPTPieChart+CustomPieChart.h"


@interface SliceDetailsView ()
@property (strong, nonatomic) CPTGraphHostingView *participantHostingView;
@property (strong, nonatomic) CPTGraphHostingView *totalSliceHostingView;

@property (strong, nonatomic) CPTXYGraph *participantGraph;
@property (strong, nonatomic) CPTXYGraph *totalSliceGraph;

@property (strong, nonatomic) CPTPieChart *participantPieChart;
@property (strong, nonatomic) CPTPieChart *totalSlicePieChart;

//@property (weak, nonatomic) ScrollViewContentVC *scrollViewContentVC; // check if i need this
@property (assign, nonatomic) NSUInteger selectedEnergyClockSlice;
@property (assign, nonatomic) NSUInteger selectedParticipant;
@property (strong, nonatomic) NSArray *availableCPTColors;

@end

@implementation SliceDetailsView



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSLog(@"<SliceDetailsView> initWithFrame...");

        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


#pragma mark - Chart behavior
-(void)initPlots
{
    NSLog(@"<SliceDetailsView> initPlots...");
    self.selectedEnergyClockSlice = 0;
    self.selectedParticipant = FirstSensorID;
    self.availableCPTColors =
    [NSArray arrayWithObjects:
     [CPTColor colorWithComponentRed:93.0f/255.0f green:150.0f/255.0f blue:72.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:46.0f/255.0f green:87.0f/255.0f blue:140.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:231.0f/255.0f green:161.0f/255.0f blue:61.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:188.0f/255.0f green:45.0f/255.0f blue:48.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:111.0f/255.0f green:61.0f/255.0f blue:121.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:125.0f/255.0f green:128.0f/255.0f blue:127.0f/255.0f alpha:1.0f],
     nil];
    
    [self configureHostViews];
    [self configureGraphs];
    [self configureCharts];
    //[self configureLegend];
    
    NSLog(@"<SliceDetailsView> participantHostingView: %@, participantGraph: %@", self.participantHostingView, self.participantGraph);
}

-(void)killAll
{
    // Remove the CPTLayerHostingView
    if ( self.participantHostingView ) {
        //[self.participantHostingView removeFromSuperview];
        
        self.participantHostingView.hostedGraph = nil;
        self.participantHostingView = nil;
    }
    if ( self.totalSliceHostingView ) {
        //[self.totalSliceHostingView removeFromSuperview];
        
        self.totalSliceHostingView.hostedGraph = nil;
        self.totalSliceHostingView = nil;
    }
    
    self.availableCPTColors = nil;
}


-(void)configureHostViews
{
    NSLog(@"<SliceDetailsView> configureHostViews...");
    
    // 1 - Set up view frames
    CGRect rectParticipant = self.bounds;
    rectParticipant = CGRectMake(rectParticipant.origin.x, rectParticipant.origin.y + 10.0, self.bounds.size.width/2, (rectParticipant.size.height));
    
    CGRect rectTotalSlice = CGRectMake(self.bounds.size.width/2, rectParticipant.origin.y, self.bounds.size.width/2, (rectParticipant.size.height));
    
    // create instances
    self.participantHostingView =[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init];
    self.totalSliceHostingView  =[(CPTGraphHostingView *) [CPTGraphHostingView alloc] init];
    
    // 2 - Create host views
    self.participantHostingView.frame = rectParticipant;
    self.participantHostingView.allowPinchScaling = NO;
    self.participantHostingView.backgroundColor =[UIColor clearColor];
    [self addSubview:self.participantHostingView];
    
    self.totalSliceHostingView.frame = rectTotalSlice;
    self.totalSliceHostingView.allowPinchScaling = NO;
    self.totalSliceHostingView.backgroundColor =[UIColor clearColor];
    [self addSubview:self.totalSliceHostingView];

    
}

-(void)configureGraphs
{
    NSLog(@"<SliceDetailsView> configureGraphs...");
    
    // create instances
    self.participantGraph = [[CPTXYGraph alloc] init];
    self.totalSliceGraph = [[CPTXYGraph alloc] init];
    
    // 1.
    self.participantGraph.frame = self.participantHostingView.bounds;
    self.participantGraph.delegate = self;
    self.participantGraph.paddingLeft = 0.0f;
    self.participantGraph.paddingTop = 0.0f;
    self.participantGraph.paddingRight = 0.0f;
    self.participantGraph.paddingBottom = 0.0f;
    self.participantGraph.axisSet = nil;
    // 2.
    self.totalSliceGraph.frame = self.participantHostingView.bounds;
    self.totalSliceGraph.delegate = self;
    self.totalSliceGraph.paddingLeft = 0.0f;
    self.totalSliceGraph.paddingTop = 0.0f;
    self.totalSliceGraph.paddingRight = 0.0f;
    self.totalSliceGraph.paddingBottom = 0.0f;
    self.totalSliceGraph.axisSet = nil;
    // 1.
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color                = [CPTColor grayColor];
    textStyle.fontName             = @"Helvetica-Bold";
    textStyle.fontSize             = 15.0f;
    self.participantGraph.titleTextStyle           = textStyle;
    self.participantGraph.titleDisplacement        = CGPointMake(0.0f, -12.0f);
    self.participantGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    self.participantHostingView.hostedGraph = self.participantGraph;
    // 2.
    self.totalSliceGraph.titleTextStyle           = textStyle;
    self.totalSliceGraph.titleDisplacement        = CGPointMake(0.0f, -12.0f);
    self.totalSliceGraph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    self.totalSliceHostingView.hostedGraph = self.totalSliceGraph;

}

-(void)configureCharts
{
    
    //NSLog(@"configureCharts..., self: %@", self);
    static BOOL animated = YES;
    CGFloat maxPieRadius = (self.participantHostingView.bounds.size.height * 0.65) / 2.0;
    
    // create instances
    self.participantPieChart = [[CPTPieChart alloc] init];
    self.totalSlicePieChart = [[CPTPieChart alloc] init];
    
    // 1.
    self.participantPieChart.dataSource = self;
    self.participantPieChart.delegate = self;
    self.participantPieChart.plotSpace.delegate = self;
    self.participantPieChart.plotSpace.allowsUserInteraction = YES;
    self.participantPieChart.pieRadius = animated ? 0.0 :
    (self.participantHostingView.bounds.size.height * 0.7) / 2;
    self.participantPieChart.identifier = @"participantPieChart";
    self.participantPieChart.startAngle = M_PI_2;
    self.participantPieChart.sliceDirection = CPTPieDirectionClockwise;
    self.participantPieChart.labelOffset = -1.0;
    self.participantPieChart.shouldCenterLabel = @"YES"; // kind of clock-design
    CPTMutableLineStyle *customLineStyle = [CPTMutableLineStyle lineStyle];
    customLineStyle.lineColor = [[CPTColor blackColor]colorWithAlphaComponent:0.3];
    self.participantPieChart.borderLineStyle = customLineStyle;
    // 2.
    self.totalSlicePieChart.dataSource = self;
    self.totalSlicePieChart.delegate = self;
    self.totalSlicePieChart.plotSpace.delegate = self;
    self.totalSlicePieChart.plotSpace.allowsUserInteraction = YES;
    self.totalSlicePieChart.pieRadius = animated ? 0.0 :
    (self.totalSliceHostingView.bounds.size.height * 0.7) / 2;
    self.totalSlicePieChart.identifier = @"totalSlicePieChart";
    self.totalSlicePieChart.startAngle = M_PI_2;
    self.totalSlicePieChart.sliceDirection = CPTPieDirectionCounterClockwise;
    //pieChart.labelRotationRelativeToRadius = YES;
    //pieChart.labelRotation                 = -M_PI_2;
    self.totalSlicePieChart.labelOffset = -1.0;
    
    // Create gradient
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
    overlayGradient.gradientType = CPTGradientTypeRadial;
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.9];
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.4] atPosition:1.0];
    // 1.
    self.participantPieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
    // 2.
    self.totalSlicePieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
    // Add charts to graphs
    // 1.
    [self.participantGraph addPlot:self.participantPieChart];
    // 2.
    [self.totalSliceGraph addPlot:self.totalSlicePieChart];
    
    // bounce effect
    if ( animated ){
        [CPTAnimation animate:self.participantPieChart
                     property:@"pieRadius"
                         from:0.0
                           to:maxPieRadius
                     duration:0.5
                    withDelay:0.1
               animationCurve:CPTAnimationCurveBounceOut
                     delegate:nil];
        
        [CPTAnimation animate:self.totalSlicePieChart
                     property:@"pieRadius"
                         from:0.0
                           to:maxPieRadius
                     duration:0.5
                    withDelay:0.1
               animationCurve:CPTAnimationCurveBounceOut
                     delegate:nil];
    }
    
    
}

// how many slices should be displayed
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
//    NSLog(@"numberOfRecordsForPlot - new");
    NSUInteger result = 0;
    if([(NSString *)plot.identifier isEqualToString:@"participantPieChart"]){
//        NSLog(@"numberOfRecordsForPlot - participantPieChart is here!!!");
        result = [self.datasource getSlicesNumber];
    }
    else if ([(NSString *)plot.identifier isEqualToString:@"totalSlicePieChart"]){
//        NSLog(@"numberOfRecordsForPlot - totalSlicePieChart is here!!!");
        result = numberOfParticipants;
    }
    return result;
}

// Gets a plot data value for the given plot and field.
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *result = nil;
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) { // The field index
        if([(NSString *)plot.identifier isEqualToString:@"participantPieChart"]){

            //result = [NSNumber numberWithFloat:(arc4random()%8)+1.0];
            result = [self.datasource detailsSliceValueAtIndex:index];
            NSLog(@"numberForPlot - participantPieChart - result: %@", result);
        }
        else if ([(NSString *)plot.identifier isEqualToString:@"totalSlicePieChart"]){

            result = [self.datasource valueForSlotAtIndex:(numberOfParticipants-index)-1 sliceAtIndex:self.selectedEnergyClockSlice];
        }

    }
    else {
        result = [NSNumber numberWithInt:index];
    }
    
    return result;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    NSLog(@"dataLabelForPlot-Slice Details");
    
    // 1 - Define label text style
    static CPTMutableTextStyle *labelText = nil;
    static NSString *labelValue = @"";
    if (!labelText) {
        labelText= [[CPTMutableTextStyle alloc] init];
        labelText.color = [CPTColor grayColor];
    }
    if ([(NSString *)plot.identifier isEqualToString:@"totalSlicePieChart"]){
        // 2 - Calculate total value
        float slotValuesSum = 0.0;
        for (NSUInteger i = 0; i < numberOfParticipants; i++) {
            slotValuesSum +=[[self.datasource valueForSlotAtIndex:i sliceAtIndex:self.selectedEnergyClockSlice] floatValue];
        }
        // 3 - Calculate percentage value
        float slotValue = [[self.datasource valueForSlotAtIndex:(numberOfParticipants-index)-1 sliceAtIndex:self.selectedEnergyClockSlice] floatValue];
        float percent = slotValue/slotValuesSum;

        // 4 - Set up display label
        labelValue = [NSString stringWithFormat:@"%0.1f %%", (percent * 100.0f)];
        if (percent <= 0.0) {
            labelValue = @"";
        }
        
    }
    else if([(NSString *)plot.identifier isEqualToString:@"participantPieChart"]){
        // prepare for 2-hours-interval output-string
        if ((index*2) < 10) {
            labelValue = [NSString stringWithFormat:@"0%i:00",index*2];
        }
        else {
            labelValue = [NSString stringWithFormat:@"%i:00",index*2];
        }
        //DEBUG
        //labelValue = [NSString stringWithFormat:@"%i",index];
        
        CGFloat medAngle = [(CPTPieChart *)plot medianAngleForPieSliceIndex:index];
        NSLog(@"labelValue: %@ and medAngle: %f", labelValue, medAngle);
        
    }
    // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:labelValue style:labelText];

}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    NSLog(@"sliceFillForPieChart - new");
    CPTFill *sector = [[CPTFill alloc] init];
    CPTColor *fillColor = [[CPTColor alloc] init];
    if([(NSString *)pieChart.identifier isEqualToString:@"participantPieChart"]){
        fillColor = [self.datasource getColorForParticipantId:self.selectedParticipant];
    }
    else if ([(NSString *)pieChart.identifier isEqualToString:@"totalSlicePieChart"]){
        NSLog(@"CPTColor for index %i !", index);
        fillColor = [self.availableCPTColors objectAtIndex:(numberOfParticipants-index)-1];
    }
    
    sector=[CPTFill fillWithColor:(CPTColor *)fillColor];
    return sector;
}


-(void)reloadPieChartForNewSlice:(NSUInteger)selectedSliceNumber
{
    self.selectedEnergyClockSlice = selectedSliceNumber;
    [self.totalSliceGraph reloadData];
}

-(void)reloadPieChartForNewParticipant:(NSUInteger)selectedParticipant
{
    // @todo
    NSLog(@"reloadPieChartForNewParticipant - selectedParticipant: %i", selectedParticipant);
    self.selectedParticipant = selectedParticipant;
    [self.participantGraph reloadData];
}



@end
