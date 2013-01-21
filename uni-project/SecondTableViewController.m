//
//  SecondTableViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//


#import "SecondTableViewController.h"
#import "DetailViewManager.h"
#import "SecondDetailViewController.h"
#import "FirstDetailViewController.h"

@implementation SecondTableViewController

NSArray *rooms;

#pragma mark -
#pragma mark Rotation support

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    //NSLog(@"calling SecondTableViewController - viewWillDisappear");
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        FirstDetailViewController *prevDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
        detailViewManager.detailViewController = prevDetailViewController;
        prevDetailViewController.navigationBar.topItem.title = @"Summary";
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"patternBg.png"]];
    rooms = @[@"Büro 1", @"Büro 2", @"Büro 3"];
    
}



#pragma mark -
#pragma mark Table view selection

// -------------------------------------------------------------------------------
//	tableView:didSelectRowAtIndexPath:
// -------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    //NSLog(@"calling didSelectRowAtIndexPath from SecondTableViewController");
    //NSLog(@"didSelectRowAtIndexPath: detailViewManager: %@", self.splitViewController.delegate);
    // Get a reference to the DetailViewManager.
    // DetailViewManager is the delegate of our split view.
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    //NSLog(@"self.splitViewController: %@", self.splitViewController);
    
    // Create and configure a new detail view controller appropriate for the selection.
    UIViewController <SubstitutableDetailViewController> *detailViewController = nil;
    
    //SecondDetailViewController *newDetailViewController = [[SecondDetailViewController alloc] initWithNibName:@"SecondDetailView" bundle:nil];
    SecondDetailViewController *newDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SecondDetailView"];

    detailViewController = newDetailViewController;
    
    detailViewController.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;

    //NSLog(@"didSelectRowAtIndexPath: %@", detailViewController);
    /*if (indexPath.row == 0) {
        detailViewController.view.backgroundColor = [UIColor purpleColor];
    }
    else if (indexPath.row == 1) {
        detailViewController.view.backgroundColor = [UIColor orangeColor];
    }
    else if (indexPath.row == 2) {
        detailViewController.view.backgroundColor = [UIColor blueColor];
    }
    else {
        detailViewController.view.backgroundColor = [UIColor magentaColor];
    }*/
    
    // DetailViewManager exposes a property, detailViewController.  Set this property
    // to the detail view controller we want displayed.  Configuring the detail view
    // controller to display the navigation button (if needed) and presenting it
    // happens inside DetailViewManager
    detailViewManager.detailViewController = detailViewController;
    NSLog(@"didSelectRowAtIndexPath: detailViewManager.detailViewController: %@", detailViewManager.detailViewController);
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return rooms.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] ;
    }
    
    // Configure the cell.
    cell.textLabel.text = rooms[indexPath.row];
    return cell;
}

@end
