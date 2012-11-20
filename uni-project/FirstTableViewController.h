//
//  FirstTableViewController.h
//  uni-project
//
//  Created by Erna on 28.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginScreenTableViewController.h"
#import "RegisterTableViewController.h"

@interface FirstTableViewController : UITableViewController <LoginScreenViewControllerDelegate, RegisterScreenViewControllerDelegate>

@end
