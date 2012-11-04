//
//  LoginScreenViewController.h
//  uni-project
//
//  Created by Erna on 28.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoginScreenViewControllerDelegate <NSObject>
- (void)didDismissPresentedViewController;
@end

@interface LoginScreenViewController : UIViewController
@property (nonatomic, weak) id<LoginScreenViewControllerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@end
