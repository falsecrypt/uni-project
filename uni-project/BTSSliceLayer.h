//
//  BTSSliceLayer.h
//
//  Copyright (c) 2011 Brian Coyner. All rights reserved.

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

// Private implementation class.
// 
// This layer represents a single slice.

extern NSString * const kBTSSliceLayerAngle;

@interface BTSSliceLayer : CAShapeLayer 
@property (nonatomic, readwrite) CGFloat sliceAngle;

// NEW
@property (nonatomic, readwrite) NSArray *slotValues;
@property (nonatomic, readwrite) CGFloat radius;

+ (id)layerWithColor:(CGColorRef)fillColor;
+ (id)layerWithoutColor;
@end