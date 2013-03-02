//
//  ScrollViewContentVC.h
//  uni-project
//
//  Created by Pavel Ermolin on 01.03.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScrollViewContentVC : UIViewController <CPTPlotSpaceDelegate,
                                                   CPTPlotDataSource,
                                                   CPTPieChartDelegate>

- (id)initWithPageNumber:(NSUInteger)page andUIViewController:(UIViewController*)viewController;

@end
