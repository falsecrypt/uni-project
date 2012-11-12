//
//  FirstTableViewController.h
//  uni-project
//
//  Created by Erna on 28.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginScreenViewController.h"
#import "RegisterTableViewController.h"

@interface FirstTableViewController : UITableViewController <LoginScreenViewControllerDelegate, RegisterScreenViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UITableView *firstTableView;
@end
