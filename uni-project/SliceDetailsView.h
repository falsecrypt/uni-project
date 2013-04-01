//
//  SliceDetailsView.h
//  uni-project
//
//  Created by Pavel Ermolin on 01.04.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol slicePieChartDatasource<NSObject>
- (NSNumber *)valueForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex;
@end


@interface SliceDetailsView : UIView <CPTPlotSpaceDelegate,CPTPlotDataSource,CPTPieChartDelegate>


-(void)initPlots;
-(void)reloadPieChartForNewSlice:(NSUInteger)selectedSliceNumber;
-(void)reloadPieChartForNewParticipant:(NSUInteger)selectedParticipant;

@property (nonatomic, strong) NSMutableArray *slotValuesForSlice;
@property (nonatomic,weak) id <slicePieChartDatasource> datasource;

@end
