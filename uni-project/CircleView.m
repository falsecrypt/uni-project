//
//  CircleView.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "CircleView.h"
#import "MonthData.h"
#import "LastMonthsViewController.h"

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


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    if ([touch.view isKindOfClass: CircleObjectView.class]) {
        // Get the CircleObjectView object from the dictionary
        currentSelectedCircle = (self.circleObjectsDictionary)[[NSString stringWithFormat:@"%d",touch.view.tag]];
        if ([(self.monthColors)[[NSString stringWithFormat:@"%i",currentSelectedCircle.tag]] isEqual:[UIColor clearColor]]) {
            currentSelectedCircle.backgroundColor = (self.monthColors)[[NSString stringWithFormat:@"%i",currentSelectedCircle.tag]];
            currentSelectedCircle.layer.borderColor = [[UIColor greenColor] colorWithAlphaComponent:1.0f].CGColor;
        }
        else {
        currentSelectedCircle.backgroundColor = [(self.monthColors)[[NSString stringWithFormat:@"%i",currentSelectedCircle.tag]] colorWithAlphaComponent: 1.0f];
        }
        
        //Is anyone listening?
        if([self.delegate respondsToSelector:@selector(setLabelsWithMonth:andConsumption:)])
        {
            MonthData *monthObj = [MonthData findFirstByAttribute:@"month" withValue:@(touch.view.tag)];
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
        if ([(self.monthColors)[[NSString stringWithFormat:@"%i",currentSelectedCircle.tag]] isEqual:[UIColor clearColor]]) {
            currentSelectedCircle.layer.borderColor = [[UIColor greenColor] colorWithAlphaComponent:0.7f].CGColor;
        }
        else {
            currentSelectedCircle.backgroundColor = (self.monthColors)[[NSString stringWithFormat:@"%i",currentSelectedCircle.tag]];
        }
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
        
        //NSLog(@"START point.x = %f, point.y = %f", point.x, point.y);
        [self calculateColorValuesForMonths:self.monthDataObjects];

        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        NSLocale *deLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
        
        for (int i=1; i<[self.monthDataObjects count]+1; i++) {
            
            CGFloat radius = [[(self.monthDataObjects)[i-1] circleradius] floatValue];
            MonthData *monthObj = (self.monthDataObjects)[i-1];
            CircleObjectView *circleObjectView = [[CircleObjectView alloc] initWithFrame:CGRectZero];
            [circleObjectView setBackgroundColor:(self.monthColors)[[monthObj.month stringValue]]];
            NSLog(@"color: %@", (self.monthColors)[[monthObj.month stringValue]]);
            circleObjectView.layer.cornerRadius = radius;
            circleObjectView.bounds = CGRectMake(0, 0, 2*radius, 2*radius); //bounds of the view’s own coordinates
            //for consumtion = 0kWh
            if (radius==0) {
                NSLog(@"radius=0!");
                circleObjectView.layer.borderColor = [[UIColor greenColor] colorWithAlphaComponent:0.7f].CGColor;
                circleObjectView.layer.borderWidth = 3.0f;
                circleObjectView.layer.cornerRadius = 20.0f;
                [circleObjectView setBackgroundColor: [UIColor clearColor]];
                circleObjectView.bounds = CGRectMake(0, 0, 2*20.0f, 2*20.0f); //bounds of the view’s own coordinates
                //[circleObjectView setClipsToBounds: YES];
            }
            circleObjectView.center = CGPointMake(point.x, point.y); //center of frame, superview’s coordinates
            circleObjectView.tag = [monthObj.month intValue]; //unique identifier
            [[circleObjectView layer] setShadowOffset:CGSizeMake(0, 1)];
            [[circleObjectView layer] setShadowColor:[[UIColor darkGrayColor] CGColor]];
            [[circleObjectView layer] setShadowRadius:3.0];
            [[circleObjectView layer] setShadowOpacity:0.8];
            [self addSubview:circleObjectView];
            (self.circleObjectsDictionary)[[monthObj.month stringValue]] = circleObjectView;

            //NSLog(@"point.x = %f, point.y = %f", point.x, point.y);
            // Add a label with a month's name
            CGFloat labelWidth = 2*radius > 50 ? 2.0*radius : 50.0f;
            CGFloat labelX = labelWidth==50.0f ? point.x-25.0f : point.x-radius;
            // CGRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height)
            UILabel *monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelX, point.y+60, labelWidth, 30)];
            // Configure that label
            
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setDateFormat:@"MMM yy"];
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
                point.y += (self.bounds.size.height/4.5);
                point.x = self.bounds.origin.x + (self.bounds.size.width/5);
            }
            else {
                point.x += (self.bounds.size.width/5);
            }
        }
        LastMonthsViewController *lmvc = (LastMonthsViewController*)self.delegate;
        if (!lmvc.instanceWasCached) {
            [self animateLastCircleAtFirstStart];
        }

    }
    
}

- (void) animateLastCircleAtFirstStart {
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        MonthData *monthLastObj = (self.monthDataObjects)[[self.monthDataObjects count]-1];
        CircleObjectView *currentCircle =
        (self.circleObjectsDictionary)[[NSString stringWithFormat:@"%i",[[monthLastObj month]intValue]]];
        //NSLog(@"self.circleObjectsDictionary = %@, self.monthDataObjects = %@", self.circleObjectsDictionary, self.monthDataObjects);
        [UIView animateWithDuration:0.3 animations:^{
            UIColor *animColorStart = [(self.monthColors)[[NSString stringWithFormat:@"%i",currentCircle.tag]] colorWithAlphaComponent: 1.0f];
            currentCircle.backgroundColor = animColorStart;
        }];
        [UIView animateWithDuration:0.3 animations:^{
            UIColor *animColorEnd = (self.monthColors)[[NSString stringWithFormat:@"%i",currentCircle.tag]];
            currentCircle.backgroundColor = animColorEnd;
        }];
        
        //Is anyone listening?
        if([self.delegate respondsToSelector:@selector(setLabelsWithMonth:andConsumption:)]){
            MonthData *monthObj = (self.monthDataObjects)[[self.monthDataObjects count]-1];
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
    });
}

- (void) calculateColorValuesForMonths: (NSArray*)monthDataObjects {
    if (!self.monthColors) {
        self.monthColors = [[NSMutableDictionary alloc] init];
    }
    float avgConsumption = 0.0f;
    float specificYearConsumption = 0.0f;
    // Color Management
    for (MonthData *month in monthDataObjects) {

        avgConsumption = [[month consumption] floatValue]*12.0;
        specificYearConsumption = avgConsumption/OfficeArea;
        if (specificYearConsumption <= 55.0) {
            float redComponent = 255.0f - ((55.0f - specificYearConsumption)*(256.0f/55.0f));
            if (redComponent < 0.0) {
                redComponent = 0.0;
            }
            UIColor *monthColor = [UIColor colorWithRed:redComponent/255.0f green:1.0f blue:0.0f alpha:0.7f];
            if (specificYearConsumption==0) {
                monthColor = [UIColor clearColor];
            }
            NSLog(@"___redComponent: %f and specificYearConsumption: %f", redComponent, specificYearConsumption);
            [self.monthColors setValue:monthColor forKey:[NSString stringWithFormat:@"%i",[[month month]intValue]]];
        }
        else {
            float greenComponent = 255.0f - ((specificYearConsumption - 55.0f)*(256.0f/25.0f));
            if (greenComponent < 0.0) {
                greenComponent = 0.0;
            }
            UIColor *monthColor = [UIColor colorWithRed:1.0f green:greenComponent/255.0f blue:0.0f alpha:0.7f];
            NSLog(@"___greenComponent: %f and specificYearConsumption: %f", greenComponent, specificYearConsumption);
            [self.monthColors setValue:monthColor forKey:[NSString stringWithFormat:@"%i",[[month month]intValue]]];
        }

     }

}

@end
