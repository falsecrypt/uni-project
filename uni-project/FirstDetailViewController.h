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

@interface FirstDetailViewController : UIViewController <SubstitutableDetailViewController, LoginScreenViewControllerDelegate>

/// SubstitutableDetailViewController

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;

@property (nonatomic, retain) ProfilePopoverViewController *userProfile;
@property (nonatomic, retain) UIPopoverController *profilePopover;

- (IBAction)profileButtonTapped:(id)sender;

@end