//
//  FirstDetailViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"
#import "ProfilePopoverViewController.h"

@interface FirstDetailViewController : UIViewController <SubstitutableDetailViewController>

//@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
//@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
/// SubstitutableDetailViewController

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, retain) UIBarButtonItem *navigationPaneBarButtonItem;

@property (nonatomic, retain) ProfilePopoverViewController *userProfile;
@property (nonatomic, retain) UIPopoverController *profilePopover;

- (IBAction)profileButtonTapped:(id)sender;

@end