//
//  SecondDetailViewController.h
//  uni-project
//
//  Created by Erna on 29.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@interface SecondDetailViewController : UIViewController <SubstitutableDetailViewController>

/// SubstitutableDetailViewController
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@end