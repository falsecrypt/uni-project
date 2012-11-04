//
//  LoginScreenViewController.m
//  uni-project
//  Copyright (c) 2012 test. All rights reserved.
//

#import "LoginScreenViewController.h"
#import "KeychainItemWrapper.h"



@interface LoginScreenViewController ()

@end

@implementation LoginScreenViewController

@synthesize cancelButton = _cancelButton;
@synthesize usernameField = _usernameField;
@synthesize passwordField = _passwordField;

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

- (IBAction)logInButtonPressed:(id)sender
{
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"TestAppLoginData" accessGroup:nil];
        // Store username to keychain
        if ([self.usernameField text])
            [keychain setObject:[_usernameField text] forKey:(__bridge id)kSecAttrAccount];
        
        // Store password to keychain
        if ([self.passwordField text])
            [keychain setObject:[_passwordField text] forKey:(__bridge id)kSecValueData];
    
    NSLog(@"username from keychain: %@", [keychain objectForKey:(__bridge id)kSecAttrAccount]);
    NSLog(@"password from keychain: %@", [keychain objectForKey:(__bridge id)kSecValueData]);
    
    [self.delegate didDismissPresentedViewController];
    
}

@end