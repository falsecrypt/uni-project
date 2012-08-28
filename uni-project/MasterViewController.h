//
//  MasterViewController.h
//  uni-project
//
//  Created by Erna on 28.08.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
