//
//  SecondDetailViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@interface PublicDetailViewController : UIViewController <SubstitutableDetailViewController>

/// SubstitutableDetailViewController
@property (nonatomic, strong) UIBarButtonItem *navigationPaneBarButtonItem;
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (nonatomic, assign) NSInteger selectedParticipant;


@end