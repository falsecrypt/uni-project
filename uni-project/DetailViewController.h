//
//  DetailViewController.h
//  uni-project
//
//  Created by Erna on 28.08.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
