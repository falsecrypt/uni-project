//
//  SecondTableViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//


#import "PublicScoreTVC.h"
#import "DetailViewManager.h"
#import "PublicDetailViewController.h"
#import "FirstDetailViewController.h"
#import "Participant.h"
#import "Reachability.h"
#import "MCachedModalStoryboardSegue.h"
#import "EnergyClockViewController.h"
#import "EMNetworkManager.h"
#import "AFHTTPRequestOperation.h"

@interface PublicScoreTVC ()

@property BOOL deviceIsOnline;
@property (nonatomic, strong) NSArray *participants;
@property (nonatomic, strong) NSMutableDictionary *userForName;
@property (nonatomic, strong) NSMutableDictionary *nameForUser;
@property (nonatomic, strong) NSMutableDictionary *imageForUser;
@property (nonatomic, strong) NSMutableDictionary *scoreForUser;
@end

@implementation PublicScoreTVC


enum SectionType : NSUInteger {
    EnergyClockSection = 0,
    ParticipantSection
};

#pragma mark -
#pragma mark Rotation support

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
// -------------------------------------------------------------------------------
/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
 {
 return YES;
 }*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"patternBg.png"]];
    NSLog(@"AFTER ALLOC INIT");
    self.participants = [[NSArray alloc] initWithObjects:
                         [NSNumber numberWithInteger:FirstSensorID],
                         [NSNumber numberWithInteger:SecondSensorID],
                         [NSNumber numberWithInteger:ThirdSensorID], nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(updateRankWithNotification:)
     name:ScoreWasCalculatedWithId
     object:nil];
    
    self.navigationItem.title = @"Teilnehmer-Büros";
    [self.tableView setAllowsSelection:YES];
    NSLog(@"PTVC: viewDidLoad");
    NSLog(@"delegate:%@ dataSource:%@", self.tableView.delegate, self.tableView.dataSource);
    // allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    NSNumber *numberofentities = [Participant numberOfEntities];
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Reachable");
            self.deviceIsOnline = YES;
            
            [self getPublicUsernames];
            [self getPublicAvatars];
            
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
                NSArray *allObjects = [Participant findAll];
                for (Participant *user in allObjects) {
                    [self.nameForUser setObject:user.name forKey:user.sensorid];
                    [self.userForName setObject:user.sensorid forKey:user.name];
                }
                [self.tableView reloadData];
            }
        });
    };
    
    [reach startNotifier];
    
    for (NSNumber *sensorId in self.participants) {
        Participant *obj = [Participant findFirstByAttribute:@"sensorid" withValue:sensorId];
        if (obj.score) {
            [self.scoreForUser setObject:obj.score forKey:sensorId];
        }
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    NSLog(@"PTVC: viewWillDisappear");
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    FirstDetailViewController *prevDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
    detailViewManager.detailViewController = prevDetailViewController;
    prevDetailViewController.navigationBar.topItem.title = @"Summary";
    
}

- (NSMutableDictionary *)userForName {
    if (! _userForName) {
        _userForName = [[NSMutableDictionary alloc] init];
    }
    return _userForName;
}

- (NSMutableDictionary *)nameForUser {
    if (! _nameForUser) {
        _nameForUser = [[NSMutableDictionary alloc] init];
    }
    return _nameForUser;
}

- (NSMutableDictionary *)imageForUser {
    if (! _imageForUser) {
        _imageForUser = [[NSMutableDictionary alloc] init];
    }
    return _imageForUser;
}

- (NSMutableDictionary *)scoreForUser {
    if (! _scoreForUser) {
        _scoreForUser = [[NSMutableDictionary alloc] init];
    }
    return _scoreForUser;
}

-(void)updateRankWithNotification:(NSNotification *)pNotification{
    
//    NSDictionary *rankWithId = (NSDictionary *)[pNotification object];
//    NSNumber *userID = [[rankWithId allKeys] lastObject];
//    NSNumber *score = [rankWithId objectForKey:userID];
    
//    [self.scoreForUser setObject:score forKey:userID];
    NSIndexPath *selected = self.tableView.indexPathForSelectedRow;
    for (NSNumber *sensorId in self.participants) {
        Participant *obj = [Participant findFirstByAttribute:@"sensorid" withValue:sensorId];
        [self.scoreForUser setObject:obj.score forKey:sensorId];
    }
    NSLog(@"self.scoreForUser : %@", self.scoreForUser );
    [self.tableView reloadData];
    [self.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionNone];
    
}

- (void)saveNewAvatars {
    
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        Participant *participant1 = [Participant findFirstByAttribute:@"sensorid" withValue:@(FirstSensorID)];
        NSData *imageData1 = UIImageJPEGRepresentation([self.imageForUser objectForKey:[NSString stringWithFormat:@"%i", FirstSensorID]], 0.5);
        [participant1 setProfileimage: imageData1];
        Participant *participant2 = [Participant findFirstByAttribute:@"sensorid" withValue:@(SecondSensorID)];
        NSData *imageData2 = UIImageJPEGRepresentation([self.imageForUser objectForKey:[NSString stringWithFormat:@"%i", SecondSensorID]], 0.5);
        [participant2 setProfileimage:imageData2];
        Participant *participant3 = [Participant findFirstByAttribute:@"sensorid" withValue:@(ThirdSensorID)];
        NSData *imageData3 = UIImageJPEGRepresentation([self.imageForUser objectForKey:[NSString stringWithFormat:@"%i", ThirdSensorID]], 0.5);
        [participant3 setProfileimage:imageData3];
    } completion:^{
        
        NSArray *allObjects = [Participant findAll];
        NSLog(@"all Participants after avatars update: %@, total number: %@", allObjects, [Participant numberOfEntities]);
    }];
    
    
    [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
        NSArray *allObjects = [Participant findAll];
        NSLog(@"all Participants after avatars update: %@, total number: %@", allObjects, [Participant numberOfEntities]);
    }];
    
}

- (void)getPublicAvatars {
    
    NSMutableArray *requestsStorage = [[NSMutableArray alloc] init];
    
    for (NSNumber *sensorId in self.participants) {
        
        NSString *requestUrl = currentCostServerBaseURLString;
        requestUrl = [requestUrl stringByAppendingString:@"rpc.php?userID="];
        requestUrl = [requestUrl stringByAppendingString:[sensorId stringValue]];
        requestUrl = [requestUrl stringByAppendingString:@"&action=get&what=avatar"];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
        [requestsStorage addObject:request];
        
    }
    
    [[EMNetworkManager sharedClient]
     enqueueBatchOfHTTPRequestOperationsWithRequests:requestsStorage
     progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
         
     } completionBlock:^(NSArray *operations) {
         for (AFHTTPRequestOperation *ro in operations) {
             if (ro.error) {
                 NSLog(@"++++++++++++++ Operation error");
             } else {
                 if (ro.responseData != nil && ro.responseData.length > 0) {
                     NSDictionary *urlParameters = [self getURLParameters:ro.request.URL];
                     // Get userID from Request Parameters
                     NSString *userID = [urlParameters objectForKey:@"userID"];
                     UIImage *publicName = [[UIImage alloc] initWithData:ro.responseData];
                     [self.imageForUser setObject:publicName forKey:userID];
                     NSLog(@"new avatar: %@", publicName);
                     
                 }//end if responsedata check
                 
             }//end else no error
             
             
         }//end for completionBlock - operations
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
         });
         [self saveNewAvatars];
         
     }];
}

- (void)getPublicUsernames {
    NSLog(@"\n getPublicUsernames \n");
    NSMutableArray *requestsStorage = [[NSMutableArray alloc] init];
    
    for (NSNumber *sensorId in self.participants) {
        
        NSString *requestTemperatureUrl = currentCostServerBaseURLString;
        requestTemperatureUrl = [requestTemperatureUrl stringByAppendingString:@"rpc.php?userID="];
        requestTemperatureUrl = [requestTemperatureUrl stringByAppendingString:[sensorId stringValue]];
        requestTemperatureUrl = [requestTemperatureUrl stringByAppendingString:@"&action=get&what=username"];
        NSURLRequest *temperatureRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:requestTemperatureUrl]];
        [requestsStorage addObject:temperatureRequest];
        
    }
    
    [[EMNetworkManager sharedClient]
     enqueueBatchOfHTTPRequestOperationsWithRequests:requestsStorage
     progressBlock:^(NSUInteger numberOfCompletedOperations, NSUInteger totalNumberOfOperations) {
         
     } completionBlock:^(NSArray *operations) {
         for (AFHTTPRequestOperation *ro in operations) {
             if (ro.error) {
                 NSLog(@"++++++++++++++ Operation error");
             } else {
                 
                 if (ro.responseData != nil && ro.responseData.length > 0) {
                     NSDictionary *urlParameters = [self getURLParameters:ro.request.URL];
                     // Get userID from Request Parameters
                     NSString *userID = [urlParameters objectForKey:@"userID"];
                     NSString *publicName = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     if ([publicName isEqualToString:@"Anonymous"]) {
                         publicName = [[publicName stringByAppendingString:@" "] stringByAppendingString:userID];
                     }
                     [self.userForName setObject:userID forKey:publicName];
                     [self.nameForUser setObject:publicName forKey:userID];
                     
                 }//end if responsedata check
                 
             }//end else no error
             
             
         }//end for completionBlock - operations
         
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
         });
         [self saveNewParticipants];
         
     }];
}

// Help Method
- (NSDictionary *)getURLParameters:(NSURL *)url {
    
    NSString * q = [url query];
    NSArray * pairs = [q componentsSeparatedByString:@"&"];
    NSMutableDictionary * kvPairs = [NSMutableDictionary dictionary];
    for (NSString * pair in pairs) {
        NSArray * bits = [pair componentsSeparatedByString:@"="];
        NSString * key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString * value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [kvPairs setObject:value forKey:key];
    }
    return kvPairs;
}

- (void)saveNewParticipants
{
    NSLog(@"PTVC: initParticipants");
    if (self.deviceIsOnline)
    {
        //[Participant truncateAll]; // !!!!!
        // first time:
        if ([Participant countOfEntities] == 0) {
            [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
                Participant *participant1 = [Participant createInContext:localContext];
                [participant1 setSensorid: [NSNumber numberWithInteger:FirstSensorID]];
                [participant1 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", FirstSensorID]]];
                Participant *participant2 = [Participant createInContext:localContext];
                [participant2 setSensorid: [NSNumber numberWithInteger:SecondSensorID]];
                [participant2 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", SecondSensorID]]];
                Participant *participant3 = [Participant createInContext:localContext];
                [participant3 setSensorid: [NSNumber numberWithInteger:ThirdSensorID]];
                [participant3 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", ThirdSensorID]]];
                
            } completion:^{
                
                //                 NSArray *allObjects = [Participant findAll];
                //                 NSLog(@"all Participants after creating: %@, total number: %@", allObjects, [Participant numberOfEntities]);
            }];
        }
        // we have already saved our participants objects -> update only
        else {
            [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
                Participant *participant1 = [Participant findFirstByAttribute:@"sensorid" withValue:@(FirstSensorID)];
                [participant1 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", FirstSensorID]]];
                Participant *participant2 = [Participant findFirstByAttribute:@"sensorid" withValue:@(SecondSensorID)];
                [participant2 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", SecondSensorID]]];
                Participant *participant3 = [Participant findFirstByAttribute:@"sensorid" withValue:@(ThirdSensorID)];
                [participant3 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", ThirdSensorID]]];
            } completion:^{
                NSArray *allObjects = [Participant findAll];
                NSLog(@"all Participants after username update: %@, total number: %@", allObjects, [Participant numberOfEntities]);
            }];
            
        }
        
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
    
    //            [self performSegueWithIdentifier:@"publicDataDetails"
    //                                      sender:[users objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]];
    
    if (indexPath.section == ParticipantSection){
        NSLog(@"<PublicTableViewController> self.selectedParticipantId: %@", self.selectedParticipantId);
        [self performSegueWithIdentifier:@"publicDataDetails"
                                  sender:[self.userForName objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]];
        NSLog(@"<PublicTableViewController> sender: %@", [self.userForName objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]);
        //        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        //        PublicDetailViewController <SubstitutableDetailViewController> *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PublicDetailViewController"];
        //        detailViewController.selectedParticipant = [self.selectedParticipantId integerValue];
        //        detailViewManager.detailViewController = detailViewController;
    }
    else if(indexPath.section == EnergyClockSection){
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        UIViewController <SubstitutableDetailViewController> *detailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EnergyClockViewController"];
        detailViewManager.detailViewController = detailViewController;
        //[self performSegueWithIdentifier:@"energyClockView" sender:nil];
        
    }
    
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ParticipantSection){
        NSLog(@"<PublicTableViewController> willSelectRowAtIndexPath");
        NSArray *usersSorted = [[self.userForName allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        self.selectedParticipantId = [self.userForName objectForKey:usersSorted[indexPath.row]];
        NSLog(@"<PublicTableViewController> willSelectRowAtIndexPath : self.selectedParticipantId: %@", self.selectedParticipantId);
    }
    return indexPath;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"<PublicTableViewController> segue : %@", segue);
    
    if ([segue.identifier isEqualToString:@"publicDataDetails"])
    {
        NSLog(@"<PublicTableViewController> segue : %@", segue);
        NSLog(@"<PublicTableViewController> sender: %@", sender);
        //here is segue an instance of our MCachedModalStoryboardSegue
        MCachedModalStoryboardSegue *customSegue = (MCachedModalStoryboardSegue *)segue;
        PublicDetailViewController *destViewController = customSegue.destinationViewController;
        NSLog(@"<PublicTableViewController> customSegue.destinationViewController: %@", customSegue.destinationViewController);
        destViewController.instanceWasCached  = customSegue.destinationWasCached;
        destViewController.selectedParticipant = [self.selectedParticipantId integerValue];
        //get username from DB TODO
        
        destViewController.title = [self.nameForUser objectForKey:self.selectedParticipantId];
    }
    //    else if ([segue.identifier isEqualToString:@"energyClockView"]){
    //        MCachedModalStoryboardSegue *customSegue = (MCachedModalStoryboardSegue *)segue;
    //        EnergyClockViewController *ecVC = customSegue.destinationViewController;
    //        ecVC.instanceWasCached  = customSegue.destinationWasCached;
    //    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog(@"users: %@", users);
    if (section == ParticipantSection){
        NSLog(@"PTVC: numberOfRowsInSection");
        //return [self.userForName count];
        return 3;
    }
    else{
        return 1;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == ParticipantSection)
        return @"User Scores";
    else
        return @"Energyclock";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ParticipantSection){
        return 78.0;
    }
    else {
        return 44.0;
    }
    
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSLog(@"cellForRowAtIndexPath");
    if (indexPath.section == ParticipantSection)
    {
        
        NSLog(@"cellForRowAtIndexPath ParticipantSection");
        // Adding data to a cell using tags, we are using custom cells //
        cell = [tableView dequeueReusableCellWithIdentifier:@"participant"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"participant"] ;
        }
        
        if ([self.userForName count] > 0 && [self.imageForUser count] > 0) {
            NSArray *usersSorted = [[self.userForName allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            NSLog(@"cellForRowAtIndexPath usersSorted: %@", usersSorted);
            // Configure the cell text
            // cell.textLabel.text = usersSorted[indexPath.row];
            UILabel *label;
            UIImageView *cellImage;
            label = (UILabel *)[cell viewWithTag:4352]; // User Name Textfield
            label.text = usersSorted[indexPath.row];
            
            NSString *userID = [self.userForName objectForKey:label.text];
            UIImage *avatar = [self.imageForUser objectForKey:userID];
            cellImage = (UIImageView *)[cell viewWithTag:4354]; // Thumbnail
            [cellImage setImage:avatar];
            NSLog(@"setting avatar: %@", avatar);
            NSLog(@"self.imageForUser: %@", self.imageForUser);
            NSLog(@"[userID stringValue]: %@", userID );
            
            label = (UILabel *)[cell viewWithTag:4353]; // Score Textfield
            if ([self.scoreForUser objectForKey:@([userID intValue])] != NULL) {
                label.text = [[self.scoreForUser objectForKey:@([userID intValue])] stringValue];
                NSLog(@" label.text: %@",  label.text );
            }
            else {
                label.text = @" ";
            }
        }
        
    }
    // Overview
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"energyclock"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"energyclock"] ;
        }
        cell.textLabel.text = @"Energieuhr";
    }
    NSLog(@"section: %i", indexPath.section);
    NSLog(@"cell: %@", cell);
    NSAssert(cell!=nil, @"cell is nil!");
    return cell;
}

@end
