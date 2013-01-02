//
//  CircleView.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "CircleView.h"
#import "MonthData.h"

//helper view to identify a circleobject after touch event
///////////////////////////////////////////////////////////
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
///////////////////////////////////////////////////////////

@implementation CircleView

CircleObjectView *currentSelectedCircle;

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
        currentSelectedCircle = [self.circleObjectsDictionary objectForKey:[NSString stringWithFormat:@"%d",touch.view.tag]];
        currentSelectedCircle.backgroundColor = [UIColor greenColor];
        
        //Is anyone listening?
        if([self.delegate respondsToSelector:@selector(setLabelsWithMonth:andConsumption:)])
        {
            MonthData *monthObj = [MonthData findFirstByAttribute:@"month" withValue:[NSNumber numberWithInt:touch.view.tag]];
            NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:kCFDateFormatterLongStyle];
            [formatter setDateFormat:@"MMMM yy"];
            NSLocale *deLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
            formatter.locale = deLocale;
            NSString *monthName = [formatter stringFromDate:monthObj.date];
            NSString *consumptionString = [monthObj.consumption stringValue];
            consumptionString = [consumptionString stringByAppendingString:@" kWh"];
            [self.delegate setLabelsWithMonth:monthName andConsumption:consumptionString ];
        }
        
    }
    //CGPoint currentTouchPosition = [touch locationInView:self];
    //NSLog(@"touchesBegan touch x: %f, y: %f", currentTouchPosition.x, currentTouchPosition.y);
    //NSLog(@"touchesBegan touch x: %@", touch);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (currentSelectedCircle!=nil) {
        currentSelectedCircle.backgroundColor = [UIColor colorWithRed:2/255.0f green:96/255.0f blue:2/255.0f alpha:1.0f];
    }
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
        point.x = self.bounds.origin.x + (self.bounds.size.width/5);
        point.y = self.bounds.origin.y + (self.bounds.size.height/3);
        
        NSLog(@"START point.x = %f, point.y = %f", point.x, point.y);
        
        // NSArray *results = [MonthData findAllSortedBy:@"year" ascending:NO];
        
        
        // Get the Graphics Context
        //CGContextRef context = UIGraphicsGetCurrentContext();
        // Set the circle outerline-width
        //CGContextSetLineWidth(context, 5.0);
        // Set the circle outerline-colour
        //[[UIColor redColor] setStroke];
        
        for (int i=1; i<[self.monthDataObjects count]+1; i++) {
            
            //CGFloat size = 10 + (arc4random() % 50);
            //CGFloat size = 10;
            CGFloat radius = [[[self.monthDataObjects objectAtIndex:i-1] circleradius] floatValue];
            
            //[self drawCircle:point withRadius:radius inContext:context];
            MonthData *monthObj = [self.monthDataObjects objectAtIndex:i-1];
            
            CircleObjectView *circleObjectView = [[CircleObjectView alloc] initWithFrame:CGRectZero];
            //[circleObjectView setBackgroundColor:[UIColor redColor]];
            [circleObjectView setBackgroundColor:[UIColor colorWithRed:2/255.0f green:96/255.0f blue:2/255.0f alpha:1.0f]];

            //circleObjectView.frame = CGRectMake(point.x, point.y, 2*radius, 2*radius);
            circleObjectView.layer.cornerRadius = radius;
            circleObjectView.bounds = CGRectMake(0, 0, 2*radius, 2*radius); //bounds of the view’s own coordinates
            circleObjectView.center = CGPointMake(point.x, point.y); //center of frame, superview’s coordinates
            circleObjectView.tag = [monthObj.month intValue]; //unique identifier
            [[circleObjectView layer] setShadowOffset:CGSizeMake(0, 1)];
            [[circleObjectView layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
            [[circleObjectView layer] setShadowRadius:3.0];
            [[circleObjectView layer] setShadowOpacity:0.8];
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
                point.y += (self.bounds.size.height/4);
                point.x = self.bounds.origin.x + (self.bounds.size.width/5);
            }
            else {
                point.x += (self.bounds.size.width/5);
            }
        }
    }
    
}

@end
