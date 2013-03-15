//
//  CPTPieChart+CustomPieChart.m
//  uni-project
//
//  Created by Pavel Ermolin on 15.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "CPTPieChart+CustomPieChart.h"
#import "NSNumberExtensions.h"


/* We override some methods to rotate pie-chart text labels (clockwise rotation relative to center)
 * we need to display the text-labels according to our EnergyClock-Design
 */

CGFloat const addedAngleValueEcoMeter  = 16.0;

@implementation CPTPieChart (CustomPieChart)




-(void)positionLabelAnnotation:(CPTPlotSpaceAnnotation *)label forIndex:(NSUInteger)idx
{
    CPTLayer *contentLayer   = label.contentLayer;
    
    //NSLog(@"positionLabelAnnotation: %@", contentLayer);
    CPTPlotArea *thePlotArea = self.plotArea;
    
    if ( contentLayer && thePlotArea ) {
        CGRect plotAreaBounds = thePlotArea.bounds;
        CGPoint anchor        = self.centerAnchor;
        CGPoint centerPoint   = CPTPointMake(plotAreaBounds.origin.x + plotAreaBounds.size.width * anchor.x,
                                             plotAreaBounds.origin.y + plotAreaBounds.size.height * anchor.y);
        
        NSDecimal plotPoint[2];
        [self.plotSpace plotPoint:plotPoint forPlotAreaViewPoint:centerPoint];
        NSDecimalNumber *xValue = [[NSDecimalNumber alloc] initWithDecimal:plotPoint[CPTCoordinateX]];
        NSDecimalNumber *yValue = [[NSDecimalNumber alloc] initWithDecimal:plotPoint[CPTCoordinateY]];
        label.anchorPlotPoint = [NSArray arrayWithObjects:xValue, yValue, nil];
        
        CGFloat currentWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthNormalized recordIndex : idx];
        if ( self.hidden || isnan(currentWidth) ) {
            contentLayer.hidden = YES;
        }
        else {
            CGFloat radialOffset = [(NSNumber *)[self cachedValueForKey:CPTPieChartBindingPieSliceRadialOffsets recordIndex:idx] cgFloatValue];
            CGFloat labelRadius  = self.pieRadius + self.labelOffset + radialOffset;
            
            CGFloat startingWidth = CPTFloat(0.0);
            if ( idx > 0 ) {
                startingWidth = (CGFloat)[self cachedDoubleForField : CPTPieChartFieldSliceWidthSum recordIndex : idx - 1];
            }
            CGFloat labelAngle = [self radiansForPieSliceValue:startingWidth + currentWidth + addedAngleValueEcoMeter / CPTFloat(2.0)];
            
            label.displacement = CPTPointMake( labelRadius * cos(labelAngle), labelRadius * sin(labelAngle) );
            
            if ( self.labelRotationRelativeToRadius ) {
                CGFloat rotation = [self normalizedPosition:self.labelRotation + labelAngle];
                if ( ( rotation > CPTFloat(0.25) ) && ( rotation < CPTFloat(0.75) ) ) {
                    rotation -= CPTFloat(0.5);
                }
                
                label.rotation = rotation * CPTFloat(2.0 * M_PI);
            }
            
            contentLayer.hidden = NO;
        }
    }
    else {
        label.anchorPlotPoint = nil;
        label.displacement    = CGPointZero;
    }
}


-(CGFloat)radiansForPieSliceValue:(CGFloat)pieSliceValue
{
    CGFloat angle       = self.startAngle;
    CGFloat endingAngle = self.endAngle;
    CGFloat pieRange;
    
    switch ( self.sliceDirection ) {
        case CPTPieDirectionClockwise:
            pieRange = isnan(endingAngle) ? CPTFloat(2.0 * M_PI) : CPTFloat(2.0 * M_PI) - ABS(endingAngle - angle);
            angle   -= pieSliceValue * pieRange;
            break;
            
        case CPTPieDirectionCounterClockwise:
            pieRange = isnan(endingAngle) ? CPTFloat(2.0 * M_PI) : ABS(endingAngle - angle);
            angle   += pieSliceValue * pieRange;
            break;
    }
    return angle;
}


-(CGFloat)normalizedPosition:(CGFloat)rawPosition
{
    CGFloat result = rawPosition;
    
    result /= (CGFloat)(2.0 * M_PI);
    result  = fmod( result, CPTFloat(1.0) );
    if ( result < CPTFloat(0.0) ) {
        result += CPTFloat(1.0);
    }
    
    return result;
}

@end
