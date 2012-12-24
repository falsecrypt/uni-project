//
//  CircleView.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "CircleView.h"
#import "MonthData.h"

@implementation CircleView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setup
{
    self.contentMode = UIViewContentModeRedraw;
}

- (void)drawCircle:(CGPoint)p withRadius:(CGFloat)radius inContext:(CGContextRef)context
{
	UIGraphicsPushContext(context);
	CGContextBeginPath(context);
	CGContextAddArc(context, p.x, p.y, radius, 0, 2*M_PI, YES);
	CGContextStrokePath(context);
	UIGraphicsPopContext();
}

- (void)drawRect:(CGRect)rect
{
	CGPoint point;
	point.x = self.bounds.origin.x + (self.bounds.size.width/6);
    point.y = self.bounds.origin.y + (self.bounds.size.height/5);
    
    NSLog(@"START point.x = %f, point.y = %f", point.x, point.y);
    
    NSArray *results = [MonthData findAllSortedBy:@"year" ascending:NO];
    // TODO kreise verteilen!
    
    
    // Get the Graphics Context
	CGContextRef context = UIGraphicsGetCurrentContext();
    // Set the circle outerline-width
	CGContextSetLineWidth(context, 5.0);
    // Set the circle outerline-colour
	[[UIColor redColor] setStroke];
    
    for (int i=1; i<[results count]+1; i++) {
        
        //CGFloat size = 10 + (arc4random() % 50);
        //CGFloat size = 10;
        CGFloat radius = [[[results objectAtIndex:i-1] circleradius] floatValue];
        [self drawCircle:point withRadius:radius inContext:context];
        
        if (i%4==0) {
            point.y += (self.bounds.size.height/3.5);
            point.x = self.bounds.origin.x + (self.bounds.size.width/6);
        }
        else {
            point.x += (self.bounds.size.width/4.5);
        }
        NSLog(@"point.x = %f, point.y = %f", point.x, point.y);
    }

}

@end
