//
//  LastMonthsViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "AFAppDotNetAPIClient.h"
#import "DetailViewManager.h"
#import "FirstDetailViewController.h"
#import "LastMonthsViewController.h"
#import "MBProgressHUD.h"
#import "MonthData.h"
#import "Reachability.h"


NSMutableDictionary *monthsDataDictionary;
BOOL deviceIsOnline;

@interface LastMonthsViewController ()

@property MBProgressHUD *HUD;

@end



@implementation LastMonthsViewController

NSMutableArray *navigationBarItems;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (!self.instanceWasCached) {
        
        DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        detailViewManager.detailViewController = self;
        
        self.dataView.delegate = self;
        
        self.monthNameLabel.text = @" ";
        self.consumptionMonthLabel.text = @" ";
        
        if (self.navigationPaneBarButtonItem)
            [self.navigationBar.topItem setLeftBarButtonItem:self.navigationPaneBarButtonItem
                                                    animated:NO];
        
        self.dataView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"mainHistotyViewBG.png"]];
        
        NSString *secondNotificationName = @"UserLoggedOffNotification";
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(hideProfileAfterUserLoggedOff)
         name:secondNotificationName
         object:nil];
        
        self.HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:self.HUD];
        //self.HUD.delegate = self;
        self.HUD.labelText = @"Loading";
        self.HUD.yOffset = -125.f;
        [self.HUD show:YES];
        
        // allocate a reachability object
        Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
        
        reach.reachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Block Says Reachable");
                deviceIsOnline = YES;
                [self initCirclesOnline];
            });
        };
        
        reach.unreachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Block Says Unreachable");
                deviceIsOnline = NO;
                [self initCirclesOffline];
            });
        };
        
        [reach startNotifier];
        
        NSLog(@"calling viewDidLoad - Last Months!");
        
    }
    
}

- (void) initCirclesOnline {
    NSLog(@"calling initCirclesOnline!");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });

        // Lets look for Week Data in our DB
        NSNumber *numberofentities = [MonthData numberOfEntities];
    
        // We are online
        NSLog(@"deviceIsOnline : %i", deviceIsOnline);
        
        // No Data, our App has been started for the first time
        if ([numberofentities intValue]==0) {
            NSLog(@"No Data in the WeekData Table!");
            [self getMonthsData];
        }
        // We have some data, we are online so lets sync
        else {
            NSLog(@"number of entities before sync : %@", numberofentities);
            [MonthData truncateAll];
            [self getMonthsData];
        }
}

- (void) initCirclesOffline{
        NSLog(@"calling initCirclesOffline!");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });
    
        // Lets look for Week Data in our DB
        NSNumber *numberofentities = [MonthData numberOfEntities];
    
        // We are offline
        // retrieve the data from the DB
        NSLog(@"deviceIsOnline : %i", deviceIsOnline);
        // ooops, No Data. Show error TODO
        if ([numberofentities intValue]==0) {
            
            NSLog(@"No Data in the WeekData Table! and the Device is not connected to the internet..");
            
        }
        else {
            self.dataView.monthDataObjects = [MonthData findAllSortedBy:@"date" ascending:YES]; // pass monthData to the view
            [self.dataView setNeedsDisplay]; 
        }
    
}

-(void)getMonthsData {
    NSLog(@"startSynchronization...");
    
    // Start this first timer immediately, without delay
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimer* firstTimer = [NSTimer timerWithTimeInterval:0.01
                                                      target:self
                                                    selector:@selector(getDataFromServer:)
                                                    userInfo:nil
                                                     repeats:NO];
        
        [[NSRunLoop currentRunLoop] addTimer:firstTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
    });
}

- (void)getDataFromServer:(NSTimer *)timer {
    
    NSLog(@"getDataFromServer...");
    //Get user's aggregated kilowatt values per month (max 12 months, semicolon separated, latest first).
    [[AFAppDotNetAPIClient sharedClient] getPath:@"rpc.php?userID=3&action=get&what=aggregation_m" parameters:nil
                                         success:^(AFHTTPRequestOperation *operation, id data) {
                                             NSString *oneMonthData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                             NSArray *components    = [oneMonthData componentsSeparatedByString:@";"];
                                             
                                             for (NSString *obj in components) {
                                                 NSArray *month = [obj componentsSeparatedByString:@"="];
                                                 NSLog(@"month : %@", month);
                                                 NSArray *monthAndYear = [month[0] componentsSeparatedByString:@"-"];
                                                 NSLog(@"[month objectAtIndex:0] : %@", month[0]);
                                                 NSLog(@"monthAndYear : %@", monthAndYear);
                                                 double temp = [month[1] doubleValue];
                                                 NSDecimalNumber *monthConsumption = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:temp];
                                                 NSLog(@"monthConsumption : %@", monthConsumption);
                                                 NSNumber *yearNumber = (NSNumber *)@([monthAndYear[1] doubleValue]);
                                                 NSNumber *monthNumber = (NSNumber *)@([monthAndYear[0] doubleValue]);
                                                 NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
                                                 //[dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]];
                                                 [dateFormatter setDateFormat:@"yy-MM"];
                                                 // set timezone for correct date, example: 2012-06 -> 2012-06-01 00:00:00 +0000
                                                 dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
                                                 NSDate *date = [dateFormatter dateFromString:month[0]];
                                                 
                                                 MonthData *newData = [MonthData createEntity];
                                                 [newData setMonth:yearNumber];
                                                 [newData setYear:monthNumber];
                                                 [newData setConsumption:monthConsumption];
                                                 [newData setDate:date];
                                                 
                                             }
                                             
                                             [[NSManagedObjectContext defaultContext] saveNestedContexts];
                                             [self calculateRadiusForCircles];
                                             
                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             NSLog(@"Failed during getting 12-Months-Data: %@",[error localizedDescription]);
                                         }];
    
    
}

-(void) calculateRadiusForCircles {
    NSArray *results = [MonthData findAllSortedBy:@"consumption" ascending:NO];
    NSLog(@"calculateRadiusForCircle -> results: %@", results);

    // Get the max consumption value
    NSDecimalNumber * consumptionMax = [results[0]consumption];
    NSLog(@"calculateRadiusForCircle -> consumptionMax after: %@", consumptionMax);
    // Calculate radius for every object
    for (MonthData *monthdata in results){
        int circleradius = ([[monthdata consumption] intValue]*50)/[consumptionMax intValue];
        circleradius = circleradius > 19 ? circleradius : circleradius > 0 ? 20 : 0; // if bigger than 0 : min. 20
        [monthdata setCircleradius:(NSDecimalNumber *)[NSDecimalNumber numberWithInt:circleradius]];
    }
    [[NSManagedObjectContext defaultContext] saveNestedContexts]; // SAVE
    
    //NSArray *resultsEND = [MonthData findAllSortedBy:@"consumption" ascending:NO];
    //NSLog(@"calculateRadiusForCircle -> resultsEND: %@", resultsEND);
    
    self.dataView.monthDataObjects = [MonthData findAllSortedBy:@"date" ascending:YES]; // pass monthData to the view
    [self.dataView setNeedsDisplay];
}

- (void)setLabelsWithMonth:(NSString *)month andConsumption:(NSString *)kwh{
    self.monthNameLabel.text = month;
    self.consumptionMonthLabel.text = kwh;
}

#pragma mark -
#pragma mark Profile Button Methods

- (void)hideProfileAfterUserLoggedOff {
    NSLog(@"hideProfileAfterUserLoggedOff...");
    if (self.profilePopover){
        [self.profilePopover dismissPopoverAnimated:YES];
        NSLog(@"profile popover dissmissed...");
    }
    [navigationBarItems removeObject:self.profileBarButtonItem];
    [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    //    NSLog(@"rightBarButtonItems: %@", [self.navigationBar.topItem rightBarButtonItems]);
    //    NSLog(@"navigationBarItems: %@", navigationBarItems);
    //    NSLog(@"self.profileBarButtonItem: %@", self.profileBarButtonItem);
    // Going back
    [(self.splitViewController.viewControllers)[0]popToRootViewControllerAnimated:TRUE];
    DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
    FirstDetailViewController *startDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FirstDetailView"];
    detailViewManager.detailViewController = startDetailViewController;
    startDetailViewController.navigationBar.topItem.title = @"Summary";
    
}

- (IBAction)profileButtonTapped:(id)sender {
    if (_userProfile == nil) {
        self.userProfile = [[ProfilePopoverViewController alloc] init];
        //_userProfile.delegate = self;
        self.profilePopover = [[UIPopoverController alloc] initWithContentViewController:_userProfile];
        
    }
    [self.profilePopover presentPopoverFromBarButtonItem:sender
                                permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
