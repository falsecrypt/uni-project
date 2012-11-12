//
//  RegisterTableViewController.h
//  uni-project
//
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import <US2FormValidator.h>

@protocol RegisterScreenViewControllerDelegate <NSObject>
- (void)didDismissPresentedViewControllerRegister;
- (void)userDidRegistered;
@end

@interface RegisterTableViewController : UITableViewController

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *submitButton;
- (IBAction)submitButtonPressed:(id)sender;
- (IBAction)cancelBarButtonItemPressed:(id)sender;
//@property (strong, nonatomic) IBOutlet US2ValidatorTextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;

@property (nonatomic, weak) id<RegisterScreenViewControllerDelegate> delegate;

@end
