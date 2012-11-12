//
//  LoginScreenViewController.h
//  uni-project
//
//  Created by Erna on 28.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginScreenViewControllerDelegate <NSObject>
- (void)didDismissPresentedViewControllerLogin;
- (void)userLoggedIn;
@end

@interface LoginScreenViewController : UIViewController
@property (nonatomic, weak) id<LoginScreenViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)logInButtonPressed:(id)sender;
@end
