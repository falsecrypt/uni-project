//
//  SecondDetailViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "PublicDetailViewController.h"
#import "ParticipantDataManager.h"
#import "Reachability.h"
#import "Participant.h"
#import "ProfilePopoverViewController.h"
#import "KeychainItemWrapper.h"

@interface PublicDetailViewController ()

@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, weak)   IBOutlet UINavigationBar *navigationBar;
@property (nonatomic, weak)   IBOutlet UIBarButtonItem *profileBarButtonItem;
@property (nonatomic, strong) UIPopoverController *profilePopover;
@property (nonatomic, strong) ProfilePopoverViewController *userProfile;
@end

@implementation PublicDetailViewController

NSInteger calculatedRank;
float calculatedScore;
BOOL deviceIsOnline;

//redefine these for switch-case statement
typedef enum {
    _APlusPlusPlus = 1,
    _APlusPlus = 2,
    _APlus = 3,
    _A = 4,
    _B = 5,
    _C = 6,
    _D = 7
} RankType;


#pragma mark -
#pragma mark SubstitutableDetailViewController

// -------------------------------------------------------------------------------
//	setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the navigationBar to either show or hide the
//  navigationPaneBarButtonItem.
// -------------------------------------------------------------------------------
- (void)setNavigationPaneBarButtonItem:(UIBarButtonItem *)navigationPaneBarButtonItem
{
    if (navigationPaneBarButtonItem != _navigationPaneBarButtonItem) {
        // Add the popover button to the left navigation item.
        [self.navigationBar.topItem setLeftBarButtonItem:navigationPaneBarButtonItem
                                                animated:NO];
        
        _navigationPaneBarButtonItem = navigationPaneBarButtonItem;
    }
}

#pragma mark -
#pragma mark View lifecycle

// -------------------------------------------------------------------------------
//	viewDidLoad:
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
    DLog(@"<PublicDetailViewController> viewDidLoad");
    
    if (!self.instanceWasCached) {
        
            DLog(@"<PublicDetailViewController> viewDidLoad first init..");
        // -setNavigationPaneBarButtonItem may have been invoked when before the
        // interface was loaded.  This will occur when setNavigationPaneBarButtonItem
        // is called as part of DetailViewManager preparing this view controller
        // for presentation as this is before the view is unarchived from the NIB.
        // When viewidLoad is invoked, the interface is loaded and hooked up.
        // Check if we are supposed to be displaying a navigationPaneBarButtonItem
        // and if so, add it to the navigationBar.
        if (self.navigationPaneBarButtonItem)
            [self.navigationBar.topItem setLeftBarButtonItem:self.navigationPaneBarButtonItem
                                                    animated:NO];
        
        //DetailViewManager *detailViewManager = (DetailViewManager*)self.splitViewController.delegate;
        //detailViewManager.detailViewController = self;
        
        NSString *rankNotificationName = @"RankWasCalculated";
        rankNotificationName = [rankNotificationName stringByAppendingString:[NSString stringWithFormat:@"%d",self.selectedParticipant]];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(addRankViewWithNotification:)
         name:rankNotificationName
         object:nil];
        
        NSString *scoreNotificationName = @"ScoreWasCalculated";
        scoreNotificationName = [scoreNotificationName stringByAppendingString:[NSString stringWithFormat:@"%d",self.selectedParticipant]];
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(addScoreViewWithNotification:)
         name:scoreNotificationName
         object:nil];
        
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
        
        Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
        ParticipantDataManager *dataManager = [[ParticipantDataManager alloc] initWithParticipantId:self.selectedParticipant];
        reach.reachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                //DLog(@"Block Says Reachable");
                deviceIsOnline = YES;
                [dataManager startCalculatingRankAndScoreWithNetworkStatus:deviceIsOnline];
                
                //NSArray *results = [Participant findAllSortedBy:@"sensorid" ascending:YES];
                //DLog(@"<PublicDetailViewController> consumption from getParticipantScore: %@", consumption);
            });
        };
        
        reach.unreachableBlock = ^(Reachability * reachability)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                //DLog(@"Block Says Unreachable");
                deviceIsOnline = NO;
                [dataManager startCalculatingRankAndScoreWithNetworkStatus:deviceIsOnline];
            });
        };
        
        [reach startNotifier];
    }
    

    
}

- (void)viewDidAppear:(BOOL)animated {
    self.borderView = [[UIView alloc] initWithFrame:CGRectMake(5, 50, self.view.bounds.size.width-10, self.view.bounds.size.height-55)];
    [self.borderView.layer setCornerRadius:20.0f];
    [self.borderView.layer setBorderColor:[UIColor colorWithRed:1/255.0f green:174/255.0f blue:240/255.0f alpha:1.0f].CGColor];
    [self.borderView.layer setBorderWidth:6.0f];
    [self.view addSubview:self.borderView];
}

-(void)addScoreViewWithNotification:(NSNotification *)pNotification{
    
    
    Participant *participant =
    [Participant findFirstByAttribute:@"sensorid" withValue:[NSNumber numberWithInt:self.selectedParticipant] inContext:[NSManagedObjectContext defaultContext]];
    
    DLog(@"<PublicDetailViewController> addScore participant: %@", participant);
    
    
    calculatedScore = [[pNotification object] floatValue];
    DLog(@"<PublicDetailViewController> calculatedScore: %f", calculatedScore);
    NSString *scoreAsText = [NSString stringWithFormat:@"%.2f",calculatedScore];
    
    // TEST add Score View
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(91, 530, 200, 120)];
    [v.layer setCornerRadius:20.0f];
    [v.layer setBorderColor:[UIColor colorWithRed:1/255.0f green:174/255.0f blue:240/255.0f alpha:1.0f].CGColor];
    [v.layer setBorderWidth:3.0f];
    
    UITextView *scoreText = [[UITextView alloc] initWithFrame: CGRectMake(5, 10, 200, 80)]; //x,y,width,height
    scoreText.text = scoreAsText;
    scoreText.font =[UIFont boldSystemFontOfSize:40.0];
    scoreText.textColor = [UIColor blackColor];
    [v addSubview: scoreText];
    
    UITextView *scoreTextBottom = [[UITextView alloc] initWithFrame: CGRectMake(5, 70, 200, 40)]; //x,y,width,height
    scoreTextBottom.text = @"Score";
    scoreTextBottom.font =[UIFont systemFontOfSize:25.0];
    scoreTextBottom.textColor = [UIColor blackColor];
    [v addSubview: scoreTextBottom];
    
    [self.view addSubview:v];
    
    
}

-(void)addRankViewWithNotification:(NSNotification *)pNotification{
    calculatedRank = [[pNotification object] integerValue];

    DLog(@"<PublicDetailViewController> addRankViewWithNotification, rank = %i", calculatedRank);
    static CGFloat const WIDTH  = 170;
    static CGFloat const HEIGHT = 70;
    static CGFloat const XVALUE = 475;
    static UIImageView *imgView;
    //calculatedRank = 7; // TEST
    switch (calculatedRank) {
        case _APlusPlusPlus:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 85, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"A+++Selected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
        case _APlusPlus:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 143, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"A++Selected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
        case _APlus:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 203, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"A+Selected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
        case _A:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 260, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"ASelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
        case _B:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 314, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"BSelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
        case _C:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 370, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"CSelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
        case _D:{
            imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 425, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"DSelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            //DLog(@"imgView = %@", imgView);
            break;
        }
            
        default:
            break;
    }

    
    DLog(@"<PublicDetailViewController> imageview: %@ added to view %@", imgView, self.view);
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationBar.topItem.title = self.title;
    KeychainItemWrapper *keychain =
    [[KeychainItemWrapper alloc] initWithIdentifier:@"EcoMeterAccountData" accessGroup:nil];
    if ( ([[keychain objectForKey:(__bridge id)(kSecAttrLabel)] isEqualToString:@"LOGGEDOFF"] )
        || ( [[keychain objectForKey:(__bridge id)kSecAttrAccount] length] == 0 ) /* Or Username is empty */
        || ( [[keychain objectForKey:(__bridge id)kSecValueData] length]== 0) ) /* Or Password is empty */ {
        DLog(@"user is not logged in, removing profileBarButtonItem");
        [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
}

// -------------------------------------------------------------------------------
//	viewDidUnload:
// -------------------------------------------------------------------------------
- (void)viewDidUnload {
	[super viewDidUnload];
	self.navigationBar = nil;
}


- (void)hideProfileAfterUserLoggedOff {
    DLog(@"hideProfileAfterUserLoggedOff...");
    if (self.profilePopover)
        [self.profilePopover dismissPopoverAnimated:YES];
    // Dismiss the Profile button
    //[self.navigationItem setRightBarButtonItem:nil animated:YES];
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    
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

- (void)showProfileAfterUserLoggedIn {
    //DLog(@"!!!!! 1 calling showProfileAfterUserLoggedIn !!!!!!!!!!");
    //[navigationBarItems addObject:self.profileBarButtonItem];
    DLog(@"FirstDetail: user logged in: adding profileBarButtonItem: %@", self.profileBarButtonItem);
    [self.navigationBar.topItem setRightBarButtonItem:self.profileBarButtonItem animated:YES];
    //[self.navigationItem setRightBarButtonItem:self.profileBarButtonItem  animated:YES];
}
#pragma mark -
#pragma mark Rotation support

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
// -------------------------------------------------------------------------------
/*- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    DLog(@"<PublicDetailViewController> shouldAutorotateToInterfaceOrientation, frame w:%f h:%f", self.view.frame.size.width, self.view.frame.size.height);
    DLog(@"<PublicDetailViewController> shouldAutorotateToInterfaceOrientation, bounds w:%f h:%f", self.view.bounds.size.width, self.view.bounds.size.height);
    return YES;
}*/

@end
