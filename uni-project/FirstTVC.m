//
//  FirstTableViewController.m
//  uni-project
//
//  Copyright (c) 2012 test. All rights reserved.
//

#import "DetailViewManager.h"
#import "FirstDetailViewController.h"
#import "FirstTVC.h"
#import "KeychainItemWrapper.h"
#import "SSKeychain.h"
#import "EcoMeterAppDelegate.h"
#import "PublicScoreTVC.h"

@interface FirstTVC ()

@property (nonatomic, assign) BOOL hideAccountSection;
@property (nonatomic, assign) BOOL hideLoginSection;
@property (nonatomic, assign) BOOL userLoggedInVar;

@end

@implementation FirstTVC


#pragma mark -
#pragma mark Rotation support

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
// -------------------------------------------------------------------------------
/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}*/

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //DLog(@"calling viewWillAppear in FirstTableViewController");
    
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPath].hidden = YES;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = NO;
    NSIndexPath *indexPathCreateAccount = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView cellForRowAtIndexPath:indexPathCreateAccount].hidden = NO;
    //DLog(@"1 calling viewWillAppear: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPath].hidden);
    
    // if there ist no existing account, remove the "login"-section
    if (![[keychain objectForKey:(__bridge id)kSecAttrAccount] length]) {
        
        DLog(@"there ist no existing account, remove the login-section");
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
        
        DLog(@"user account was already created, remove the create account-section");
        
        // user already logged in?
        //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        //self.userLoggedInVar = [keychain objectForKey:(__bridge id)(kSecAttrLabel)];
        DLog(@"LOGGEDIN Flag = %@", [keychain objectForKey:(__bridge id)(kSecAttrLabel)]);
        DLog(@"kSecAttrLabel: %@", [keychain objectForKey:(__bridge id)(kSecAttrLabel)]);
        if ([[keychain objectForKey:(__bridge id)(kSecAttrLabel)] isEqualToString:@"LOGGEDIN"]) {
            DLog(@"user already logged in");
            self.userLoggedInVar = true;
            [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = YES;
            [self.tableView cellForRowAtIndexPath:indexPath].hidden = NO;
            //DLog(@"2 calling viewWillAppear: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPath].hidden);
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
    
    //DLog(@"calling viewDidLoad in FirstTableViewController");

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
    //DLog(@"calling numberOfRowsInSection in FirstTableViewController with section number %i", section);
    //DLog(@"calling numberOfRowsInSection in FirstTableViewController with hideLoginSection %d", self.hideLoginSection);
    /*if ( section == 0 && self.hideLoginSection ){
        // Hide this section
         DLog(@"return 0 (section == 0)");
        return 0;
    }*/
    /*
    if ( section == 1 && self.hideAccountSection ) {
        // Hide this section
        DLog(@"return 0 (section == 1)");
        return 0;
    }*/
    // Mein Buero
    /*
    if ( section == 2 && !self.userLoggedInVar ) {
        // Hide this section
        DLog(@"return 0 (section == 2)");
        return 0;
    } */
    //else {
        //return [super tableView:self.tableView numberOfRowsInSection:section];
       // DLog(@"return 1");
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
        PublicScoreTVC *newTableViewController = [[PublicScoreTVC alloc] init];
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
        LoginScreenTVC *viewController = (LoginScreenTVC*)[segue.destinationViewController topViewController];
        viewController.delegate = self;
    }
    if ([[segue identifier] isEqualToString:@"RegisterSegue"])
    {
        // There is a navigation controller in the middle, between firsttableVC and registertableVC
        //RegisterTableViewController *viewController = [[[segue destinationViewController] viewControllers] objectAtIndex:0];
        // OR JUST:
        RegisterTVC *viewController = (RegisterTVC*)[segue.destinationViewController topViewController];
        
        /*DLog(@"calling prepareForSegue segue.destinationViewController viewControllers: %@",
              [[[segue destinationViewController] viewControllers] objectAtIndex:0]); */
        viewController.delegate = self;
    }
//    if ([[segue identifier] isEqualToString:@"publicAreaSegue"])
//    {
//        // There is a navigation controller in the middle, between firsttableVC and registertableVC
//        //RegisterTableViewController *viewController = [[[segue destinationViewController] viewControllers] objectAtIndex:0];
//        // OR JUST:
//        UITabBarController *destVC = (UITabBarController *)segue.destinationViewController;
//        EcoMeterAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//        DetailViewManager *detailViewManager = appDelegate.detailViewManager;
//        id detailVC = (detailViewManager.splitViewController.viewControllers)[1];
//        detailViewManager.splitViewController.viewControllers = [[NSArray alloc] initWithObjects:destVC, detailVC, nil];
//    } 
    
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
   //DLog(@"calling heightForRowAtIndexPath with self.hideAccountSection = %d", self.hideAccountSection);
    // user has just logged in or he hasnot created an account yet
    if (section == 0 && (self.userLoggedInVar || self.hideLoginSection)) {
        DLog(@"calling heightForRowAtIndexPath, section=0, return 0");
        return 0;
    }
    else if (section == 1 && self.hideAccountSection) {
        DLog(@"calling heightForRowAtIndexPath, section=1, return 0");
        return 0;
    }
    else if (section == 2 && !self.userLoggedInVar) {
        DLog(@"calling heightForRowAtIndexPath, section=2, return 0");
        return 0;
    }
    else {
        DLog(@"calling heightForRowAtIndexPath else: return default for section %i", section);
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
        return @"Mein Energieverbrauch";
    }
    else if (self.hideLoginSection && section == 1){
        return @"Registrieren";
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
    //DLog(@"calling userLoggedIn in FirstTableViewController");
    // User has logged in, we must change layout etc.
    self.userLoggedInVar = true;
    
    NSIndexPath *indexPathMeinBuero = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden = NO;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = YES;
    
    //DLog(@"1 calling userLoggedIn: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden);
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    //DLog(@"2 calling userLoggedIn: mein buero.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden);

    /*
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObjects:
                                            [NSIndexPath indexPathForRow:0 inSection:0], nil]
                            withRowAnimation:UITableViewRowAnimationTop];
     */

    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
}

-(void)userDidRegistered
{
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

-(void)hidePrivateDataAfterUserLoggedOff
{
    DLog(@"hidePrivateDataAfterUserLoggedOff");
    self.userLoggedInVar = false;
    self.hideLoginSection = false;
    
    NSIndexPath *indexPathMeinBuero = [NSIndexPath indexPathForRow:0 inSection:2];
    [self.tableView cellForRowAtIndexPath:indexPathMeinBuero].hidden = YES;
    NSIndexPath *indexPathLogin = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden = NO;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
    
    DLog(@"login.hidden = %i", [self.tableView cellForRowAtIndexPath:indexPathLogin].hidden);
    
}

@end
