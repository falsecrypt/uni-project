//
//  SecondDetailViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "PublicDetailViewController.h"
#import "ParticipantDataManager.h"
#import "Reachability.h"


@interface PublicDetailViewController ()



@end

@implementation PublicDetailViewController

NSInteger calculatedRank;
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
    
    NSString *notificationName = @"RankWasCalculated";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(addRankViewWithNotification:)
     name:notificationName
     object:nil];
    
    Reachability* reach = [Reachability reachabilityWithHostname:currentCostServerBaseURLHome];
    reach.reachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Reachable");
            deviceIsOnline = YES;
            [ParticipantDataManager startCalculatingRankByParticipantId:self.selectedParticipant networkReachable:deviceIsOnline];
            //[self addRankViewWithNotification:calculatedRank];
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Block Says Unreachable");
            deviceIsOnline = NO;
        });
    };
    
    [reach startNotifier];
    
    //ParticipantDataManager *pdm = [[ParticipantDataManager alloc] init];
    //NSLog(@"pdm = %@", pdm);

      
}

-(void)addRankViewWithNotification:(NSNotification *)pNotification{
    NSInteger calculatedRank = [[pNotification object] integerValue];
    NSLog(@"calling addRankViewForCalculatedRank with rank = %i", calculatedRank);
    static CGFloat const WIDTH  = 170;
    static CGFloat const HEIGHT = 70;
    static CGFloat const XVALUE = 475;
    //calculatedRank = 7; // TEST
    switch (calculatedRank) {
        case _APlusPlusPlus:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 85, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"A+++Selected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
        case _APlusPlus:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 143, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"A++Selected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
        case _APlus:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 203, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"A+Selected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
        case _A:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 260, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"ASelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
        case _B:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 314, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"BSelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
        case _C:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 370, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"CSelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
        case _D:{
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(XVALUE, 425, WIDTH, HEIGHT)]; //x,y,width,height
            NSString *imgFilepath = [[NSBundle mainBundle] pathForResource:@"DSelected" ofType:@"png"];
            UIImage *img = [[UIImage alloc] initWithContentsOfFile:imgFilepath];
            [imgView setImage:img];
            [self.view addSubview:imgView];
            NSLog(@"imgView = %@", imgView);
            break;
        }
            
        default:
            break;
    }
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationBar.topItem.title = self.title;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    //NSLog(@"calling SecondDetailViewController - viewWillDisappear");
    
}

// -------------------------------------------------------------------------------
//	viewDidUnload:
// -------------------------------------------------------------------------------
- (void)viewDidUnload {
	[super viewDidUnload];
	self.navigationBar = nil;
}

#pragma mark -
#pragma mark Rotation support

// -------------------------------------------------------------------------------
//	shouldAutorotateToInterfaceOrientation:
// -------------------------------------------------------------------------------
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

@end
