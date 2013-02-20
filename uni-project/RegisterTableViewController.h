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
//- (void)userDidRegistered;
@end


@interface RegisterTableViewController : UITableViewController

@property (nonatomic, weak) id<RegisterScreenViewControllerDelegate> delegate;

@end
