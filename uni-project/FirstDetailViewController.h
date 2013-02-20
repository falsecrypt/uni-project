//
//  FirstDetailViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import "ProfilePopoverViewController.h"
#import "LoginScreenTableViewController.h"
//#import "RegisterTableViewController.h"

@interface FirstDetailViewController : UIViewController <SubstitutableDetailViewController /*, LoginScreenViewControllerDelegate*/ >

/// SubstitutableDetailViewController
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;
@property (nonatomic, weak)   IBOutlet UINavigationBar *navigationBar; // title is set directly by PublicTableViewController in viewWillDisappear method

@end