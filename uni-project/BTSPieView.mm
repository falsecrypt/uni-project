//
//  BTSPieView.m
//
//  Copyright (c) 2011 Brian Coyner. All rights reserved.
//

#import "BTSPieView.h"
#import <QuartzCore/QuartzCore.h>

#import "BTSPieViewValues.h"
#import "BTSPieLayer.h"
#import "BTSSliceLayer.h"

static float const kBTSPieViewSelectionOffset = 30.0f;

// Used as a CAAnimationDelegate when animating existing slices
@interface BTSSliceLayerExistingLayerDelegate : NSObject
@property(nonatomic, weak) id animationDelegate;
@end

@interface BTSSliceLayerAddAtBeginningLayerDelegate : NSObject
@property(nonatomic, weak) id animationDelegate;
@end

@interface BTSSliceLayerAddInMiddleLayerDelegate : NSObject
@property(nonatomic, weak) id animationDelegate;
@property(nonatomic) CGFloat initialSliceAngle;
@end

@interface BTSPieView () {
    
    NSInteger _selectedSliceIndex;
    
    CADisplayLink *_displayLink;
    
    NSMutableArray *_animations;
    NSMutableArray *_layersToRemove;
    NSMutableArray *_deletionStack;
    
    BTSSliceLayerExistingLayerDelegate *_existingLayerDelegate;
    BTSSliceLayerAddAtBeginningLayerDelegate *_addAtBeginningLayerDelegate;
    BTSSliceLayerAddInMiddleLayerDelegate *_addInMiddleLayerDelegate;
    
    NSNumberFormatter *_labelFormatter;
    
    CGPoint _center;
    CGFloat _radius;
    
    NSArray *radiusArray; // from EnergyClockViewController
    NSArray *temperatureValuesArray;
    NSDictionary *temperatureUserValues; // hour => {userID => Temperature}
    NSArray *slotValuesForSlice;
    
    __block BTSSliceLayer *touchedSliceLayerInside;
    BTSSliceLayer *touchedContainerSliceLayer;
    BTSSliceLayer *touchedContainerSliceLayerPrev;
    NSUInteger touchedSliceLayerIndex;
    __block CGFloat touchedStartAngle;
    __block CGFloat touchedEndAngle;
    
    NSArray *participants;
}

// C-helper functions
CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle);

CGPathRef CGPathCreateArcLineForAngle(CGPoint center, CGFloat radius, CGFloat angle, BOOL drawArrow);

void BTSUpdateLabelPosition(CALayer *labelLayer, CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle);

void BTSUpdateAllLayers(BTSPieLayer *pieLayer, NSUInteger layerIndex, CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle);

void BTSUpdateLayers(NSArray *sliceLayers, NSArray *labelLayers, NSArray *tmepLabelLayers, NSArray *lineLayers, NSUInteger layerIndex, CGPoint center, CGFloat radius, NSArray *radiusArray, CGFloat startAngle, CGFloat endAngle);

CGFloat BTSLookupPreviousLayerAngle(NSArray *pieLayers, NSUInteger currentPieLayerIndex, CGFloat defaultAngle);

@end

@implementation BTSPieView

@synthesize dataSource = _dataSource;
@synthesize delegate = _delegate;
@synthesize animationDuration = _animationDuration;
@synthesize highlightSelection = _highlightSelection;

#pragma mark - Custom Layer Initialization

+ (Class)layerClass
{
    return [BTSPieLayer class];
}

#pragma mark - View Initialization

- (void)initView
{
    _animationDuration = 0.2f;
    _highlightSelection = NO;
    
    _labelFormatter = [[NSNumberFormatter alloc] init];
    [_labelFormatter setNumberStyle:NSNumberFormatterPercentStyle];
    
    _selectedSliceIndex = -1;
    _animations = [[NSMutableArray alloc] init];
    
    _layersToRemove = [[NSMutableArray alloc] init];
    _deletionStack = [[NSMutableArray alloc] init];
    
    _existingLayerDelegate = [[BTSSliceLayerExistingLayerDelegate alloc] init];
    [_existingLayerDelegate setAnimationDelegate:self];
    
    _addAtBeginningLayerDelegate = [[BTSSliceLayerAddAtBeginningLayerDelegate alloc] init];
    [_addAtBeginningLayerDelegate setAnimationDelegate:self];
    
    _addInMiddleLayerDelegate = [[BTSSliceLayerAddInMiddleLayerDelegate alloc] init];
    [_addInMiddleLayerDelegate setAnimationDelegate:self];
    
    // Target object and a selector to be called when the screen is updated
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateTimerFired:)];
    [_displayLink setPaused:YES]; // disable notifications
                                  // the selector on the target is called when the screen’s contents need to be updated
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    participants = [[NSArray alloc] initWithObjects:
                             [NSNumber numberWithInteger:FirstSensorID],
                             [NSNumber numberWithInteger:SecondSensorID],
                             [NSNumber numberWithInteger:ThirdSensorID], nil];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initView];
    }
    
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initView];
    }
    
    return self;
}

#pragma mark - View Clean Up

- (void)dealloc
{
    [_displayLink invalidate];
    _displayLink = nil;
}

#pragma mark - Layout Hack

- (void)layoutSubviews
{
    // Calculate the center and radius based on the parent layer's bounds. This version
    // of the BTSPieChart assumes the view does not change size.
    CGRect parentLayerBounds = [[self layer] bounds];
    CGFloat centerX = parentLayerBounds.size.width / 2.0f;
    CGFloat centerY = parentLayerBounds.size.height / 2.0f;
    _center = CGPointMake(centerX, centerY);
    
    // Reduce the radius just a bit so the the pie chart layers do not hug the edge of the view.
    _radius = MIN(centerX, centerY) - 20;
    
    [self refreshLayers];
}

- (void)beginCATransaction
{
    [CATransaction begin];
    [CATransaction setAnimationDuration:_animationDuration];
}

#pragma mark - Reload Pie View (No Animation)

- (BTSSliceLayer *)insertSliceLayerAtIndex:(NSUInteger)index /*color:(UIColor *)color*/
{
    
    BTSSliceLayer *sliceLayer = [BTSSliceLayer layerWithoutColor];
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    [[pieLayer sliceLayers] insertSublayer:sliceLayer atIndex:index];
    
    // Changed by Pavel Ermolin //
    //NSLog(@"insertSliceLayerAtIndex");
    
    // Insert sublayers for our slots (number of participants/users)
    if (_dataSource) {
        NSUInteger slotCount = [_dataSource numberOfSlotsInPieView:self];
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieView:self];
        NSMutableArray *slotValues = [[NSMutableArray alloc] init];
        NSLog(@"number of Slots: %i", slotCount);
        for (int i=0; i<slotCount; i++) {
            UIColor *slotColor = [_delegate pieView:self
                                colorForSlotAtIndex:(slotCount-1)-i      // Slot Number
                                       sliceAtIndex:index
                                         sliceCount:sliceCount];
            
            BTSSliceLayer *sliceLayerInside = [BTSSliceLayer layerWithColor:slotColor.CGColor];
            CGFloat slotValue = [_dataSource pieView:self valueForSlotAtIndex:i sliceAtIndex:index];
            slotValues[i] = [NSNumber numberWithFloat:slotValue];
            [sliceLayer insertSublayer:sliceLayerInside atIndex:i];
        }
        sliceLayer.slotValues = slotValues;
        NSLog(@"sliceLayer.slotValues: %@", sliceLayer.slotValues);
    }
    
    //NSLog(@"[sliceLayer sublayers]: %@", [sliceLayer sublayers]);
    //*************************//
    
    return sliceLayer;
}

- (CATextLayer *)insertLabelLayerAtIndex:(NSUInteger)index value:(double)value
{
    CATextLayer *labelLayer = [BTSPieView createLabelLayer];
    
    //[labelLayer setString:[_labelFormatter stringFromNumber:[NSNumber numberWithDouble:value]]]; // 4%
    NSString *timeString = [[NSString alloc] init];
    if ((index*2) < 10) {
        timeString = [NSString stringWithFormat:@"0%i:00",index*2];
    }
    else {
        timeString = [NSString stringWithFormat:@"%i:00",index*2];
    }
    [labelLayer setString:timeString];
    [labelLayer setForegroundColor:[UIColor colorWithRed:80/255.0f green:80/255.0f blue:80/255.0f alpha:1.0f].CGColor];
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    CALayer *layer = [pieLayer labelLayers];
    [layer insertSublayer:labelLayer atIndex:index];
    return labelLayer;
}

- (CATextLayer *)insertTemperatureLabelLayerAtIndex:(NSUInteger)index value:(int)value hour:(NSUInteger)hourValue  {
    
    CATextLayer *labelLayer = [BTSPieView createLabelLayer];
    NSDictionary *userTemperatureValues = [temperatureUserValues objectForKey:@(hourValue)];
    NSLog(@"@(hourValue): %@", @(hourValue));
    NSLog(@"userTemperatureValues: %@", userTemperatureValues);
    if ([[userTemperatureValues allKeys] count] > 0) {
        
        NSArray *allKeys = [[userTemperatureValues allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        NSLog(@"allKeys: %@", allKeys);
        // Method for getting the correct color:
        // 1. Sort all User IDs in the array [4,3,5] -> [3,4,5]
        // 2. Given the User ID we can now calculate the color-index, e.g UserID 5 has color-index 2 in the color-array
        for (int j=0; j<[allKeys count]; j++) {
            CATextLayer *anotherLayer = [BTSPieView createLabelLayer];
            int index = 0;
            for (int i = 0; i < [participants count]; i++) {
                if ([allKeys[j] integerValue] == [participants[i] integerValue]) {
                    break;
                }
                else {
                    index++;
                }
            }
            NSLog(@"index: %i", index);
            CGColor *userLabelColor = [_dataSource getColorForTempLabel:index].CGColor;
            NSLog(@"userLabelColor: %@", userLabelColor);
            [anotherLayer setForegroundColor: userLabelColor];
            NSNumber *temperatureNumber = [userTemperatureValues objectForKey:allKeys[j]];
            //NSString *temperature = [temperatureNumber stringValue];
            NSString *temperature = [NSString stringWithFormat:@"%@%@",temperatureNumber, @"\u00B0"];
            [anotherLayer setString:temperature];
            //[anotherLayer setAnchorPoint:CGPointMake(-0.3, -0.3)];
            //[anotherLayer setBackgroundColor:[UIColor grayColor].CGColor];
            [labelLayer addSublayer:anotherLayer];
        }
        
    }
    //[labelLayer setString:[_labelFormatter stringFromNumber:[NSNumber numberWithDouble:value]]]; // 4%
    NSString *tempString = [[NSString alloc] init];
    tempString = [NSString stringWithFormat:@"%i%@", value, @"\u00B0"]; //number with degree sign
    [labelLayer setString:tempString];
    [labelLayer setForegroundColor:[UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1.0f].CGColor];
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    CALayer *layer = [pieLayer tempLabelLayers]; // special labels for temperature
    [layer insertSublayer:labelLayer atIndex:index];
    return labelLayer;
}

- (CATextLayer *)insertUserTemperatureLabelLayerAtIndex:(NSUInteger)index hour:(NSUInteger)hourValue {
//    CATextLayer *labelLayer = [BTSPieView createLabelLayer];
//    NSDictionary *userTemperatureValues = [temperatureUserValues objectForKey:@(hourValue)];
//    NSArray *allKeys = [[userTemperatureValues allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
//    for (int i=0; i<[allKeys count]; i++) {
//        CATextLayer *anotherLayer = [BTSPieView createLabelLayer];
//        CGColor *userLabelColor = [_dataSource getColorForTempLabel:[allKeys[i] integerValue]].CGColor;
//        [anotherLayer setForegroundColor: userLabelColor];
//        NSString *temperature = [userTemperatureValues objectForKey:@([allKeys[i] integerValue])];
//        [temperature stringByAppendingString:[NSString stringWithFormat:@"%@", @"\u00B0" ]];
//        [anotherLayer setString:temperature];
//        [anotherLayer setBackgroundColor:[UIColor greenColor].CGColor];
//        [labelLayer addSublayer:anotherLayer];
//    }
//    
//    NSString *tempString = [[NSString alloc] init];
//    
//    
//    //tempString = [NSString stringWithFormat:@"%i%@", value, @"\u00B0"]; //number with degree sign
//    [labelLayer setString:tempString];
//    [labelLayer setForegroundColor:[UIColor colorWithRed:110/255.0f green:110/255.0f blue:110/255.0f alpha:1.0f].CGColor];
//    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
//    CALayer *layer = [pieLayer tempLabelLayers]; // special labels for temperature
//    [layer insertSublayer:labelLayer atIndex:index];
//    return labelLayer;
}

- (CAShapeLayer *)insertLineLayerAtIndex:(NSUInteger)index color:(UIColor *)color
{
    
    CAShapeLayer *lineLayer = [CAShapeLayer layer];
    [lineLayer setStrokeColor:color.CGColor];
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    [[pieLayer lineLayers] insertSublayer:lineLayer atIndex:index];
    
    return lineLayer;
}

- (void)reloadData
{
    NSLog(@"reloadData");
    //[CATransaction begin];
    //[CATransaction setDisableActions:YES];
    
    BTSPieLayer *parentLayer = (BTSPieLayer *) [self layer];
    [parentLayer removeAllPieLayers];
    
    if (_dataSource) {
        
        [self beginCATransaction];
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieView:self];
        radiusArray = [_dataSource getRadiusArray];
        slotValuesForSlice = [_dataSource getSlotValuesForSliceArray];
        temperatureValuesArray = [_dataSource getTemperatureValues];
        temperatureUserValues = [_dataSource getUserTemperatureValues];
        NSLog(@"setting temperatureUserValues: %@", temperatureUserValues);
        BTSPieViewValues values(sliceCount, ^(NSUInteger index) {
            return [_dataSource pieView:self valueForSliceAtIndex:index];
        });
        
        CGFloat startAngle = (CGFloat) -M_PI_2;
        CGFloat endAngle = startAngle;
        //NSLog(@"sliceCount: %i", sliceCount);
        for (NSUInteger sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++) {
            
            endAngle += values.angles()[sliceIndex];
            //NSLog(@"reloadData: endAngle: %f", endAngle);
            //UIColor *color = [_delegate pieView:self colorForSlotAtIndex:sliceIndex sliceAtIndex:sliceIndex sliceCount:sliceCount];
            BTSSliceLayer *sliceLayer = [self insertSliceLayerAtIndex:sliceIndex];
            [sliceLayer setSliceAngle:endAngle];
            [self insertLabelLayerAtIndex:sliceIndex value:values.percentages()[sliceIndex]];
            NSUInteger hourValue = sliceIndex*2;
            [self insertTemperatureLabelLayerAtIndex:sliceIndex value:[temperatureValuesArray[sliceIndex] integerValue] hour:hourValue];
            //[self insertUserTemperatureLabelLayerAtIndex:sliceIndex hour:hourValue];
            [self insertLineLayerAtIndex:sliceIndex color:[UIColor blackColor]];
            //BTSPieLayer *pieLayer = (BTSPieLayer *)[self layer];
            //NSArray *sliceLayers = [[pieLayer sliceLayers] sublayers];
            //BTSSliceLayer *sliceLayer = (BTSSliceLayer *) [sliceLayers objectAtIndex:sliceIndex];
            //NSArray *slotValues = sliceLayer.slotValues;
            BTSUpdateAllLayers(parentLayer, sliceIndex, _center, _radius, radiusArray, slotValuesForSlice, startAngle, endAngle);
            
            startAngle = endAngle;
        }
        [CATransaction commit];
    }
    //[CATransaction setDisableActions:NO];
    // [CATransaction commit];
}

#pragma mark - Insert Slice

- (void)insertSliceAtIndex:(NSUInteger)indexToInsert animate:(BOOL)animate
{
    //NSLog(@"insertSliceAtIndex: animate: %i", animate);
    if (!animate) {
        [self reloadData];
        return;
    }
    
    if (_dataSource) {
        
        [self beginCATransaction];
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieView:self];
        BTSPieViewValues values(sliceCount, ^(NSUInteger sliceIndex) {
            return [_dataSource pieView:self valueForSliceAtIndex:sliceIndex];
        });
        
        CGFloat startAngle = (CGFloat) -M_PI_2;
        CGFloat endAngle = startAngle;
        
        for (NSUInteger currentIndex = 0; currentIndex < sliceCount; currentIndex++) {
            
            // Make no implicit transactions are creating (e.g. when adding the new slice we don't want a "fade in" effect)
            [CATransaction setDisableActions:YES];
            
            endAngle += values.angles()[currentIndex];
            
            BTSSliceLayer *sliceLayer;
            if (indexToInsert == currentIndex) {
                sliceLayer = [self insertSliceAtIndex:currentIndex values:&values startAngle:startAngle endAngle:endAngle];
            } else {
                sliceLayer = [self updateSliceAtIndex:currentIndex values:&values];
            }
            
            [CATransaction setDisableActions:NO];
            
            // Remember because "sliceAngle" is a dynamic property this ends up calling the actionForLayer:forKey: method on each layer with a non-nil delegate
            //NSLog(@"<insertSliceAtIndex> endAngle: %f", endAngle);
            [sliceLayer setSliceAngle:endAngle];
            [sliceLayer setDelegate:nil];
            
            startAngle = endAngle;
        }
        
        [CATransaction commit];
    }
}

- (BTSSliceLayer *)insertSliceAtIndex:(NSUInteger)index values:(BTSPieViewValues*)values startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle
{
    //NSLog(@"insertSliceAtIndex: values: startAngle: endAngle:");
    NSUInteger sliceCount = values->count();
    //NSLog(@"sliceCount: %i", sliceCount);
    //UIColor *color = [_delegate pieView:self colorForSliceAtIndex:index sliceCount:sliceCount];
    
    BTSSliceLayer *sliceLayer = [self insertSliceLayerAtIndex:index];
    id delegate = [self delegateForSliceAtIndex:index sliceCount:sliceCount];
    [sliceLayer setDelegate:delegate];
    
    CGFloat initialLabelAngle = [self initialLabelAngleForSliceAtIndex:index sliceCount:sliceCount startAngle:startAngle endAngle:endAngle];
    //NSLog(@"insertSliceAtIndex, angle calling");
    CATextLayer *labelLayer = [self insertLabelLayerAtIndex:index value:values->percentages()[index]];
    BTSUpdateLabelPosition(labelLayer, _center, _radius, initialLabelAngle, initialLabelAngle);
    
    // Special Case...
    // If the delegate is the "add in middle", then the "initial label angle" is also the delegate's starting angle.
    if (delegate == _addInMiddleLayerDelegate) {
        [_addInMiddleLayerDelegate setInitialSliceAngle:initialLabelAngle];
    }
    
    [self insertLineLayerAtIndex:index color:[UIColor blackColor]];
    
    return sliceLayer;
}

- (BTSSliceLayer *)updateSliceAtIndex:(NSUInteger)currentIndex values:(BTSPieViewValues*)values
{
    //NSLog(@"updateSliceAtIndex:values:");
    BTSPieLayer *pieLayer = (BTSPieLayer *)[self layer];
    
    NSArray *sliceLayers = [[pieLayer sliceLayers] sublayers];
    BTSSliceLayer *sliceLayer = (BTSSliceLayer *) [sliceLayers objectAtIndex:currentIndex];
    [sliceLayer setDelegate:_existingLayerDelegate];
    
    NSArray *labelLayers = [[pieLayer labelLayers] sublayers];
    CATextLayer *labelLayer = [labelLayers objectAtIndex:currentIndex];
    double value = values->percentages()[currentIndex];
    NSString *label = [_labelFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
    //NSLog(@"label: %@", label);
    [labelLayer setString:label];
    return sliceLayer;
}

- (id)delegateForSliceAtIndex:(NSUInteger)currentIndex sliceCount:(NSUInteger)sliceCount
{
    // The inserted layer animates differently depending on where the new layer is inserted.
    id delegate;
    if (currentIndex == 0) {
        delegate = _addAtBeginningLayerDelegate;
    } else if (currentIndex + 1 == sliceCount) {
        delegate = nil;
    } else {
        delegate = _addInMiddleLayerDelegate;
    }
    return delegate;
}

- (CGFloat)initialLabelAngleForSliceAtIndex:(NSUInteger)currentIndex sliceCount:(NSUInteger)sliceCount startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle
{
    // The inserted layer animates differently depending on where the new layer is inserted.
    CGFloat initialLabelAngle;
    
    /*if (currentIndex == 0) {
     initialLabelAngle = startAngle;
     } else if (currentIndex + 1 == sliceCount) {
     initialLabelAngle = endAngle;
     } else {
     BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
     NSArray *pieLayers = [[pieLayer sliceLayers] sublayers];
     initialLabelAngle = BTSLookupPreviousLayerAngle(pieLayers, currentIndex, (CGFloat)-M_PI_2);
     }*/
    
    initialLabelAngle = startAngle;
    //NSLog(@"initialLabelAngle: %f", initialLabelAngle);
    return initialLabelAngle;
}

#pragma mark - Remove Slice

- (void)removeSliceAtIndex:(NSUInteger)indexToRemove animate:(BOOL)animate
{
    if (!animate) {
        [self reloadData];
        return;
    }
    
    if (_delegate) {
        
        BTSPieLayer *parentLayer = (BTSPieLayer *) [self layer];
        NSArray *sliceLayers = [[parentLayer sliceLayers] sublayers];
        NSArray *labelLayers = [[parentLayer labelLayers] sublayers];
        NSArray *lineLayers = [[parentLayer lineLayers] sublayers];
        
        CAShapeLayer *sliceLayerToRemove = [sliceLayers objectAtIndex:indexToRemove];
        CATextLayer *labelLayerToRemove = [labelLayers objectAtIndex:indexToRemove];
        CALayer *lineLayerToRemove = [lineLayers objectAtIndex:indexToRemove];
        
        [_layersToRemove addObjectsFromArray:[NSArray arrayWithObjects:lineLayerToRemove, sliceLayerToRemove, labelLayerToRemove, nil]];
        
        [self beginCATransaction];
        
        NSUInteger current = [_layersToRemove count];
        [CATransaction setCompletionBlock:^{
            if (current == [_layersToRemove count]) {
                [_layersToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
                    [obj removeFromSuperlayer];
                }];
                
                [_layersToRemove removeAllObjects];
            }
        }];
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieView:self];
        
        if (sliceCount > 0) {
            
            [CATransaction setDisableActions:YES];
            [labelLayerToRemove setHidden:YES];
            [CATransaction setDisableActions:NO];
            
            BTSPieViewValues values(sliceCount, ^(NSUInteger index) {
                return [_dataSource pieView:self valueForSliceAtIndex:index];
            });
            
            CGFloat startAngle = (CGFloat) -M_PI_2;
            CGFloat endAngle = startAngle;
            for (NSUInteger sliceIndex = 0; sliceIndex < [sliceLayers count]; sliceIndex++) {
                
                BTSSliceLayer *sliceLayer = (BTSSliceLayer *) [sliceLayers objectAtIndex:sliceIndex];
                [sliceLayer setDelegate:_existingLayerDelegate];
                
                NSUInteger modelIndex = sliceIndex <= indexToRemove ? sliceIndex : sliceIndex - 1;
                
                CGFloat currentEndAngle;
                if (sliceIndex == indexToRemove) {
                    currentEndAngle = endAngle;
                } else {
                    double value = values.percentages()[modelIndex];
                    NSString *label = [_labelFormatter stringFromNumber:[NSNumber numberWithDouble:value]];
                    CATextLayer *labelLayer = [labelLayers objectAtIndex:sliceIndex];
                    [labelLayer setString:label];
                    
                    endAngle += values.angles()[modelIndex];
                    currentEndAngle = endAngle;
                }
                
                [sliceLayer setSliceAngle:currentEndAngle];
            }
        }
        
        [CATransaction commit];
        
        [self maybeNotifyDelegateOfSelectionChangeFrom:_selectedSliceIndex to:-1];
    }
}

#pragma mark - Reload Slice Value

- (void)reloadSliceAtIndex:(NSUInteger)index animate:(BOOL)animate
{
    //NSLog(@"reloadSliceAtIndex:animate:");
    if (!animate) {
        [self reloadData];
        return;
    }
    
    if (_dataSource) {
        
        [self beginCATransaction];
        
        BTSPieLayer *parentLayer = (BTSPieLayer *) [self layer];
        NSArray *sliceLayers = [[parentLayer sliceLayers] sublayers];
        NSArray *labelLayers = [[parentLayer labelLayers] sublayers];
        
        NSUInteger sliceCount = [_dataSource numberOfSlicesInPieView:self];
        
        BTSPieViewValues values(sliceCount, ^(NSUInteger sliceIndex) {
            return [_dataSource pieView:self valueForSliceAtIndex:sliceIndex];
        });
        
        // For simplicity, the start angle is always zero... no reason it can't be any valid angle in radians.
        CGFloat endAngle = (CGFloat) -M_PI_2;
        
        // We are updating existing layer values (viz. not adding, or removing). We simply iterate each slice layer and
        // adjust the start and end angles.
        for (NSUInteger sliceIndex = 0; sliceIndex < sliceCount; sliceIndex++) {
            
            BTSSliceLayer *sliceLayer = (BTSSliceLayer *) [sliceLayers objectAtIndex:sliceIndex];
            [sliceLayer setDelegate:_existingLayerDelegate];
            
            endAngle += values.angles()[sliceIndex];
            [sliceLayer setSliceAngle:endAngle];
            
            CATextLayer *labelLayer = (CATextLayer *) [labelLayers objectAtIndex:sliceIndex];
            double value = values.percentages()[sliceIndex];
            NSNumber *valueAsNumber = [NSNumber numberWithDouble:value];
            NSString *label = [_labelFormatter stringFromNumber:valueAsNumber];
            //NSLog(@"label: %@", label);
            [labelLayer setString:label];
        }
        
        [CATransaction commit];
    }
}

- (void)refreshLayers
{
    //NSLog(@"refreshLayers");
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    NSArray *sliceLayers = [[pieLayer sliceLayers] sublayers];
    NSArray *labelLayers = [[pieLayer labelLayers] sublayers];
    NSArray *lineLayers = [[pieLayer lineLayers] sublayers];
    NSArray *tempLabelLayers = [[pieLayer tempLabelLayers] sublayers];
    
    [sliceLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        CGFloat startAngle = BTSLookupPreviousLayerAngle(sliceLayers, index, (CGFloat) -M_PI_2);
        CGFloat endAngle = (CGFloat) [[obj valueForKey:kBTSSliceLayerAngle] doubleValue];
        BTSUpdateLayers(sliceLayers, labelLayers, tempLabelLayers, lineLayers, index, _center, _radius, radiusArray, slotValuesForSlice, startAngle, endAngle);
    }];
}

#pragma mark - Animation Delegate + CADisplayLink Callback

- (void)updateTimerFired:(CADisplayLink *)displayLink
{
    //NSLog(@"updateTimerFired:");
    BTSPieLayer *parentLayer = (BTSPieLayer *) [self layer];
    NSArray *pieLayers = [[parentLayer sliceLayers] sublayers];
    NSArray *labelLayers = [[parentLayer labelLayers] sublayers];
    NSArray *lineLayers = [[parentLayer lineLayers] sublayers];
    NSArray *tempLabelLayers = [[parentLayer tempLabelLayers] sublayers];
    
    CGPoint center = _center;
    CGFloat radius = _radius;
    
    [CATransaction setDisableActions:YES];
    
    NSUInteger index = 0;
    for (BTSSliceLayer *currentPieLayer in pieLayers) {
        CGFloat interpolatedStartAngle = BTSLookupPreviousLayerAngle(pieLayers, index, (CGFloat) -M_PI_2);
        BTSSliceLayer *presentationLayer = (BTSSliceLayer *) [currentPieLayer presentationLayer];
        CGFloat interpolatedEndAngle = [presentationLayer sliceAngle];
        
        BTSUpdateLayers(pieLayers, labelLayers, tempLabelLayers, lineLayers, index, center, radius, radiusArray, slotValuesForSlice, interpolatedStartAngle, interpolatedEndAngle);
        ++index;
    }
    [CATransaction setDisableActions:NO];
}

- (void)animationDidStart:(CAAnimation *)anim
{
    [_displayLink setPaused:NO];
    [_animations addObject:anim];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)animationCompleted
{
    [_animations removeObject:anim];
    
    if ([_animations count] == 0) {
        [_displayLink setPaused:YES];
    }
}

#pragma mark - Touch Handing (Selection Notification)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    // Distance betw. center and touch point, pythagorean theorem approach:
    float distance = sqrt(pow((_center.x - point.x), 2.0) + pow((_center.y - point.y), 2.0));
    //NSLog(@"distance between cebter and touch: %f", distance);
    __block NSInteger selectedIndex = -1;
    
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    NSArray *lineLayers = [[pieLayer lineLayers] sublayers];
    NSArray *sliceLayers = [[pieLayer sliceLayers] sublayers];
    NSArray *labelLayers = [[pieLayer labelLayers] sublayers];
    NSArray *tempLabelLayers = [[pieLayer tempLabelLayers] sublayers];
    
    [sliceLayers enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
        BTSSliceLayer *sliceLayer = (BTSSliceLayer *) obj;
        //NSLog(@"sliceLayer: %@", sliceLayer);
        //NSLog(@"sublayers: %@", [sliceLayer sublayers]);
        CGPathRef path = [sliceLayer path];
        
        CGFloat startAngle = BTSLookupPreviousLayerAngle(sliceLayers, index, (CGFloat) -M_PI_2);
        
        // NOTE: in this demo code, the touch handling does not know about any applied transformations (i.e. perspective)
        if (CGPathContainsPoint(path, &CGAffineTransformIdentity, point, 0)) {
            if ((touchedContainerSliceLayerPrev != touchedContainerSliceLayer)
                &&
                (touchedContainerSliceLayerPrev != nil && touchedContainerSliceLayer != nil)){ // normal case
                touchedContainerSliceLayerPrev = touchedContainerSliceLayer;
                touchedContainerSliceLayer = sliceLayer;
            }
            else if (touchedContainerSliceLayerPrev == nil && touchedContainerSliceLayer == nil) { // first time
                touchedContainerSliceLayer = sliceLayer;
                NSLog(@"touchesMoved if: FIRST TIME!");
            }
            else if(touchedContainerSliceLayerPrev == nil && touchedContainerSliceLayer != nil) { // second time
                if (touchedContainerSliceLayer == sliceLayer) {
                    touchedContainerSliceLayerPrev = sliceLayer; // touched the same slice twice
                    NSLog(@"touchesMoved if: THE SAME!");
                }
                else {
                    touchedContainerSliceLayerPrev = touchedContainerSliceLayer; // second time but different slice
                    touchedContainerSliceLayer = sliceLayer;
                    NSLog(@"touchesMoved if: NOT THE SAME!");
                }
                
            }
            else if (touchedContainerSliceLayerPrev == touchedContainerSliceLayer){ // wants the slice to explode once more
                touchedContainerSliceLayerPrev = nil;
            }
            
            
            
            touchedContainerSliceLayer = sliceLayer;
            
            if (_highlightSelection) {
                [sliceLayer setStrokeColor:[UIColor whiteColor].CGColor];
                [sliceLayer setLineWidth:2.0];
                [sliceLayer setZPosition:1];
            } else {
                double endAngle = [sliceLayer sliceAngle];
                
                CGFloat deltaAngle = (CGFloat) (((endAngle + startAngle) / 2.0));
                
                CGFloat xOffset = (CGFloat) (10.0f * cos(deltaAngle));
                CGFloat yOffset = (CGFloat) (10.0f * sin(deltaAngle));
                
                CGFloat centerX = xOffset;
                CGFloat centerY = yOffset;
                /*NSLog(@"_center.x: %f, _center.y: %f, xOffset: %f, yOffset: %f, startAngle: %f, endAngle: %f, index: %i",
                 _center.x, _center.y, xOffset, yOffset, startAngle, endAngle, index); */
                CGAffineTransform translationTransform = CGAffineTransformMakeTranslation(centerX, centerY);
                [sliceLayer setAffineTransform:translationTransform];
                [sliceLayer setStrokeColor:[UIColor whiteColor].CGColor];
                [sliceLayer setLineWidth:2.0];
                [sliceLayer setZPosition:1];
                [[labelLayers objectAtIndex:index] setAffineTransform:translationTransform];
                [[lineLayers objectAtIndex:index] setAffineTransform:translationTransform];
                [[tempLabelLayers objectAtIndex:index] setAffineTransform:translationTransform];
                
                //                NSArray *sliceLayersInside = [sliceLayer sublayers];
                //                __block CGFloat diff = 9999.0; // between distance var and slot radius
                //                __block BTSSliceLayer *touchedSliceLayerInsideTemp = nil;
                //                // touch handling of slots inside found sliceLayer
                //                [sliceLayersInside enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
                //                    BTSSliceLayer *sliceLayerInside = (BTSSliceLayer *) obj;
                //                    CGFloat slotRadius = sliceLayerInside.radius;
                //                    NSLog(@"slotRadius: %f", slotRadius);
                //                    if (((slotRadius-distance) < diff) && (slotRadius >= distance)) {
                //                        diff = (slotRadius-distance);
                //                        NSLog(@"new diff: %f", diff);
                //                        touchedSliceLayerInsideTemp = sliceLayerInside;
                //                        NSLog(@"touchedSliceLayerInsideTemp: %@", touchedSliceLayerInsideTemp);
                //                    }
                //
                //                }];
                //                if (touchedSliceLayerInside != touchedSliceLayerInsideTemp) {
                //                    if (touchedSliceLayerInside != nil) {
                //                        [sliceLayersInside enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
                //                            BTSSliceLayer *sliceLayerInside = (BTSSliceLayer *) obj;
                //                            if (sliceLayerInside.radius < touchedSliceLayerInside.radius) {
                //                                CGPathRef pathInsideOriginal =
                //                                CGPathCreateArc(_center,sliceLayerInside.radius - 20.0 , touchedStartAngle, touchedEndAngle); // reset
                //                                [sliceLayerInside setPath:pathInsideOriginal];
                //                            }
                //                            else {
                //                                CGPathRef pathInsideNew =
                //                                CGPathCreateArc(_center,sliceLayerInside.radius - 15.0 , touchedStartAngle, touchedEndAngle); // reset
                //                                [sliceLayerInside setPath:pathInsideNew];
                //                            }
                //                        }];
                //
                //                    }
                //
                //                    touchedSliceLayerInside = touchedSliceLayerInsideTemp;
                //                    touchedEndAngle = endAngle;
                //                    touchedStartAngle = startAngle;
                //
                //                    [sliceLayersInside enumerateObjectsUsingBlock:^(id obj, NSUInteger index, BOOL *stop) {
                //                        BTSSliceLayer *sliceLayerInside = (BTSSliceLayer *) obj;
                //                        if (sliceLayerInside.radius < touchedSliceLayerInside.radius) {
                //                            CGPathRef pathInsideNew =
                //                            CGPathCreateArc(_center,sliceLayerInside.radius + 20.0 , touchedStartAngle, touchedEndAngle);
                //                            [sliceLayerInside setPath:pathInsideNew];
                //                        }
                //                        else {
                //                            CGPathRef pathInsideNew =
                //                            CGPathCreateArc(_center,sliceLayerInside.radius + 15.0 , touchedStartAngle, touchedEndAngle);
                //                            [sliceLayerInside setPath:pathInsideNew];
                //                        }
                //
                //                    }];
                //
                //                    NSLog(@"touched sliceLayerInside: %@ with Radius: %f", touchedSliceLayerInside, touchedSliceLayerInside.radius);
                //
                //
                //                }
                
            }
            
            selectedIndex = (NSInteger) index;
            touchedSliceLayerIndex = selectedIndex;
        } else {
            [sliceLayer setAffineTransform:CGAffineTransformIdentity];
            [[labelLayers objectAtIndex:index] setAffineTransform:CGAffineTransformIdentity];
            //[[labelLayers objectAtIndex:index+1] setAffineTransform:CGAffineTransformIdentity];
            [[lineLayers objectAtIndex:index] setAffineTransform:CGAffineTransformIdentity];
            [[tempLabelLayers objectAtIndex:index] setAffineTransform:CGAffineTransformIdentity];
            [sliceLayer setLineWidth:0.0];
            [sliceLayer setZPosition:0];
        }
    }];
    
    [self maybeNotifyDelegateOfSelectionChangeFrom:_selectedSliceIndex to:selectedIndex];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    BTSPieLayer *pieLayer = (BTSPieLayer *) [self layer];
    NSArray *lineLayers = [[pieLayer lineLayers] sublayers];
    NSArray *labelLayers = [[pieLayer labelLayers] sublayers];
    NSArray *tempLabelLayers = [[pieLayer tempLabelLayers] sublayers];
    
    if (touchedContainerSliceLayer == touchedContainerSliceLayerPrev) {
        NSLog(@"touchesEnded: THE SAME!");
        //NSLog(@"touchedContainerSliceLayer: %@,  touchedContainerSliceLayerPrev: %@", touchedContainerSliceLayer, touchedContainerSliceLayerPrev);
        [touchedContainerSliceLayer setAffineTransform:CGAffineTransformIdentity];
        [[labelLayers objectAtIndex:touchedSliceLayerIndex] setAffineTransform:CGAffineTransformIdentity];
        [[lineLayers objectAtIndex:touchedSliceLayerIndex] setAffineTransform:CGAffineTransformIdentity];
        [[tempLabelLayers objectAtIndex:touchedSliceLayerIndex] setAffineTransform:CGAffineTransformIdentity];
        [touchedContainerSliceLayer setLineWidth:0.0];
        [touchedContainerSliceLayer setZPosition:0];
    }
    
    
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}


#pragma mark - Selection Notification

- (void)maybeNotifyDelegateOfSelectionChangeFrom:(NSInteger)previousSelection to:(NSInteger)newSelection
{
    NSLog(@"maybeNotifyDelegateOfSelectionChangeFrom:");
    if (previousSelection != newSelection) {
        
        if (previousSelection != -1) {
            [_delegate pieView:self willDeselectSliceAtIndex:previousSelection];
        }
        
        _selectedSliceIndex = newSelection;
        
        if (newSelection != -1) {
            [_delegate pieView:self willSelectSliceAtIndex:newSelection];
            
            if (previousSelection != -1) {
                [_delegate pieView:self didDeselectSliceAtIndex:previousSelection];
            }
            
            [_delegate pieView:self didSelectSliceAtIndex:newSelection];
        } else {
            if (previousSelection != -1) {
                [_delegate pieView:self didDeselectSliceAtIndex:previousSelection];
            }
        }
    }
}

#pragma mark - Pie Layer Creation Method

+ (CATextLayer *)createLabelLayer
{
    CATextLayer *textLayer = [CATextLayer layer];
    [textLayer setContentsScale:[[UIScreen mainScreen] scale]];
    CGFontRef font = CGFontCreateWithFontName((__bridge CFStringRef) [[UIFont systemFontOfSize:14.0] fontName]);
    [textLayer setFont:font];
    CFRelease(font);
    [textLayer setFontSize:14.0];
    [textLayer setAnchorPoint:CGPointMake(0.5, 0.5)];
    [textLayer setAlignmentMode:kCAAlignmentCenter];
    //[textLayer setBackgroundColor:[UIColor greenColor].CGColor];
    CGSize size = [@"100.00%" sizeWithFont:[UIFont systemFontOfSize:14.0]];
    [textLayer setBounds:CGRectMake(0.0, 0.0, size.width, size.height)];
    return textLayer;
}

#pragma mark - Function Helpers

// Helper method to create an arc path for a layer
CGPathRef CGPathCreateArc(CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle) {
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, center.x, center.y);
    CGPathAddArc(path, NULL, center.x, center.y, radius, startAngle, endAngle, 0);
    CGPathCloseSubpath(path);
    return path;
}

CGPathRef CGPathCreateArcLineForAngle(CGPoint center, CGFloat radius, CGFloat angle, bool drawArrow) {
    NSLog(@"CGPathCreateArcLineForAngle - angle: %f", angle);
    CGMutablePathRef linePath = CGPathCreateMutable();
    CGPathMoveToPoint(linePath, NULL, center.x, center.y);
    CGPathAddLineToPoint(linePath, NULL, (CGFloat) (center.x + (radius+13.0) * cos(angle)), (CGFloat) (center.y + (radius+13.0) * sin(angle)));
    if (drawArrow) { //draw an arrow at 0:00
        CGPathAddLineToPoint(linePath, NULL, (CGFloat) (center.x + (radius+13.0) * cos(angle))+ 10.0f, (CGFloat) (center.y + (radius+13.0) * sin(angle))+10.0f);
        CGPathAddLineToPoint(linePath, NULL, (CGFloat) (center.x + (radius+13.0) * cos(angle)), (CGFloat) (center.y + (radius+13.0) * sin(angle))+20.0f);
        //CGPathCloseSubpath(linePath);
    }
    return linePath;
}

void BTSUpdateLabelPosition(CALayer *labelLayer, CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle) {
    //CGFloat midAngle = (startAngle + endAngle) / 2.0f;
    //CGFloat halfRadius = radius / 2.0f;
    CGFloat midAngle = startAngle;
    CGFloat halfRadius = radius + 18.0f;
    [labelLayer setPosition:CGPointMake((CGFloat) (center.x + (halfRadius * cos(midAngle))), (CGFloat) (center.y + (halfRadius * sin(midAngle))))];
}

void BTSUpdateTempLabelPosition(CALayer *tempLabelLayer, CGPoint center, CGFloat radius, CGFloat startAngle, CGFloat endAngle) {
    CGFloat midAngle = (startAngle + endAngle) / 2.0f;
    CGFloat halfRadius = radius + 23.0f;
    //CGFloat midAngle = startAngle;
    [tempLabelLayer setPosition:CGPointMake((CGFloat) (center.x + (halfRadius * cos(midAngle))), (CGFloat) (center.y + (halfRadius * sin(midAngle))))];
}

void BTSUpdateLayers(NSArray *sliceLayers, NSArray *labelLayers, NSArray *tempLabelLayers, NSArray *lineLayers, NSUInteger layerIndex, CGPoint center, CGFloat radius, NSArray *radiusArray, NSArray *slotValuesForSlice, CGFloat startAngle, CGFloat endAngle) {
    
    {
        CAShapeLayer *lineLayer = [lineLayers objectAtIndex:layerIndex];
        NSLog(@"BTSUpdateLayers, with startAngle: %f and layerIndex: %i and sliceLayers: %@ and lineLayers: %@", startAngle, layerIndex, sliceLayers, lineLayers);
        if (layerIndex == 11) {
            NSLog(@"BTSUpdateLayers, start found!");
            bool drawArrow = true;
            CGPathRef linePath = CGPathCreateArcLineForAngle(center, radius + 5, endAngle, drawArrow);
            
            /*CGMutablePathRef trianglePath = CGPathCreateMutable();
             CGPathMoveToPoint(trianglePath, NULL,40.0f, 0.0f);
             CGPathAddLineToPoint (trianglePath, NULL,80.0f, 60.0f);
             CGPathAddLineToPoint (trianglePath, NULL,0.0f, 60.0f);
             CGPathCloseSubpath(trianglePath);
             
             [lineLayer setPath:trianglePath];
             
             [lineLayer setPath:linePath];
             CFRelease(trianglePath);*/
            [lineLayer setPath:linePath];
            CFRelease(linePath);
        }
        else {
            CGPathRef linePath = CGPathCreateArcLineForAngle(center, radius, endAngle, false);
            NSLog(@"BTSUpdateLayers, linePath: %@", linePath);
            [lineLayer setPath:linePath];
            CFRelease(linePath);
        }
        
    }
    
    {
        CAShapeLayer *sliceLayer = [sliceLayers objectAtIndex:layerIndex];
        
        // Changed by Pavel Ermolin //
        //CAShapeLayer *sliceLayerInside = [[sliceLayer sublayers] objectAtIndex:0];
        /*NSMutableArray *radiusStepArray = [[NSMutableArray alloc] init];
         for (int j=0; j<5; j++) {
         [radiusStepArray insertObject:[NSNumber numberWithInt:arc4random()%80+20] atIndex:j];
         }
         NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
         NSArray *sortedArray = [radiusStepArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];*/
        //NSLog(@"sliceLayer: %@", sliceLayer);
        //NSLog(@"sliceLayer sublayers: %@", [sliceLayer sublayers]);
        
        //int i = 0;
        
        CGFloat angleBetween = ABS(ABS(startAngle) - ABS(endAngle));
        NSArray *slotValues = slotValuesForSlice[layerIndex];
        NSLog(@"BTSUpdateLayers: slotValuesForSlice at index %i : %@ ", layerIndex, slotValues);
        int slotsCount = [slotValues count];
        int j = slotsCount-1; // slot number
        NSArray *radiusValuesForSlice = calculateRadiusValues(slotValues, radius, angleBetween);
        
        NSLog(@"BTSUpdateLayers: startAngle: %f", startAngle);
        NSLog(@"BTSUpdateLayers: endAngle: %f", endAngle);
        for (CAShapeLayer *sliceLayerInside in [sliceLayer sublayers]) {
            //NSLog(@"radius: %f", radius);
            //NSLog(@"new radius: %f", radius-[sortedArray[i]integerValue]);
            //NSLog(@"sortedArray[i]: %@", sortedArray[i]);
            ((BTSSliceLayer *) sliceLayerInside).radius = [radiusValuesForSlice[j] floatValue];
            //CGPathRef pathInside = CGPathCreateArc(center, radius-i, startAngle, endAngle);
            CGPathRef pathInside = CGPathCreateArc(center, [radiusValuesForSlice[j] floatValue], startAngle, endAngle);
            [sliceLayerInside setPath:pathInside];
            CFRelease(pathInside);
            //NSLog(@"layerIndex: %i, j: %i", layerIndex, j);
            //int step = [[[radiusArray objectAtIndex:layerIndex] objectAtIndex:j] integerValue];
            //NSLog(@"step: %i", step);
            //i+=step;
            j--;
        }
        
        //*************************//
        
        CGPathRef path = CGPathCreateArc(center, radius, startAngle, endAngle);
        [sliceLayer setPath:path];
        CFRelease(path);
    }
    
    {
        CALayer *labelLayer = [labelLayers objectAtIndex:layerIndex];
        BTSUpdateLabelPosition(labelLayer, center, radius, startAngle, endAngle);
    }
    
    {
        CALayer *labelLayer = [tempLabelLayers objectAtIndex:layerIndex];
        BTSUpdateTempLabelPosition(labelLayer, center, radius, startAngle, endAngle);
    }
    
    
}

NSArray *calculateRadiusValues(NSArray *slotValues, CGFloat radius, CGFloat angleBetween)
{
    NSLog(@"calculateRadiusValues - slotValues: %@, radius: %f", slotValues, radius);
    // Calculate total area of the circle segment
    CGFloat totalArea = 0.5 * (radius * radius) * angleBetween;
    NSMutableArray *resultRadiusValues = [[NSMutableArray alloc] init];
    // Area pieces
    CGFloat sum = 0.0;
    //NSMutableArray *areaPieces = [[NSMutableArray alloc] init];
    CGFloat areaPieces[[slotValues count]];
    for (int i=0; i<[slotValues count]; i++) {
        sum+= [slotValues[i] floatValue];
    }
    NSLog(@"calculateRadiusValues - sum: %f", sum);
    for (int i=0; i<[slotValues count]; i++) {
        areaPieces[i] = ([slotValues[i] floatValue]/sum) * totalArea;
    }
    NSLog(@"calculateRadiusValues - areaPieces values: %f, %f, %f", areaPieces[0], areaPieces[1], areaPieces[2]);
    CGFloat currentArea = 0.0;
    for (int i=0; i<[slotValues count]; i++) {
        currentArea += areaPieces[i];
        resultRadiusValues[i] = [NSNumber numberWithFloat:sqrtf( (2.0 * currentArea) / angleBetween )];
    }
    NSLog(@"calculateRadiusValues - resultRadiusValues: %@", resultRadiusValues);
    return resultRadiusValues;
}

void BTSUpdateAllLayers(BTSPieLayer *pieLayer, NSUInteger layerIndex, CGPoint center, CGFloat radius, NSArray *radiusArray, NSArray *slotValuesForSlice, CGFloat startAngle, CGFloat endAngle) {
    BTSUpdateLayers([[pieLayer sliceLayers] sublayers], [[pieLayer labelLayers] sublayers], [[pieLayer tempLabelLayers] sublayers], [[pieLayer lineLayers] sublayers], layerIndex, center, radius, radiusArray, slotValuesForSlice, startAngle, endAngle);
}

CGFloat BTSLookupPreviousLayerAngle(NSArray *pieLayers, NSUInteger currentPieLayerIndex, CGFloat defaultAngle) {
    BTSSliceLayer *sliceLayer;
    if (currentPieLayerIndex == 0) {
        sliceLayer = nil;
    } else {
        sliceLayer = [pieLayers objectAtIndex:currentPieLayerIndex - 1];
    }
    
    return (sliceLayer == nil) ? defaultAngle : [[sliceLayer presentationLayer] sliceAngle];
}

@end

#pragma mark - Existing Layer Animation Delegate

@implementation BTSSliceLayerExistingLayerDelegate

@synthesize animationDelegate = _animationDelegate;

- (id <CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if ([kBTSSliceLayerAngle isEqual:event]) {
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:event];
        NSNumber *currentAngle = [[layer presentationLayer] valueForKey:event];
        [animation setFromValue:currentAngle];
        [animation setDelegate:_animationDelegate];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        
        return animation;
    } else {
        return nil;
    }
}

@end

#pragma mark - New Layer Animation Delegate

@implementation BTSSliceLayerAddAtBeginningLayerDelegate

@synthesize animationDelegate = _animationDelegate;

- (id <CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if ([kBTSSliceLayerAngle isEqualToString:event]) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:kBTSSliceLayerAngle];
        
        [animation setFromValue:[NSNumber numberWithDouble:-M_PI_2]];
        [animation setDelegate:_animationDelegate];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        
        return animation;
    } else {
        return nil;
    }
}

@end

#pragma mark - Add Layer In Middle Animation Delegate

@implementation BTSSliceLayerAddInMiddleLayerDelegate

@synthesize animationDelegate = _animationDelegate;
@synthesize initialSliceAngle = _initialSliceAngle;

- (id <CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    if ([kBTSSliceLayerAngle isEqualToString:event]) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:kBTSSliceLayerAngle];
        
        [animation setFromValue:[NSNumber numberWithDouble:_initialSliceAngle]];
        [animation setDelegate:_animationDelegate];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];
        
        return animation;
    } else {
        return nil;
    }
}
@end

