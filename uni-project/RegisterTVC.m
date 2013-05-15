//
//  RegisterTableViewController.m
//  uni-project
//
//  Created by Erna on 05.11.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import "RegisterTVC.h"
#import "KeychainItemWrapper.h"
#import "EMNetworkManager.h"
#import "User.h"

@interface RegisterTVC ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;

- (IBAction)submitButtonPressed:(id)sender;
- (IBAction)cancelBarButtonItemPressed:(id)sender;

@property (nonatomic, weak) IBOutlet UITextField *usernameField;
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UITextField *publicUsernameField;


@end

@implementation RegisterTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //Code for dissmissing this viewController by clicking outside it
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.tableView addGestureRecognizer:recognizer];
    
    self.usernameField.delegate = self;
    self.emailField.delegate = self;
    self.passwordField.delegate = self;
    self.publicUsernameField.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self readyToCreateAnAccount:textField];
    
    return YES;
}

- (void)dismissKeyboard:(UITapGestureRecognizer *)sender
{
    NSLog(@"dismissKeyboard");
    [[self view] endEditing: YES];
//    [self.usernameField resignFirstResponder];
//    [self.emailField resignFirstResponder];
//    [self.passwordField resignFirstResponder];
//    [self.publicUsernameField resignFirstResponder];
    
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

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

- (void)showAlertAfterValidationFailed:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Validation Failed" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)readyToCreateAnAccount:(id)sender {
    NSString *inputUsername = [self.usernameField text];
    NSString *inputPassword = [self.passwordField text];
    NSString *inputEmail    = [self.emailField text];
    NSString *inputPublicUsername = [self.publicUsernameField text];
    
    [sender resignFirstResponder];
    if( [inputUsername length] < 1 || [inputPassword length] < 1  ){
        [self showAlertAfterValidationFailed:@"Benutzername und Passwort dürfen nicht leer sein"];
    }
    if( [inputPublicUsername length] < 1 ){
        [self showAlertAfterValidationFailed:@"Bitte geben Sie Ihren gewünschten öffentlichen Namen ein"];
    }
    else {
        
        // OK. lets save the new account, using keychain
        KeychainItemWrapper *keychain =
        [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
        [keychain setObject:inputUsername forKey:(__bridge id)kSecAttrAccount];
        [keychain setObject:inputPassword forKey:(__bridge id)kSecValueData];
        if ([inputEmail length] > 0) {
            [keychain setObject:inputEmail forKey:(__bridge id)kSecAttrDescription];
        }
        /* kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
         Only accessible when device is unlocked. Data is not migrated via backups.
         */
        [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlockedThisDeviceOnly) forKey:(__bridge id)(kSecAttrAccessible)];
        // login-flag
        [keychain setObject:@"LOGGEDIN" forKey:(__bridge id)(kSecAttrLabel)];
        
        // OK. lets save the public username, not encrypted
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:inputPublicUsername forKey:@"publicUserName"];
        // and send it to the server
        [self sendPublicUsernameToServer:inputPublicUsername];
        
        NSString *publicUsernameRetrieved = [defaults stringForKey:@"publicUserName"];
        NSLog(@"userLoggedIn from the keychain (kSecAttrLabel): %@", [keychain objectForKey:(__bridge id)(kSecAttrLabel)]);
        NSLog(@"publicUsernameRetrieved from NSUserDefaults: %@", publicUsernameRetrieved);
        [self.delegate didDismissPresentedViewControllerRegister];
        //[self.delegate userDidRegistered];
        
        // Save the User-Object
        [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
            User *newUser = [User createInContext:localContext];
            newUser.created = [NSDate date];
            newUser.sensorid = @(MySensorID);
        } completion:^{
            NSLog(@"NEW USER SAVED!");
        }];
        
        NSString *notificationName = @"UserRegisteredNotification";
        [[NSNotificationCenter defaultCenter]
         postNotificationName:notificationName
         object:nil];
        
    }
}


- (void)sendPublicUsernameToServer:(NSString *)publicName {
    
    NSString *postPath = @"rpc.php?userID=";
    postPath = [postPath stringByAppendingString: [NSString stringWithFormat:@"%i", MySensorID]];
    postPath = [postPath stringByAppendingString:@"&action=put&username="];
    postPath = [postPath stringByAppendingString:publicName];
    
    [[EMNetworkManager sharedClient] postPath:postPath parameters:nil
                 success:^(AFHTTPRequestOperation *operation, id response) {
                     NSLog(@"Public Username sent...");
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     NSLog(@"Error with request, while sending public user name!");
                     NSLog(@"%@",[error localizedDescription]);
                 }];
}

// Ready to create an account?
- (IBAction)submitButtonPressed:(id)sender {
    [self readyToCreateAnAccount:sender];
    
}

- (IBAction)cancelBarButtonItemPressed:(id)sender {
    
    [self.delegate didDismissPresentedViewControllerRegister];
    
}

@end
