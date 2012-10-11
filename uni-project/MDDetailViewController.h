//
//  MDDetailViewController.h
//  MultipleMasterDetailViews
//
//  Created by Todd Bates on 11/14/11.
//  Copyright (c) 2011 Science At Hand LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MDDetailViewController : UIViewController <UISplitViewControllerDelegate, CPTPlotDataSource, UIActionSheetDelegate, CPTBarPlotDataSource, CPTBarPlotDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UISwitch *switchAAPL;
@property (strong, nonatomic) IBOutlet UISwitch *switchGOOG;
@property (strong, nonatomic) IBOutlet UISwitch *switchMSFT;
@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (strong, nonatomic) IBOutlet CPTGraphHostingView *hostViewForBarGraph;
@end
