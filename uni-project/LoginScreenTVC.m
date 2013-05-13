//
//  LoginScreenTableViewController.m
//  uni-project
//  Copyright (c) 2012 test. All rights reserved.
//

#import "LoginScreenTVC.h"
#import "KeychainItemWrapper.h"
#import "SSKeychain.h"
#import <TargetConditionals.h>



@interface LoginScreenTVC ()
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@end

@implementation LoginScreenTVC


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIView *tempImageView = [[UIImageView alloc] init];
    [tempImageView setFrame:self.tableView.frame];
    tempImageView.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"patternBg"]];
    self.tableView.backgroundView = tempImageView;
    
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}*/


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [[self view] endEditing: YES];
    [self readyToLogin];
    
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
    [self.usernameField resignFirstResponder];

    [self readyToLogin];
    
}

- (void)readyToLogin {
    
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
                 forKey:(__bridge id)(kSecAttrAccessible)];
    if( [self.usernameField.text length] < 1 || [self.passwordField.text length] < 1  ){
        [self showAlertAfterValidationFailed:@"Username and Password cannot be Blank"];
    }
    
    if ([self.usernameField.text isEqualToString:[keychain objectForKey:(__bridge id)kSecAttrAccount]] &&
        [self.passwordField.text isEqualToString:[keychain objectForKey:(__bridge id)kSecValueData]]) {
        
        // now set UserLoggedIn, using keychain
        [keychain setObject:@"LOGGEDIN" forKey:(__bridge id)(kSecAttrLabel)];
        
        NSLog(@"Credentials accepted-userLoggedIn from the keychain: %@", [keychain objectForKey:(__bridge id)(kSecAttrLabel)]);
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
}

- (IBAction)didSelectCancel:(id)sender {
    
        [self.delegate didDismissPresentedViewControllerLogin];
}

@end