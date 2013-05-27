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
#import "User.h"

@interface PublicScoreTVC ()

@property BOOL deviceIsOnline;
@property (nonatomic, strong) NSArray *participants;
@property (nonatomic, strong) NSMutableDictionary *userForName;
@property (nonatomic, strong) NSMutableDictionary *nameForUser;
@property (nonatomic, strong) NSMutableDictionary *imageForUser;
@property (nonatomic, strong) NSMutableDictionary *scoreForUser;
@property (strong, nonatomic) User *me;
@property (strong ,nonatomic) NSDictionary *rowNrForUserId;


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
    DLog(@"AFTER ALLOC INIT");
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
    DLog(@"PTVC: viewDidLoad");
    DLog(@"delegate:%@ dataSource:%@", self.tableView.delegate, self.tableView.dataSource);
    // allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    NSNumber *numberofentities = [Participant numberOfEntities];
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"Block Says Reachable");
            self.deviceIsOnline = YES;
            [self getPublicUsernames];
            [self getPublicAvatars];
            
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"Block Says Unreachable");
            self.deviceIsOnline = NO;
            // No Data, we are offline
            if ([numberofentities intValue]==0) {
                DLog(@"No Data in the Participant Table!");
                
            }
            // We have some data
            else {
                NSArray *allObjects = [Participant findAll];
                for (Participant *user in allObjects) {
                    [self.nameForUser setObject:user.name forKey:[user.sensorid stringValue]];
                    [self.userForName setObject:user.sensorid forKey:user.name];
                    if (user.profileimage) {
                        UIImage *avatarImg = [[UIImage alloc] initWithData: user.profileimage];
                        [self.imageForUser setObject:avatarImg forKey:[user.sensorid stringValue]];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    DLog(@"Unreachable, self.nameForUser: %@", self.nameForUser);
                    [self.tableView reloadData];
                 });  
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
    DLog(@"PTVC: viewWillDisappear");
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    FirstDetailViewController *prevDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
    detailViewManager.detailViewController = prevDetailViewController;
    prevDetailViewController.navigationBar.topItem.title = @"Home";
    
}

- (NSMutableDictionary *)userForName {
    if (! _userForName) {
        _userForName = [[NSMutableDictionary alloc] init];
    }
    return _userForName;
}

- (User *)me {
    if (! _me) {
        _me = [User findFirstByAttribute:@"sensorid" withValue:@(MySensorID)];
    }
    return _me;
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

- (NSDictionary *)rowNrForUserId {
    if (! _rowNrForUserId) {
        _rowNrForUserId = @{@(FirstSensorID): @(0), @(SecondSensorID): @(1), @(ThirdSensorID): @(2)};
    }
    return _rowNrForUserId;
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
        
        NSIndexPath *myIP = [NSIndexPath indexPathForRow:[[self.rowNrForUserId objectForKey:sensorId] integerValue]
                                               inSection:ParticipantSection];
        UITableViewCell *cellToUpdate = [self.tableView cellForRowAtIndexPath:myIP];
        UILabel *label = (UILabel *)[cellToUpdate viewWithTag:4353]; // Score Textfield
        label.text = [obj.score stringValue];
        [cellToUpdate setNeedsLayout];
    }
    DLog(@"self.scoreForUser : %@", self.scoreForUser );
    //[self.tableView reloadData];
    
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
        
        DLog(@"all Participants after avatars update: %@, total number: %@", [Participant findAll], [Participant numberOfEntities]);
    }];
    
    
    [[NSManagedObjectContext defaultContext]  saveInBackgroundCompletion:^{
        DLog(@"all Participants after avatars update: %@, total number: %@", [Participant findAll], [Participant numberOfEntities]);
    }];
    
}

- (void)getPublicAvatars {
    if ([self.imageForUser count] > 0) {
        return;
    }
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
                 DLog(@"++++++++++++++ Operation error");
             } else {
                 if (ro.responseData != nil && ro.responseData.length > 0) {
                     NSDictionary *urlParameters = [self getURLParameters:ro.request.URL];
                     // Get userID from Request Parameters
                     NSString *userID = [urlParameters objectForKey:@"userID"];
                     UIImage *imgFromServer = [[UIImage alloc] initWithData:ro.responseData];
                     UIImage *imageToUse = nil;
                     // If its my account:
                     if ([userID integerValue] == MySensorID) {
                         // Check whether the image from response equals the image in our DB
                         if ([ro.responseData isEqualToData:self.me.profileimage] || self.me.profileimage == nil) {
                             imageToUse = imgFromServer;
                             [self.imageForUser setObject:imgFromServer forKey:userID];
                         }
                         // OK. they are not the same, lets sync. DB-Image has higher priority
                         else {
                             UIImage *imgFromDB = [[UIImage alloc] initWithData: self.me.profileimage];
                             imageToUse = imgFromDB;
                             [self.imageForUser setObject:imgFromDB forKey:userID];
                             // Send the DB-Image to the server
                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                 [self sendImageToServer:self.me.profileimage];
                             });
                             
                         }
                         
                     }
                     // Other Users
                     else{
                         imageToUse = imgFromServer;
                         [self.imageForUser setObject:imgFromServer forKey:userID];
                     }
                     
                     // Update the cell immediatly
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSIndexPath *myIP = [NSIndexPath indexPathForRow:[[self.rowNrForUserId objectForKey:[NSNumber numberWithInt:[userID intValue]]] integerValue ]
                                                                inSection:ParticipantSection];
                         UITableViewCell *cellToUpdate = [self.tableView cellForRowAtIndexPath:myIP];
                         UIImageView *cellImage = (UIImageView *)[cellToUpdate viewWithTag:4354]; // UIImageView
                         [cellImage setImage:imageToUse];
                         [cellToUpdate setNeedsLayout];
                     });
                     
                     
                     DLog(@"new avatar: %@", imgFromServer);
                     
                 }//end if responsedata check
                 
             }//end else no error
             
             
         }//end for completionBlock - operations
         
         [self saveNewAvatars];
         
     }];
}

- (void)sendImageToServer:(NSData *)image {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:@"put" forKey:@"action"];
    [parameters setObject:@(1) forKey:@"avatar"];
    [parameters setObject:@(MySensorID) forKey:@"userID"];
    
    NSMutableURLRequest *request = [[EMNetworkManager sharedClient] multipartFormRequestWithMethod:@"POST"
                                                                                              path:@"rpc.php"
                                                                                        parameters:parameters
                                                                         constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                                             [formData appendPartWithFileData:image name:@"image" fileName:@"avatar.jpg" mimeType:@"image/jpeg"];
                                                                         }];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *response = [operation responseString];
        DLog(@"response: [%@], responseObj: %@",response, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if([operation.response statusCode] == 403){
            DLog(@"Upload Failed");
            return;
        }
        DLog(@"error: %@", [operation error]);
    }];
    
    [operation start];
}

- (void)getPublicUsernames {
    
    if ([self.userForName count] > 0) {
        return;
    }
    DLog(@"\n getPublicUsernames \n");
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
                 DLog(@"++++++++++++++ Operation error");
             } else {
                 
                 if (ro.responseData != nil && ro.responseData.length > 0) {
                     NSDictionary *urlParameters = [self getURLParameters:ro.request.URL];
                     // Get userID from Request Parameters
                     NSString *userID = [urlParameters objectForKey:@"userID"];
                     NSString *publicName = [[NSString alloc] initWithData:ro.responseData encoding:NSUTF8StringEncoding];
                     NSString *nameToUse = nil;
                     
                     // If its my account:
                     if ([userID integerValue] == MySensorID) {
                         // Check whether the username from response equals the username on our iPad
                         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                         if ([publicName isEqualToString:[defaults objectForKey:@"publicUserName"]] ||
                             [[defaults objectForKey:@"publicUserName"] length] == 0) {
                             nameToUse = publicName;
                         }
                         // OK. they are not the same, lets sync. Username in NSUserDefaults has higher priority
                         else {
                             nameToUse = [defaults objectForKey:@"publicUserName"];
                             // Send the DB-Image to the server
                             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                 [self sendPublicUsernameToServer:nameToUse];
                             });
                             
                         }
                         
                     }
                     // Other Users
                     else{
                         nameToUse = publicName;
                     }
                     
                     if ([publicName isEqualToString:@"Anonymous"]) {
                         publicName = [[publicName stringByAppendingString:@" "] stringByAppendingString:userID];
                         nameToUse = publicName;
                     }
                     // Update the cell immediatly
                     dispatch_async(dispatch_get_main_queue(), ^{
                         NSIndexPath *myIP = [NSIndexPath indexPathForRow:[[self.rowNrForUserId objectForKey:[NSNumber numberWithInt:[userID intValue]]] integerValue ]
                                                                inSection:ParticipantSection];
                         UITableViewCell *cellToUpdate = [self.tableView cellForRowAtIndexPath:myIP];
                         UILabel *label = (UILabel *)[cellToUpdate viewWithTag:4352]; // User Name Textfield
                         label.text = nameToUse;
                         [cellToUpdate setNeedsLayout];
                     });
                     
                     [self.userForName setObject:userID forKey:nameToUse];
                     [self.nameForUser setObject:nameToUse forKey:userID];
                     
                 }//end if responsedata check
                 
             }//end else no error
             
             
         }//end for completionBlock - operations

         [self saveNewParticipants];
         
     }];
}


- (void)sendPublicUsernameToServer:(NSString *)publicName {
    
    NSString *postPath = @"rpc.php?userID=";
    postPath = [postPath stringByAppendingString: [NSString stringWithFormat:@"%i", MySensorID]];
    postPath = [postPath stringByAppendingString:@"&action=put&username="];
    postPath = [postPath stringByAppendingString:publicName];
    
    [[EMNetworkManager sharedClient] postPath:postPath parameters:nil
                                      success:^(AFHTTPRequestOperation *operation, id response) {
                                          DLog(@"Public Username sent...");
                                      }
                                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                          DLog(@"Error with request, while sending public user name!");
                                          DLog(@"%@",[error localizedDescription]);
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
    DLog(@"PTVC: initParticipants");
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
                //                 DLog(@"all Participants after creating: %@, total number: %@", allObjects, [Participant numberOfEntities]);
            }];
        }
        // we have already saved some participants objects
        else {
            [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
                Participant *participant1 = [Participant findFirstByAttribute:@"sensorid" withValue:@(FirstSensorID)];
                if (participant1 == nil) {
                    participant1 = [Participant createInContext:localContext];
                    [participant1 setSensorid: [NSNumber numberWithInteger:FirstSensorID]];
                }
                [participant1 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", FirstSensorID]]];
                Participant *participant2 = [Participant findFirstByAttribute:@"sensorid" withValue:@(SecondSensorID)];
                if (participant2 == nil) {
                    participant2 = [Participant createInContext:localContext];
                    [participant2 setSensorid: [NSNumber numberWithInteger:SecondSensorID]];
                }
                [participant2 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", SecondSensorID]]];
                Participant *participant3 = [Participant findFirstByAttribute:@"sensorid" withValue:@(ThirdSensorID)];
                if (participant3 == nil) {
                    participant3 = [Participant createInContext:localContext];
                    [participant3 setSensorid: [NSNumber numberWithInteger:ThirdSensorID]];
                }
                [participant3 setName:[self.nameForUser objectForKey:[NSString stringWithFormat:@"%i", ThirdSensorID]]];
            } completion:^{
                DLog(@"all Participants after username update: %@, total number: %@", [Participant findAll], [Participant numberOfEntities]);
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
    DLog(@"<PublicTableViewController> _____didSelectRowAtIndexPath_____");
    
    //            [self performSegueWithIdentifier:@"publicDataDetails"
    //                                      sender:[users objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]];
    
    if (indexPath.section == ParticipantSection){
        DLog(@"<PublicTableViewController> self.selectedParticipantId: %@", self.selectedParticipantId);
        [self performSegueWithIdentifier:@"publicDataDetails"
                                  sender:[self.userForName objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]];
        DLog(@"<PublicTableViewController> sender: %@", [self.userForName objectForKey:[tableView cellForRowAtIndexPath:indexPath].textLabel.text]);
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
        DLog(@"<PublicTableViewController> willSelectRowAtIndexPath");
        //NSArray *usersSorted = [[self.userForName allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        //self.selectedParticipantId = [self.userForName objectForKey:usersSorted[indexPath.row]];
        self.selectedParticipantId = [self.participants[indexPath.row] stringValue];
        DLog(@"<PublicTableViewController> willSelectRowAtIndexPath : self.selectedParticipantId: %@", self.selectedParticipantId);
    }
    return indexPath;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DLog(@"<PublicTableViewController> segue : %@", segue);
    
    if ([segue.identifier isEqualToString:@"publicDataDetails"])
    {
        DLog(@"<PublicTableViewController> segue : %@", segue);
        DLog(@"<PublicTableViewController> sender: %@", sender);
        //here is segue an instance of our MCachedModalStoryboardSegue
        MCachedModalStoryboardSegue *customSegue = (MCachedModalStoryboardSegue *)segue;
        PublicDetailViewController *destViewController = customSegue.destinationViewController;
        DLog(@"<PublicTableViewController> customSegue.destinationViewController: %@", customSegue.destinationViewController);
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
    //DLog(@"users: %@", users);
    if (section == ParticipantSection){
        DLog(@"PTVC: numberOfRowsInSection");
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    DLog(@"cellForRowAtIndexPath");
    if (indexPath.section == ParticipantSection)
    {
        
        DLog(@"cellForRowAtIndexPath ParticipantSection");
        DLog(@"self.nameForUser: %@, userForName: %@", self.nameForUser, self.userForName);
        // Adding data to a cell using tags, we are using custom cells //
        cell = [tableView dequeueReusableCellWithIdentifier:@"participant"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"participant"] ;
        }
        NSString *userID = [self.participants[indexPath.row] stringValue];
        if([self.imageForUser objectForKey:userID] != nil){
            UIImage *avatar = [self.imageForUser objectForKey:userID];
            UIImageView *cellImage = (UIImageView *)[cell viewWithTag:4354];
            [cellImage setImage:avatar];
        }
        // Image Not in the cache
        else {
            ((UIImageView *)[cell viewWithTag:4354]).image = nil;
        }
        DLog(@"nameForUser valueForKey:userID: %@ userID: %@", [self.nameForUser valueForKey:userID], userID);
        if([self.nameForUser objectForKey:userID] != nil){
            UILabel *label = (UILabel *)[cell viewWithTag:4352]; // User Name Textfield
            label.text = [self.nameForUser objectForKey:userID];
            
        }
        // Username Not in the cache
        else {
            ((UILabel *)[cell viewWithTag:4352]).text = @" ";
        }
        if ([self.scoreForUser objectForKey:self.participants[indexPath.row]] != nil) {
            UILabel *label = (UILabel *)[cell viewWithTag:4353]; // Score Textfield
            label.text = [[self.scoreForUser objectForKey:self.participants[indexPath.row]] stringValue];
        }
        // Score Not in the cache
        else {
            ((UILabel *)[cell viewWithTag:4353]).text = @" ";
        }
    
        
        /*if ([self.userForName count] > 0 && [self.imageForUser count] > 0) {
            NSArray *usersSorted = [[self.userForName allKeys]sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            DLog(@"cellForRowAtIndexPath usersSorted: %@", usersSorted);
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
            DLog(@"setting avatar: %@", avatar);
            DLog(@"self.imageForUser: %@", self.imageForUser);
            DLog(@"[userID stringValue]: %@", userID );
            
            label = (UILabel *)[cell viewWithTag:4353]; // Score Textfield
            if ([self.scoreForUser objectForKey:@([userID intValue])] != NULL) {
                label.text = [[self.scoreForUser objectForKey:@([userID intValue])] stringValue];
                DLog(@" label.text: %@",  label.text );
            }
            else {
                label.text = @" ";
            }
        }*/
        
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
    DLog(@"section: %i, row: %i", indexPath.section, indexPath.row);
    DLog(@"cell: %@", cell);
    NSAssert(cell!=nil, @"cell is nil!");
    return cell;
}

@end
