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

@interface SliceDetailsView ()
@property (strong, nonatomic) CPTGraphHostingView *participantHostingView;
@property (strong, nonatomic) CPTGraphHostingView *totalSliceHostingView;

@property (strong, nonatomic) CPTXYGraph *participantGraph;
@property (strong, nonatomic) CPTXYGraph *totalSliceGraph;

@property (strong, nonatomic) CPTPieChart *participantPieChart;
@property (strong, nonatomic) CPTPieChart *totalSlicePieChart;

@property (weak, nonatomic) ScrollViewContentVC *scrollViewContentVC; // check if i need this
@property (assign, nonatomic) NSUInteger selectedEnergyClockSlice;

@end

@implementation SliceDetailsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        NSLog(@"<SliceDetailsView> initWithFrame...");
        //[self initPlots];
        
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
    [self configureHostViews];
    [self configureGraphs];
    [self configureCharts];
    //[self configureLegend];
    
    NSLog(@"<SliceDetailsView> participantHostingView: %@, participantGraph: %@", self.participantHostingView, self.participantGraph);
}

-(void)configureHostViews
{
    NSLog(@"<SliceDetailsView> configureHostViews...");
    
    // 1 - Set up view frames
    CGRect rectParticipant = self.bounds;
    rectParticipant = CGRectMake(rectParticipant.origin.x, rectParticipant.origin.y, (rectParticipant.size.width/2)-30.0, (rectParticipant.size.height));
    
    CGRect rectTotalSlice = CGRectMake(rectParticipant.size.width+30.0, rectParticipant.origin.y, (rectParticipant.size.width), (rectParticipant.size.height));
    
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
    self.participantPieChart.sliceDirection = CPTPieDirectionCounterClockwise;
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
    //pieChart.labelOffset                   = -5.0;
    //pieChart.labelRotation = M_PI_4;
    
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
                           to:(self.participantHostingView.bounds.size.height * 0.7) / 2
                     duration:0.5
                    withDelay:0.1
               animationCurve:CPTAnimationCurveBounceOut
                     delegate:nil];
        
        [CPTAnimation animate:self.totalSlicePieChart
                     property:@"pieRadius"
                         from:0.0
                           to:(self.totalSliceHostingView.bounds.size.height * 0.7) / 2
                     duration:0.5
                    withDelay:0.1
               animationCurve:CPTAnimationCurveBounceOut
                     delegate:nil];
    }
    
    
}

// how many slices should be displayed
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    NSLog(@"numberOfRecordsForPlot - new");
    NSUInteger result = 0;
    if([(NSString *)plot.identifier isEqualToString:@"participantPieChart"]){
        NSLog(@"numberOfRecordsForPlot - participantPieChart is here!!!");
        result = 12;
    }
    else if ([(NSString *)plot.identifier isEqualToString:@"totalSlicePieChart"]){
        NSLog(@"numberOfRecordsForPlot - totalSlicePieChart is here!!!");
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
            // TEST
            result = [NSNumber numberWithFloat:(arc4random()%8)+1.0];
            
        }
        else if ([(NSString *)plot.identifier isEqualToString:@"totalSlicePieChart"]){

            result = [self.datasource valueForSlotAtIndex:index sliceAtIndex:self.selectedEnergyClockSlice];
        }

    }
    else {
        result = [NSNumber numberWithInt:index];
    }
    
    NSLog(@"numberForPlot - new");
    
    return result;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index
{
    NSLog(@"dataLabelForPlot - new");
    static CPTMutableTextStyle *labelText = nil;
    static NSString *labelValue = nil;
    if (!labelText) {
        labelText= [[CPTMutableTextStyle alloc] init];
        labelText.color = [CPTColor blackColor];
    }
    
    labelValue = @"test";
    
    // Create and return layer with label text
    CPTTextLayer *layer =[[CPTTextLayer alloc] initWithText:labelValue style:labelText];
    return layer;
}

/*-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index
{
    NSLog(@"sliceFillForPieChart - new");
}*/


-(void) reloadPieChartForNewSlice:(NSUInteger)selectedSliceNumber
{
    self.selectedEnergyClockSlice = selectedSliceNumber;
    [self.totalSliceGraph reloadData];
}



@end
