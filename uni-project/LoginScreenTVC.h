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

@interface LoginScreenTVC : UITableViewController<UITextFieldDelegate>

@property (nonatomic, weak) id<LoginScreenViewControllerDelegate> delegate;
//@property (nonatomic, weak) id<ProfilePopoverDelegate> profileDelegate;
- (IBAction)logInButtonPressed:(id)sender;

- (IBAction)didSelectCancel:(id)sender;
@end
