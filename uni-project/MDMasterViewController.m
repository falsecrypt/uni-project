//
//  MDMasterViewController.m
//  MultipleMasterDetailViews
//
//  Created by Todd Bates on 11/14/11.
//  Copyright (c) 2011 Science At Hand LLC. All rights reserved.
//

#import "MDMasterViewController.h"

#import "MDDetailViewController.h"

@interface MDMasterViewController ()

@property (nonatomic, strong) NSMutableArray *objectsArray;

@end

@implementation MDMasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize objectsArray = _objectsArray;

- (void)awakeFromNib
{
    self.clearsSelectionOnViewWillAppear = NO;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.detailViewController = (MDDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    NSLog(@"viewDidLoad:self.detailViewController: %@", [self.detailViewController description]);
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    
    self.objectsArray = [NSMutableArray arrayWithObjects:@"Detail 2_1 Root", @"Detail 2_2 Root", nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"detail_2_1"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = [self.objectsArray objectAtIndex:indexPath.row];
        [(MDDetailViewController *)[[segue destinationViewController] topViewController] setDetailItem:object];
    }
    else if ([[segue identifier] isEqualToString:@"detail_2_2"]){
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = [self.objectsArray objectAtIndex:indexPath.row];
        [(MDDetailViewController *)[[segue destinationViewController] topViewController] setDetailItem:object];
    }
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
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
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

/*
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     
    
    NSInteger row = indexPath.row;
    NSLog(@"You selected: %i", row);
    NSLog(@"%@",[[self.splitViewController.viewControllers lastObject] viewControllers]);
    NSString *controllerIdentifier = [NSString stringWithFormat:@"Detail 2_%i Root", row+1];
    NSLog(@"controllerIdentifier: %@", controllerIdentifier);
    UIViewController* detail = [[self.splitViewController.storyboard instantiateViewControllerWithIdentifier:controllerIdentifier]topViewController];
    UIViewController* UINavigationController = [self.splitViewController.storyboard instantiateViewControllerWithIdentifier:controllerIdentifier];
    //self.detailViewController = (MDDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    self.detailViewController = (MDDetailViewController *)detail;
    NSLog(@"UINavigationController: %@", UINavigationController);
    
    NSString *object = [self.objectsArray objectAtIndex:indexPath.row];
    NSLog(@"object: %@", object);
    [self.detailViewController setDetailItem:object];
}
 */

@end
