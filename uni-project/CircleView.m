//
//  CircleView.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "CircleView.h"
#import "MonthData.h"


@interface CircleObjectView : UIView


@end

@implementation CircleObjectView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

@end

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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass: CircleObjectView.class]) {
        // Get the CircleObjectView object from the dictionary
        CircleObjectView *circle = [self.circleObjectsDictionary objectForKey:[NSString stringWithFormat:@"%d",touch.view.tag]];
        circle.backgroundColor = [UIColor greenColor];
    }
    //CGPoint currentTouchPosition = [touch locationInView:self];
    //NSLog(@"touchesBegan touch x: %f, y: %f", currentTouchPosition.x, currentTouchPosition.y);
    //NSLog(@"touchesBegan touch x: %@", touch);
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
    if (self.monthDataObjects!=nil) {
        
        CGPoint point;
        self.circleObjectsDictionary = [[NSMutableDictionary alloc] init];
        point.x = self.bounds.origin.x + (self.bounds.size.width/6);
        point.y = self.bounds.origin.y + (self.bounds.size.height/5);
        
        NSLog(@"START point.x = %f, point.y = %f", point.x, point.y);
        
        // NSArray *results = [MonthData findAllSortedBy:@"year" ascending:NO];
        // TODO kreise verteilen!
        
        
        // Get the Graphics Context
        CGContextRef context = UIGraphicsGetCurrentContext();
        // Set the circle outerline-width
        CGContextSetLineWidth(context, 5.0);
        // Set the circle outerline-colour
        [[UIColor redColor] setStroke];
        
        for (int i=1; i<[self.monthDataObjects count]+1; i++) {
            
            //CGFloat size = 10 + (arc4random() % 50);
            //CGFloat size = 10;
            CGFloat radius = [[[self.monthDataObjects objectAtIndex:i-1] circleradius] floatValue];
            
            //[self drawCircle:point withRadius:radius inContext:context];
            MonthData *monthObj = [self.monthDataObjects objectAtIndex:i-1];
            
            CircleObjectView *circleObjectView = [[CircleObjectView alloc] init];
            [circleObjectView setBackgroundColor:[UIColor redColor]];
            circleObjectView.frame = CGRectMake(point.x, point.y, 2*radius, 2*radius);
            circleObjectView.layer.cornerRadius = radius;
            circleObjectView.tag = [monthObj.month intValue];
            [self addSubview:circleObjectView];
            [self.circleObjectsDictionary setObject:circleObjectView forKey:[monthObj.month stringValue]];

            NSLog(@"point.x = %f, point.y = %f", point.x, point.y);
            // Add a label with a month's name
            CGFloat labelWidth = 2*radius > 50 ? 2.0*radius : 50.0f;
            CGFloat labelX = labelWidth==50.0f ? point.x-25.0f : point.x-radius;
            // CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
            UILabel *monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, point.y+60, labelWidth, 30)];
            // Configure that label
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setDateFormat:@"MMM yy"];
            NSLocale *deLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            formatter.locale = deLocale;
            NSString *monthName = [formatter stringFromDate:monthObj.date];
            monthLabel.text = monthName;
            monthLabel.textColor = [UIColor blackColor];
            monthLabel.textAlignment = NSTextAlignmentCenter;
            monthLabel.tag = 10;
            monthLabel.backgroundColor = [UIColor clearColor];
            monthLabel.font = [UIFont fontWithName:@"Verdana" size:14.0];
            monthLabel.hidden = NO;
            //monthLabel.highlighted = YES;
            //monthLabel.highlightedTextColor = [UIColor blueColor];
            monthLabel.lineBreakMode = YES;
            monthLabel.numberOfLines = 0;
            [self addSubview:monthLabel];
            
            if (i%4==0) {
                point.y += (self.bounds.size.height/3.5);
                point.x = self.bounds.origin.x + (self.bounds.size.width/6);
            }
            else {
                point.x += (self.bounds.size.width/4.5);
            }
        }
    }
    
}

@end
