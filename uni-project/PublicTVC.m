//
//  SecondTableViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//


#import "PublicTVC.h"
#import "DetailViewManager.h"
#import "PublicDetailViewController.h"
#import "FirstDetailViewController.h"
#import "Participant.h"
#import "Reachability.h"
#import "MCachedModalStoryboardSegue.h"

@interface PublicTVC ()

@property BOOL deviceIsOnline;

@end

@implementation PublicTVC

NSDictionary *users;

enum SectionType : NSUInteger {
    ParticipantSection = 0,
    OverviewSection
};

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
    
    self.navigationItem.title = @"Teilnehmer-Büros";
    
    // allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    NSNumber *numberofentities = [Participant numberOfEntities];
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Reachable");
            self.deviceIsOnline = YES;
            // No Data, our App has been started for the first time
            if ([numberofentities intValue]==0) {
                NSLog(@"No Data in the Participant Table!");
                [self initParticipants];
            }
            // We have some data
            //else {
                //[Participant truncateAll];
                //[self initParticipants];
           // }
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Unreachable");
            self.deviceIsOnline = NO;
            // No Data, we are offline
            if ([numberofentities intValue]==0) {
                NSLog(@"No Data in the Participant Table!");
                
            }
            // We have some data
            else {
                [self initParticipants];
            }
        });
    };
    
    [reach startNotifier];
    
    //get usersnames from DB or from server
    users = @{@"Büro 1":[NSNumber numberWithInt:FirstSensorID],
    @"Büro 2":[NSNumber numberWithInt:SecondSensorID],
    @"Büro 3":[NSNumber numberWithInt:ThirdSensorID]};
    
    
}

- (void)initParticipants
{
    if (self.deviceIsOnline)
    {
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext)
        {
        Participant *participant1 = [Participant createInContext:localContext];
        [participant1 setSensorid: [NSNumber numberWithInteger:FirstSensorID]];
        Participant *participant2 = [Participant createInContext:localContext];
        [participant2 setSensorid: [NSNumber numberWithInteger:SecondSensorID]];
        Participant *participant3 = [Participant createInContext:localContext];
        [participant3 setSensorid: [NSNumber numberWithInteger:ThirdSensorID]];
        
        } completion:^{
        
        //NSArray *allObjects = [Participant findAll];
        //NSLog(@"all Participants: %@", allObjects);
        }];
    }
}



#pragma mark -
#pragma mark Table view selection

// -------------------------------------------------------------------------------
//	tableView:didSelectRowAtIndexPath:
// -------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    //NSLog(@"calling didSelectRowAtIndexPath from SecondTableViewController");
    //NSLog(@"didSelectRowAtIndexPath: detailViewManager: %@", self.splitViewController.delegate);
    // Get a reference to the DetailViewManager.
    // DetailViewManager is the delegate of our split view.
    //DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    //NSLog(@"self.splitViewController: %@", self.splitViewController);
    
    // Create and configure a new detail view controller appropriate for the selection.
    //UIViewController <SubstitutableDetailViewController> *detailViewController = nil;
    
    //PublicDetailViewController *newDetailViewController = [[PublicDetailViewController alloc] initWithNibName:@"SecondDetailView" bundle:nil];
    //PublicDetailViewController *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SecondDetailView"];

    //detailViewController = newDetailViewController;
    
    //detailViewController.title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    //detailViewController.selectedParticipant = [[users objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]integerValue];

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
    //detailViewManager.detailViewController = detailViewController;
    NSLog(@"<PublicTableViewController> _____didSelectRowAtIndexPath_____");
    
    if (indexPath.section == ParticipantSection)
    {
        self.selectedParticipantId = [users objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
        [self performSegueWithIdentifier:@"publicDataDetails"
                                  sender:[users objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]];
    }
    /*else if(indexPath.section == OverviewSection)
    {
        // TODO
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        UIViewController <SubstitutableDetailViewController> *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"OverviewViewController"];
        detailViewManager.detailViewController = detailViewController;
        
    }*/
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"publicDataDetails"])
    {
        NSLog(@"<PublicTableViewController> segue : %@", segue);
        NSLog(@"<PublicTableViewController> sender: %@", sender);
        //here is segue an instance of our MCachedModalStoryboardSegue
        MCachedModalStoryboardSegue *customSegue = (MCachedModalStoryboardSegue *)segue;
        PublicDetailViewController *destViewController = customSegue.destinationViewController;
        NSLog(@"<PublicTableViewController> customSegue.destinationViewController: %@", customSegue.destinationViewController);
        destViewController.instanceWasCached  = customSegue.destinationWasCached;
        destViewController.selectedParticipant = [sender integerValue];
        //get username from DB TODO
        
        destViewController.title = [users allKeysForObject:[NSNumber numberWithInt:[sender integerValue]]][0];
    }

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"users: %@", users);
    //if (section == ParticipantSection)
    //{
        return users.count;
    //}
    /*else
    {
        return 1;
    }*/
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //if(section == ParticipantSection)
        return @"Teilnehmer";
    /*else
        return @"Übersicht"; */
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == ParticipantSection)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"participant"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"participant"] ;
        }
        NSArray *usersSorted = [[users allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        // Configure the cell text
        cell.textLabel.text = usersSorted[indexPath.row];
    }
    // Overview
   /* else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"overview"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"overview"] ;
        }
        cell.textLabel.text = @"Stromverbrauch";
    } */
    NSLog(@"section: %i", indexPath.section);
    NSAssert(cell!=nil, @"cell is nil!");
    return cell;
}

@end
