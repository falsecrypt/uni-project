//
//  FirstTableViewController.m
//  uni-project
//
//  Created by Erna on 28.10.12.
//  Copyright (c) 2012 test. All rights reserved.
//

#import "FirstTableViewController.h"
#import "FirstDetailViewController.h"
#import "DetailViewManager.h"
#import "SecondTableViewController.h"

@interface FirstTableViewController ()

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"calling viewDidLoad in FirstTableViewController");

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
    return 1;
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
        LoginScreenViewController *viewController = segue.destinationViewController;
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

#pragma mark - LoginScreen delegate

-(void)userLoggedIn
{
    // User has logged in, we must change layout etc.
    
}

@end
