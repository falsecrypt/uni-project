//
//  LoginScreenTableViewController.h
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginScreenViewControllerDelegate <NSObject>
- (void)didDismissPresentedViewControllerLogin;
//- (void)userLoggedIn;
@end

/*@protocol ProfilePopoverDelegate <NSObject>
- (void)showProfileAfterUserLoggedIn;
@end*/

@interface LoginScreenTableViewController : UITableViewController

@property (nonatomic, weak) id<LoginScreenViewControllerDelegate> delegate;
//@property (nonatomic, weak) id<ProfilePopoverDelegate> profileDelegate;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)logInButtonPressed:(id)sender;

- (IBAction)didSelectCancel:(id)sender;
@end
