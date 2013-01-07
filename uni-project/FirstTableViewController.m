//
//  FirstTableViewController.m
//  uni-project
//
//  Copyright (c) 2012 test. All rights reserved.
//

#import "FirstTableViewController.h"
#import "FirstDetailViewController.h"
#import "DetailViewManager.h"
#import "SecondTableViewController.h"
#import "KeychainItemWrapper.h"

@interface FirstTableViewController ()

@property (nonatomic) BOOL userLoggedInVar;
@property (nonatomic) BOOL hideLoginSection;
@property (nonatomic) BOOL hideAccountSection;
@end

@implementation FirstTableViewController


#pragma mark -
#pragma mark Rotation support

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //NSLog(@"calling viewWillAppear in FirstTableViewController");
    
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPath].hidden = YES;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = NO;
    NSIndexPath *indexPathCreateAccount = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView cellForRowAtIndexPath:indexPathCreateAccount].hidden = NO;
    //NSLog(@"1 calling viewWillAppear: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPath].hidden);
    
    // if there ist no existing account, remove the "login"-section
    if (![[keychain objectForKey:(__bridge id)kSecAttrAccount] length]) {
        
        NSLog(@"there ist no existing account, remove the login-section");
        /*
        [self.tableView  beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:
                                                [NSIndexPath indexPathForRow:0 inSection:0], nil] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:0]
                      withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView  endUpdates];*/
        self.hideLoginSection = true;
        [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = YES;
    }
    // user account was already created, remove the "create account"-section
    else {
        
        NSLog(@"user account was already created, remove the create account-section");
        
        // user already logged in?
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.userLoggedInVar = [defaults boolForKey:@"userLoggedIn"];
        if (self.userLoggedInVar) {
            NSLog(@"user already logged in");
            //self.hideLoginSection = true;
            [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = YES;
            [self.tableView cellForRowAtIndexPath:indexPath].hidden = NO;
            //NSLog(@"2 calling viewWillAppear: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPath].hidden);
        }
        else {

        }
        self.hideAccountSection = true;
        NSIndexPath *indexPathCreateAccount = [NSIndexPath indexPathForRow:0 inSection:1];
        [self.tableView cellForRowAtIndexPath:indexPathCreateAccount].hidden = YES;
        [self.tableView reloadData];
        
        /*[self.tableView  beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:
                                                [NSIndexPath indexPathForRow:0 inSection:1], nil] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1]
                      withRowAnimation:UITableViewRowAnimationNone];
        
        [self.tableView  endUpdates];
        
        [self.tableView  reloadData];*/
        
    }
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.userLoggedInVar = false;
    self.hideLoginSection = false;
    self.hideAccountSection = false;
    
    UIView *tempImageView = [[UIImageView alloc] init];
    [tempImageView setFrame:self.tableView.frame];
    tempImageView.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"patternBg"]];
    self.tableView.backgroundView = tempImageView;
    
    // we use notification center for broadcasting information
    // Register to Receive a Notification
    NSString *registeredNotificationName = @"UserRegisteredNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(userDidRegistered)
     name:registeredNotificationName
     object:nil];
    
    NSString *loggedInNotificationName = @"UserLoggedInNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(userLoggedIn)
     name:loggedInNotificationName
     object:nil];
    
    NSString *loggedOffNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hidePrivateDataAfterUserLoggedOff)
     name:loggedOffNotificationName
     object:nil];
    
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //[defaults setBool:FALSE forKey:@"userLoggedIn"];
    
    //NSLog(@"calling viewDidLoad in FirstTableViewController");

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



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"calling numberOfRowsInSection in FirstTableViewController with section number %i", section);
    //NSLog(@"calling numberOfRowsInSection in FirstTableViewController with hideLoginSection %d", self.hideLoginSection);
    /*if ( section == 0 && self.hideLoginSection ){
        // Hide this section
         NSLog(@"return 0 (section == 0)");
        return 0;
    }*/
    /*
    if ( section == 1 && self.hideAccountSection ) {
        // Hide this section
        NSLog(@"return 0 (section == 1)");
        return 0;
    }*/
    // Mein Buero
    /*
    if ( section == 2 && !self.userLoggedInVar ) {
        // Hide this section
        NSLog(@"return 0 (section == 2)");
        return 0;
    } */
    //else {
        //return [super tableView:self.tableView numberOfRowsInSection:section];
       // NSLog(@"return 1");
        return 1;
   // }

}



#pragma mark - Table view delegate

// -------------------------------------------------------------------------------
//	tableView:didSelectRowAtIndexPath:
// -------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get a reference to the DetailViewManager.
    // DetailViewManager is the delegate of our split view.
    //DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    
    NSUInteger row = indexPath.row;
    
    if (row == 1) {
        SecondTableViewController *newTableViewController = [[SecondTableViewController alloc] init];
        [self.navigationController pushViewController:newTableViewController animated:YES];
        
    }
    /*
    else {
        // Create and configure a new detail view controller appropriate for the selection.
        UIViewController <SubstitutableDetailViewController> *detailViewController = nil;
        
        FirstDetailViewController *newDetailViewController = [[FirstDetailViewController alloc] initWithNibName:@"FirstDetailView" bundle:nil];
        detailViewController = newDetailViewController;
        
        detailViewController.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
        
        // DetailViewManager exposes a property, detailViewController.  Set this property
        // to the detail view controller we want displayed.  Configuring the detail view
        // controller to display the navigation button (if needed) and presenting it
        // happens inside DetailViewManager.
        detailViewManager.detailViewController = detailViewController;
        
    } */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"LoginSegue"])
    {
        //LoginScreenTableViewController *viewController = segue.destinationViewController;
        LoginScreenTableViewController *viewController = (LoginScreenTableViewController*)[segue.destinationViewController topViewController];
        viewController.delegate = self;
    }
    if ([[segue identifier] isEqualToString:@"RegisterSegue"])
    {
        // There is a navigation controller in the middle, between firsttableVC and registertableVC
        //RegisterTableViewController *viewController = [[[segue destinationViewController] viewControllers] objectAtIndex:0];
        // OR JUST:
        RegisterTableViewController *viewController = (RegisterTableViewController*)[segue.destinationViewController topViewController];
        
        /*NSLog(@"calling prepareForSegue segue.destinationViewController viewControllers: %@",
              [[[segue destinationViewController] viewControllers] objectAtIndex:0]); */
        viewController.delegate = self;
    }
}


- (void)didDismissPresentedViewControllerLogin
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES]; // deselects the "Login"-Button
    [self dismissViewControllerAnimated:YES completion:NULL]; //removes the Login Screen
    
    //dismiss the hidden view (popover on the left) or not?
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    if (detailViewManager.navigationPopoverController) {
        [detailViewManager.navigationPopoverController dismissPopoverAnimated:YES];
    }
    
}

- (void)didDismissPresentedViewControllerRegister
{
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES]; // deselects the "Login"-Button
    [self dismissViewControllerAnimated:YES completion:NULL]; //removes the Login Screen
    
    //dismiss the hidden view (popover on the left) or not?
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    if (detailViewManager.navigationPopoverController) {
        [detailViewManager.navigationPopoverController dismissPopoverAnimated:YES];
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int section = indexPath.section;
   //NSLog(@"calling heightForRowAtIndexPath with self.hideAccountSection = %d", self.hideAccountSection);
    // user has just logged in or he hasnot created an account yet
    if (section == 0 && (self.userLoggedInVar || self.hideLoginSection)) {
        NSLog(@"calling heightForRowAtIndexPath, section=0, return 0");
        return 0;
    }
    else if (section == 1 && self.hideAccountSection) {
        NSLog(@"calling heightForRowAtIndexPath, section=1, return 0");
        return 0;
    }
    else if (section == 2 && !self.userLoggedInVar) {
        NSLog(@"calling heightForRowAtIndexPath, section=2, return 0");
        return 0;
    }
    else {
        NSLog(@"calling heightForRowAtIndexPath else: return default for section %i", section);
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if((self.userLoggedInVar || self.hideLoginSection) && section == 0)
        return [[UIView alloc] initWithFrame:CGRectZero];
    else if(section == 1 && self.hideAccountSection)
        return [[UIView alloc] initWithFrame:CGRectZero];
    else if(section == 2 && !self.userLoggedInVar)
        return [[UIView alloc] initWithFrame:CGRectZero];
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if(((self.userLoggedInVar || self.hideLoginSection) && section == 0) || (section == 1 && self.hideAccountSection) || (section == 2 && !self.userLoggedInVar))
        return 1;
    return 32;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{   
    if(self.userLoggedInVar && section == 2) {
        return @"Private";
    }
    else if (self.hideLoginSection && section == 1){
        return @"Register";
    }
    else {
        return [super tableView:tableView titleForHeaderInSection:section];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if(((self.userLoggedInVar || self.hideLoginSection) && section == 0) || (section == 1 && self.hideAccountSection) || (section == 2 && !self.userLoggedInVar))
        return 1;
    return 16;
}

-(UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if((self.userLoggedInVar || self.hideLoginSection) && section == 0)
        return [[UIView alloc] initWithFrame:CGRectZero];
    else if(section == 1 && self.hideAccountSection)
        return [[UIView alloc] initWithFrame:CGRectZero];
    else if(section == 2 && !self.userLoggedInVar)
        return [[UIView alloc] initWithFrame:CGRectZero];
    return nil;
}



#pragma mark - LoginScreen delegate

-(void)userLoggedIn
{
    //NSLog(@"calling userLoggedIn in FirstTableViewController");
    // User has logged in, we must change layout etc.
    self.userLoggedInVar = true;
    
    NSIndexPath *indexPathMeinBuero = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden = NO;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = YES;
    
    //NSLog(@"1 calling userLoggedIn: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden);
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    //NSLog(@"2 calling userLoggedIn: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden);

    /*
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:
                                            [NSIndexPath indexPathForRow:0 inSection:0], nil]
                            withRowAnimation:UITableViewRowAnimationTop];
     */

    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
}

-(void)userDidRegistered {
    self.userLoggedInVar = true;
    self.hideAccountSection = true;
    NSIndexPath *indexPathMeinBuero = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden = NO;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = YES;
    NSIndexPath *indexPathCreateAccount = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView cellForRowAtIndexPath:indexPathCreateAccount].hidden = YES;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
    
}

-(void)hidePrivateDataAfterUserLoggedOff {
    self.userLoggedInVar = false;
    
    NSIndexPath *indexPathMeinBuero = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden = YES;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = NO;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
    
}

@end
