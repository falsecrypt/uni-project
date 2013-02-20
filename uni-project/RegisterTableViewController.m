//
//  RegisterTableViewController.m
//  uni-project
//
//  Created by Erna on 05.11.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import "RegisterTableViewController.h"
#import "KeychainItemWrapper.h"

@interface RegisterTableViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *submitButton;

- (IBAction)submitButtonPressed:(id)sender;
- (IBAction)cancelBarButtonItemPressed:(id)sender;

@property (nonatomic, weak) IBOutlet UITextField *usernameField;
@property (nonatomic, weak) IBOutlet UITextField *emailField;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;

@end

@implementation RegisterTableViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

// Ready to create an account?
- (IBAction)submitButtonPressed:(id)sender {
    NSString *inputUsername = [self.usernameField text];
    NSString *inputPassword = [self.passwordField text];
    NSString *inputEmail    = [self.emailField text];
    
    if( [inputUsername length] < 1 || [inputPassword length] < 1  ){
        [self showAlertAfterValidationFailed:@"Username and Password cannot be blank"];
    }
    else {
        // OK. lets save the new account, using keychain
        KeychainItemWrapper *keychain =
        [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
        [keychain setObject:inputUsername forKey:(__bridge id)kSecAttrAccount];
        [keychain setObject:inputPassword forKey:(__bridge id)kSecValueData];
        [keychain setObject:inputEmail forKey:(__bridge id)kSecAttrDescription];
        /* kSecAttrAccessibleWhenUnlockedThisDeviceOnly:
           Only accessible when device is unlocked. Data is not migrated via backups.
         */
        [keychain setObject:(__bridge id)(kSecAttrAccessibleWhenUnlockedThisDeviceOnly) forKey:(__bridge id)(kSecAttrAccessible)];
        // login-flag
        [keychain setObject:@"1" forKey:(__bridge id)(kSecAttrLabel)];
        /*
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"userLoggedIn"];
        
        BOOL loggedIN = [defaults boolForKey:@"userLoggedIn"]; */
        NSLog(@"userLoggedIn from the keychain (kSecAttrLabel): %@", [keychain objectForKey:(__bridge id)(kSecAttrLabel)]);
        [self.delegate didDismissPresentedViewControllerRegister];
        //[self.delegate userDidRegistered];
        
        NSString *notificationName = @"UserRegisteredNotification";
        [[NSNotificationCenter defaultCenter]
         postNotificationName:notificationName
         object:nil];
        
    }

}

- (IBAction)cancelBarButtonItemPressed:(id)sender {

    [self.delegate didDismissPresentedViewControllerRegister];
    
}
@end
