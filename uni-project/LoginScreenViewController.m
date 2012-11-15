//
//  LoginScreenViewController.m
//  uni-project
//  Copyright (c) 2012 test. All rights reserved.
//

#import "LoginScreenViewController.h"
#import "KeychainItemWrapper.h"
#import <TargetConditionals.h>



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
    [self.delegate didDismissPresentedViewControllerLogin];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)showAlertAfterValidationFailed:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Validation Failed" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (IBAction)logInButtonPressed:(id)sender
{
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"userLoggedIn"];
    
    if( [self.usernameField.text length] < 1 || [self.passwordField.text length] < 1  ){
        [self showAlertAfterValidationFailed:@"Username and Password cannot be Blank"];
    }
    
#if TARGET_IPHONE_SIMULATOR
    
    // Validation on simulatior
    else if ([self.usernameField.text isEqualToString:@"admin"] &&
             [self.passwordField.text isEqualToString:@"admin"]) {
        
        // now set UserLoggedIn = true, using NSUserDefaults
        
        [defaults setBool:YES forKey:@"userLoggedIn"];
        
        BOOL loggedIN = [defaults boolForKey:@"userLoggedIn"];
        NSLog(@"Simulator-Credentials accepted-userLoggedIn from NSUserDefaults: %d", loggedIN);
        [self.delegate didDismissPresentedViewControllerLogin];
        [self.delegate userLoggedIn];
    }
    // Sorry, something went wrong
    else {
        [self showAlertAfterValidationFailed:@"The username or password you entered is incorrect"];
    }
    
#else
    
    // Validation deploying on real device
    else if ([self.usernameField.text isEqualToString:[keychain objectForKey:(__bridge id)kSecAttrAccount]] &&
             [self.passwordField.text isEqualToString:[keychain objectForKey:(__bridge id)kSecValueData]]) {
    


        // now set UserLoggedIn = true, using NSUserDefaults
        
        [defaults setBool:YES forKey:@"userLoggedIn"];
        
        BOOL loggedIN = [defaults boolForKey:@"userLoggedIn"];
        NSLog(@"Credentials accepted-userLoggedIn from NSUserDefaults: %d", loggedIN);
        [self.delegate didDismissPresentedViewControllerLogin];
        [self.delegate userLoggedIn];
    }
    // Sorry, something went wrong
    else {
        [self showAlertAfterValidationFailed:@"The username or password you entered is incorrect"];
    }
    
#endif

    
}

@end