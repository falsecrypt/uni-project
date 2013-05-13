//
//  MyAccountTableViewController.m
//  uni-project

//  Copyright (c) 2013 test. All rights reserved.
//

#import "MyAccountTVC.h"
#import "KeychainItemWrapper.h"
#import "ProfilePopoverViewController.h"
#import "DetailViewManager.h"
#import "FirstDetailViewController.h"


@interface MyAccountTVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *profileBarButtonItem;
- (IBAction)profileButtonTapped:(UIBarButtonItem *)sender;
@property (nonatomic, strong) ProfilePopoverViewController *userProfile;
@property (nonatomic, strong) UIPopoverController *profilePopover;

@end

@implementation MyAccountTVC

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

    UIView *tempImageView = [[UIImageView alloc] init];
    [tempImageView setFrame:self.tableView.frame];
    tempImageView.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"patternBg"]];
    self.tableView.backgroundView = tempImageView;
    
    NSString *firstNotificationName = @"UserLoggedInNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showProfileAfterUserLoggedIn)
     name:firstNotificationName
     object:nil];
    
    NSString *registeredNotificationName = @"UserRegisteredNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showProfileAfterUserLoggedIn)
     name:registeredNotificationName
     object:nil];
    
    NSString *secondNotificationName = @"UserLoggedOffNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(hideProfileAfterUserLoggedOff)
     name:secondNotificationName
     object:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if ( ([[keychain objectForKey:(__bridge id)(kSecAttrLabel)] isEqualToString:@"LOGGEDOFF"] )
        || ( [[keychain objectForKey:(__bridge id)kSecAttrAccount] length] == 0 ) /* Or Username is empty */
        || ( [[keychain objectForKey:(__bridge id)kSecValueData] length]== 0) ) /* Or Password is empty */ {
        NSLog(@"user is not logged in, removing profileBarButtonItem");
        [self.navigationItem setRightBarButtonItem:self.profileBarButtonItem animated:YES];
    }
    
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue: %@", segue.identifier);
    
    ((UIViewController *)segue.destinationViewController).navigationItem.rightBarButtonItem = self.profileBarButtonItem;

}

- (void)showProfileAfterUserLoggedIn {
    //NSLog(@"!!!!! 1 calling showProfileAfterUserLoggedIn !!!!!!!!!!");
    //[navigationBarItems addObject:self.profileBarButtonItem];
    NSLog(@"FirstDetail: user logged in: adding profileBarButtonItem: %@", self.profileBarButtonItem);
    [self.navigationItem setRightBarButtonItem:self.profileBarButtonItem animated:YES];
}

- (void)hideProfileAfterUserLoggedOff {
    if (self.profilePopover)
        [self.profilePopover dismissPopoverAnimated:YES];
    // Dismiss the Profile button
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    // Going back:
    // 1. To the First Table View Controller on the left, 'Master-View'
    [(self.splitViewController.viewControllers)[0]popToRootViewControllerAnimated:TRUE];
    // 2. To the First View Controller on the right, 'Detail-View'
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    FirstDetailViewController *startDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
    detailViewManager.detailViewController = startDetailViewController;
    startDetailViewController.navigationBar.topItem.title = @"Summary";
}

- (IBAction)profileButtonTapped:(UIBarButtonItem *)sender {
    if (_userProfile == nil) {
        self.userProfile = [[ProfilePopoverViewController alloc] init];
        //_userProfile.delegate = self;
        self.profilePopover = [[UIPopoverController alloc] initWithContentViewController:_userProfile];
        
    }
    [self.profilePopover presentPopoverFromBarButtonItem:sender
                                permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    
}
@end
