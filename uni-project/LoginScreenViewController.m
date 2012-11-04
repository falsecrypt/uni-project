//
//  LoginScreenViewController.m
//  uni-project
//
//  Created by Erna on 28.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import "LoginScreenViewController.h"



@interface LoginScreenViewController ()

@end

@implementation LoginScreenViewController

@synthesize cancelButton = _cancelButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didSelectCancel:(UIButton *)sender
{
    [self.delegate didDismissPresentedViewController];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

@end
