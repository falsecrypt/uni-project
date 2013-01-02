//
//  LoginScreenTableViewController.m
//  uni-project
//  Copyright (c) 2012 test. All rights reserved.
//

#import "LoginScreenTableViewController.h"
#import "KeychainItemWrapper.h"
#import <TargetConditionals.h>



@interface LoginScreenTableViewController ()

@end

@implementation LoginScreenTableViewController

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

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)showAlertAfterValidationFailed:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Validation Failed" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)logInButtonPressed:(id)sender
{

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"userLoggedIn"];
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    
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
        if( [ self.delegate respondsToSelector: @selector( didDismissPresentedViewControllerLogin ) ] ) {
            [self.delegate didDismissPresentedViewControllerLogin]; 
            NSLog(@"self.delegate 1: %@", self.delegate);
        }
        /*if( [ self.delegate respondsToSelector: @selector( showProfileAfterUserLoggedIn ) ] ) {
            [self.delegate showProfileAfterUserLoggedIn]; // profileDelegate == null ???
            NSLog(@"self.delegate 2: %@", self.delegate);
        }*/
        
        NSString *notificationName = @"UserLoggedInNotification";
        [[NSNotificationCenter defaultCenter]
         postNotificationName:notificationName
         object:nil];
        
        
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
        
        NSString *notificationName = @"UserLoggedInNotification";
        [[NSNotificationCenter defaultCenter]
         postNotificationName:notificationName
         object:nil];
    }
    // Sorry, something went wrong
    else {
        [self showAlertAfterValidationFailed:@"The username or password you entered is incorrect"];
    }
    
#endif

    
}

- (IBAction)didSelectCancel:(id)sender {
    
        [self.delegate didDismissPresentedViewControllerLogin];
}

@end