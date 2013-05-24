//
//  EnergyClockViewController.m
//  uni-project
//
//  Created by Pavel Ermolin on 28.02.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "EnergyClockViewController.h"
#import "ScrollViewContentVC.h"
#import "EnergyClockSlice.h"
#import "AKSegmentedControl.h"
#import "SliceDetailsView.h"
#import "EnergyClockDataManager.h"
#import "EcoMeterAppDelegate.h"
#import "MBProgressHUD.h"
#import "Participant.h"
#import "ProfilePopoverViewController.h"
#import "KeychainItemWrapper.h"

// identifiers/tags
static const int numberPages    = 2;
static const int numberSlices   = 12; // 12 time intervalls, 00:00-02:00-..., sometimes == 11 !
static const int topScrollView  = 9; // ScrollView identifiers
static const int mainScrollView = 10;
static const int sliceDetailsView = 13;


@interface EnergyClockViewController ()<UIScrollViewDelegate, BTSPieViewDataSource, BTSPieViewDelegate>

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
//@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet BTSPieView *energyClockView;
// Used to display so called 'EnergyClock-Multilevel-Pie Chart', center of the screen -> Slice Values
@property (nonatomic, strong) NSMutableArray *sliceValues;
// Used to display so called 'EnergyClock-Multilevel-Pie Chart', center of the screen -> Slot Values
@property (nonatomic, strong) NSMutableArray *slotValuesForSlice;
@property (nonatomic, strong) NSMutableArray *temperatureValues;
@property (nonatomic, strong) NSMutableDictionary *userTemperatureValues;
// Data for a Detail Pie Chart, when user selects a participant using our 'participantSelector'
// Holds the values of all participants for the current date, Form: [Slice] => [[userId]=>[consumption]]
@property (nonatomic, strong) NSArray *dayUserConsumption;
@property (nonatomic, strong) NSArray *availableSliceColors;
@property (nonatomic, strong) NSArray *availableCPTColors;
@property (nonatomic, strong) NSDictionary *CPTColorsForParticipants;
@property (nonatomic, assign) NSInteger selectedSliceIndex;
//@property (nonatomic, assign) CGFloat energyClockViewRadius;
@property (nonatomic, strong) NSDate *currentDate;

@property (strong, nonatomic) AKSegmentedControl *participantSelector;

@property (weak, nonatomic) IBOutlet SliceDetailsView *sliceDetailsView;
@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property (assign, nonatomic) NSInteger selectedEnergyClockSlice;
@property (assign, nonatomic) BOOL waitingForNewData;
@property (assign, nonatomic) NSInteger selectedParticipantId;
@property (nonatomic, strong) MBProgressHUD *HUD;

@property (nonatomic, strong) ProfilePopoverViewController *userProfile;
@property (nonatomic, strong) UIPopoverController *profilePopover;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *profileBarButtonItem;

- (IBAction)profileButtonTapped:(id)sender;

@end

@implementation EnergyClockViewController

static const NSArray *participants;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        DLog(@"EnergyClockViewController-initWithNibName");
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(initEnergyClockAfterSavingData) // when the data has been saved we will be notified
     name:EnergyClockDataSaved
     object:nil];
    
    [self startHUD];
    
    participants = [[NSArray alloc] initWithObjects:
                    [NSNumber numberWithInteger:FirstSensorID],
                    [NSNumber numberWithInteger:SecondSensorID],
                    [NSNumber numberWithInteger:ThirdSensorID], nil];
    
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
    
    self.sliceDetailsView.datasource = self;
    self.sliceDetailsView.tag = sliceDetailsView;
    
    self.selectedEnergyClockSlice = -1;
    self.selectedParticipantId = FirstSensorID;
    
    // TEST
    // Must divide by 255.0F... RBG values are between 0.0 and 1.0
    self.availableSliceColors = [NSArray arrayWithObjects:
                                 [UIColor colorWithRed:93.0f/255.0f green:150.0f/255.0f blue:72.0f/255.0f alpha:1.0f],
                                 [UIColor colorWithRed:46.0f/255.0f green:87.0f/255.0f blue:140.0f/255.0f alpha:1.0f],
                                 [UIColor colorWithRed:231.0f/255.0f green:161.0f/255.0f blue:61.0f/255.0f alpha:1.0f],
                                 [UIColor colorWithRed:188.0f/255.0f green:45.0f/255.0f blue:48.0f/255.0f alpha:1.0f],
                                 [UIColor colorWithRed:111.0f/255.0f green:61.0f/255.0f blue:121.0f/255.0f alpha:1.0f],
                                 [UIColor colorWithRed:125.0f/255.0f green:128.0f/255.0f blue:127.0f/255.0f alpha:1.0f],
                                 nil];
    self.availableCPTColors =
    [NSArray arrayWithObjects:
     [CPTColor colorWithComponentRed:93.0f/255.0f green:150.0f/255.0f blue:72.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:46.0f/255.0f green:87.0f/255.0f blue:140.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:231.0f/255.0f green:161.0f/255.0f blue:61.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:188.0f/255.0f green:45.0f/255.0f blue:48.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:111.0f/255.0f green:61.0f/255.0f blue:121.0f/255.0f alpha:1.0f],
     [CPTColor colorWithComponentRed:125.0f/255.0f green:128.0f/255.0f blue:127.0f/255.0f alpha:1.0f],
     nil];
    
    self.CPTColorsForParticipants = [[NSDictionary alloc] init];
    NSMutableDictionary *CPTColorsForParticipantsMutable = [self.CPTColorsForParticipants mutableCopy];
    for (int i=0; i<[participants count]; i++) {
        [CPTColorsForParticipantsMutable setObject:self.availableCPTColors[i] forKey:participants[i]];
    }
    self.CPTColorsForParticipants = CPTColorsForParticipantsMutable;
    
    // Segmented Control #1
    UILabel *segmentedControl1Label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.origin.x + 10.0, 400.0, 380.0, 20.0)]; // x,y,width,height
                                                                                                                                       //[segmentedControl1Label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [segmentedControl1Label setText:SegmentedControlLabelText];
    [segmentedControl1Label setTextAlignment:NSTextAlignmentCenter];
    [segmentedControl1Label setBackgroundColor:[UIColor clearColor]];
    [segmentedControl1Label setTextColor:[UIColor colorWithRed:82.0/255.0 green:113.0/255.0 blue:131.0/255.0 alpha:1.0]];
    [segmentedControl1Label setShadowColor:[UIColor whiteColor]];
    [segmentedControl1Label setShadowOffset:CGSizeMake(0.0, 1.0)];
    [segmentedControl1Label setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0]];
    
    [self.mainScrollView addSubview:segmentedControl1Label];
    self.participantSelector = [[AKSegmentedControl alloc] initWithFrame:CGRectMake(self.view.frame.origin.x + 10.0,
                                                                                    CGRectGetMaxY(segmentedControl1Label.frame) + 10.0, 380.0, 37.0)];
    [self.participantSelector addTarget:self action:@selector(segmentedViewController:) forControlEvents:UIControlEventValueChanged];
    [self.participantSelector setSegmentedControlMode:AKSegmentedControlModeSticky];
    [self.participantSelector setSelectedIndex:0];
    
    [self setupSegmentedControl];
    
    [[EnergyClockDataManager sharedClient] calculateValuesWithMode:DayChartsMode];
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    self.temperatureValues = [[NSMutableArray alloc]initWithCapacity:numberSlices];
    self.userTemperatureValues = [[NSMutableDictionary alloc] init];
    for (int i=0; i<numberSlices; i++) {
        [self.temperatureValues insertObject:@(0) atIndex:i];
    }
    
    for (NSUInteger i = 0; i < numberPages; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    
    self.scrollView.delegate = self;
    self.scrollView.tag = topScrollView;
    self.mainScrollView.delegate = self;
    self.mainScrollView.tag = mainScrollView;
    self.pageControl.numberOfPages = numberPages;
    self.pageControl.currentPage = 0;
    
    // set up the data source and delegate
    [self.energyClockView setDataSource:self];
    [self.energyClockView setDelegate:self];
    self.selectedSliceIndex = -1;
    //float animationDuration = 1.0f;
    //[self.energyClockView setAnimationDuration:animationDuration];
    
    //[self.energyClockView reloadData];
    [self checkSyncStatus];
    
    DLog(@"viewDidLoad-after checkSyncStatus, self.sliceValues: %@", self.sliceValues);
    DLog(@"viewDidLoad-after checkSyncStatus, self.slotValuesForSlice: %@", self.slotValuesForSlice);
    EcoMeterAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    DetailViewManager *detailViewManager = appDelegate.detailViewManager;
    DLog(@"viewDidLoad detailViewManager.splitViewController.viewControllers: %@", detailViewManager.splitViewController.viewControllers);
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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
    
    // IMPORTANT:
    if (self.sliceDetailsView) {
        [self.sliceDetailsView killAll];
    }
    
    //            for (UIViewController *vc in self.childViewControllers) {
    //                [vc willMoveToParentViewController:nil];
    //                [vc removeFromParentViewController];
    //            }
    // CANNOT REMOVE THE MAINSCROLLVIEW -> CRASH
    //for(UIView *view in self.view.subviews){
    //    DLog(@"view: %@ removing in progress..", view);
    //    if (view.tag == mainScrollView) {
    //        for (UIView *v in view.subviews) {
    //            if (v.tag == sliceDetailsView) {
    //                DLog(@"[inside] - bingo!");
    //                [(SliceDetailsView *)v killAll];
    //                DLog(@"[inside] - vorbei!");
    //            }
    //        }
    //    }
    //    [view removeFromSuperview];
    //    DLog(@"view: %@ removed!", view);
    //}
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // a page is the width of the scroll view
    self.scrollView.contentSize =
    CGSizeMake(CGRectGetWidth(self.scrollView.frame) * numberPages, CGRectGetHeight(self.scrollView.frame));
    
    self.mainScrollView.contentSize =
    CGSizeMake(CGRectGetWidth(self.mainScrollView.frame), CGRectGetHeight(self.energyClockView.frame) + CGRectGetHeight(self.sliceDetailsView.frame));
    DLog(@"self.mainScrollView.contentSize h: %f, w: %f", self.mainScrollView.contentSize.height, self.mainScrollView.contentSize.width);
    
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
    
    //    CGRect parentLayerBounds = [self.energyClockView bounds];
    //    CGFloat centerX = parentLayerBounds.size.width / 2.0f;
    //    CGFloat centerY = parentLayerBounds.size.height / 2.0f;
    
    // Reduce the radius just a bit so the the pie chart layers do not hug the edge of the view.
    // self.energyClockViewRadius = MIN(centerX, centerY) - 20.0;
    
    // Create and display Pie Chart slices, animated
    // we use dummy values for testing purposes
    
    /*for (int insertIndex=0; insertIndex<numberSlices; insertIndex++) {
     
     NSMutableArray *innerArray = [[NSMutableArray alloc]initWithCapacity:numberOfParticipants];
     
     for (int i=0; i<numberOfParticipants; i++) {
     [innerArray insertObject:@(arc4random()/21*0.1) atIndex:i];
     }
     [self.slotValuesForSlice insertObject:innerArray atIndex:insertIndex];
     
     [self.sliceValues insertObject:[NSNumber numberWithFloat:insertIndex+0.53] atIndex:insertIndex];
     //[self.energyClockView insertSliceAtIndex:insertIndex animate:YES];
     }*/
    
    DLog(@"before calling reloadData!");
    [self.energyClockView reloadData];
    
    if (self.waitingForNewData == NO) {
        self.sliceDetailsView.slotValuesForSlice = self.slotValuesForSlice;
        DLog(@"<EnergyClockVC> calling viewDidAppear");
        [self.sliceDetailsView initPlots];
        [self hideHUD];
    }
    
}


-(void)startHUD
{
    self.HUD = [[MBProgressHUD alloc] initWithView:self.mainScrollView];
    [self.mainScrollView addSubview:self.HUD];
	self.HUD.labelText = @"Loading";
    self.HUD.yOffset = -125.f;
    [self.HUD show:YES];
}

-(void)hideHUD
{
    [MBProgressHUD hideHUDForView:self.mainScrollView animated:YES];
    //[self.HUD removeFromSuperview];
    //self.HUD = nil;
    //DLog(@"after|self.mainScrollView.contentSize h: %f, w: %f", self.mainScrollView.contentSize.height, self.mainScrollView.contentSize.width);
}

// should we display the energyclock of the last date immediately
// or should we wait to the 'AggregatedDaysSaved'-Notification?
-(void)checkSyncStatus
{
    /* Get last sync date, ==today? -> then do nothing! */
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSDateComponents *todayComponents =
    [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
    NSAssert(systemObj!=nil, @"System Object with id=primary doesnt exist");
    DLog(@"checkSyncStatus systemObj: %@", systemObj);
    NSDate *lastSyncDate = systemObj.daysupdated;
    DLog(@"checkSyncStatus lastSyncDate: %@", lastSyncDate);
    DLog(@"checkSyncStatus todayComponents: %@", todayComponents);
    
    if ([lastSyncDate isKindOfClass:[NSDate class]] && !FORCEDAYCHARTSUPDATE){
        
        NSDateComponents *lastSyncComponents =
        [calendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:lastSyncDate];
        
        if(([todayComponents year]  == [lastSyncComponents year])  &&
           ([todayComponents month] == [lastSyncComponents month]) &&
           ([todayComponents day]   == [lastSyncComponents day]))
        {
            DLog(@"checkSyncStatus, we synced already");
            // we have synced today already
            self.waitingForNewData = NO;
            EnergyClockSlice *slice = [EnergyClockSlice findFirstOrderedByAttribute:@"date" ascending:NO];
            [self initValuesForNewDate:slice.date];
            self.currentDate = slice.date;
        }
        else {
            self.waitingForNewData = YES;
        }
    }
    else {
        self.waitingForNewData = YES;
    }
}

-(void)initEnergyClockAfterSavingData
{
    DLog(@"initEnergyClockAfterSavingData");
    DLog(@"System numberOfEntities in initEnergyClockAfterSavingData: %@", [System numberOfEntities]);
    NSArray *allsystems = [System findAll];
    
    for (System *sys in allsystems) {
        DLog(@"System object daysupdated: %@", sys.daysupdated);
    }
    EnergyClockSlice *slice = [EnergyClockSlice findFirstOrderedByAttribute:@"date" ascending:NO];
    [self initValuesForNewDate:slice.date];
    self.currentDate = slice.date;
    // OK we're done, lets reload the energyclock and init the detail plots
    DLog(@"before calling reloadData!");
    [self.energyClockView reloadData];
    self.sliceDetailsView.slotValuesForSlice = self.slotValuesForSlice;
    [self.sliceDetailsView initPlots];
    [self hideHUD];
}

-(NSMutableArray*)sliceValues
{
    if(!_sliceValues){
        _sliceValues = [[NSMutableArray alloc]initWithCapacity:numberSlices];
    }
    return _sliceValues;
}

-(NSMutableArray*)slotValuesForSlice
{
    if(!_slotValuesForSlice){
        _slotValuesForSlice = [[NSMutableArray alloc]initWithCapacity:numberSlices];
        
        for (int i=0; i<numberSlices; i++) {
            [_slotValuesForSlice insertObject:[NSNull null] atIndex:i];
        }
    }
    return _slotValuesForSlice;
}

-(NSMutableArray*)temperatureValues
{
    if(!_temperatureValues){
        _temperatureValues = [[NSMutableArray alloc]initWithCapacity:numberSlices];
        
        for (int i=0; i<numberSlices; i++) {
            [_temperatureValues insertObject:[NSNull null] atIndex:i];
        }
    }
    return _temperatureValues;
}

// random values
-(NSMutableArray*)radiusValuesForSlice
{
    if(!_radiusValuesForSlice){
        _radiusValuesForSlice = [[NSMutableArray alloc]initWithCapacity:numberSlices];
        
        NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey: @"self" ascending: YES];
        for (int i=0; i<numberSlices; i++) {
            NSMutableArray *radiusStepArray = [[NSMutableArray alloc] init];
            for (int j=0; j<numberOfParticipants; j++) {
                [radiusStepArray insertObject:[NSNumber numberWithInt:arc4random()%80+20] atIndex:j];
            }
            NSArray *sortedArray = [radiusStepArray sortedArrayUsingDescriptors: [NSArray arrayWithObject: sortOrder]];
            [_radiusValuesForSlice insertObject:sortedArray atIndex:i];
        }
    }
    return _radiusValuesForSlice;
}

- (void)loadScrollViewWithPage:(NSUInteger)page
{
    DLog(@"loadScrollViewWithPage...");
    // replace the placeholder if necessary
    ScrollViewContentVC *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null])
    {
        controller = [[ScrollViewContentVC alloc] initWithPageNumber:page andUIViewController:self];
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (controller.view.superview == nil)
    {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = CGRectGetWidth(frame) * page;
        frame.origin.y = 0;
        controller.view.frame = frame;
        
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
        DLog(@"<EnergyClockViewController> controller.view: %@", controller.view);
        DLog(@"<EnergyClockViewController> controller.view.subviews: %@", controller.view.subviews);
        
        /*
         NSDictionary *numberItem = [self.contentList objectAtIndex:page];
         controller.numberImage.image = [UIImage imageNamed:[numberItem valueForKey:kImageKey]];
         controller.numberTitle.text = [numberItem valueForKey:kNameKey];
         */
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    DLog(@"<EnergyClockViewController> scrollViewWillBeginDecelerating...");
    
}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    DLog(@"<EnergyClockViewController> scrollViewDidEndDecelerating...");
    // Top ScrollView with day-Pie-Charts
    if (scrollView.tag == topScrollView) {
        // switch the indicator when more than 50% of the previous/next page is visible
        CGFloat pageWidth = CGRectGetWidth(self.scrollView.frame);
        NSUInteger page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        self.pageControl.currentPage = page;
        
        // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
        if (page == 0)
        {
            [self loadScrollViewWithPage:page];
            [self loadScrollViewWithPage:page + 1];
        }
        else if (page == 1)
        {
            [self loadScrollViewWithPage:page - 1];
            [self loadScrollViewWithPage:page];
        }
        
    }
    // Main ScrollView with Slice-Details-Pie-Charts
    else if (scrollView.tag == mainScrollView){
        
    }
    
    // a possible optimization would be to unload the views+controllers which are no longer visible
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load the pages which are now on screen
    //DLog(@"<EnergyClockViewController> scrollViewDidScroll...");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// this method is called after user touched one of the day charts
-(void)loadEnergyClockForDate:(NSDate *)date
{
    if ([self.currentDate isEqualToDate:date]) {
        DLog(@"<EnergyClockViewController> -loadEnergyClockForWeekDay, plot with date: %@ touched, same date as the current -> returning..", date);
        return;
    }
    DLog(@"<EnergyClockViewController> -loadEnergyClockForWeekDay, plot with date: %@ touched", date);
    
    [self initValuesForNewDate:date];
    self.currentDate = date;
    DLog(@"before calling reloadData!");
    [self.energyClockView reloadData];
    // Reload Details Pie Charts
    self.selectedEnergyClockSlice = 0; // select the first slice
    [self.sliceDetailsView reloadPieChartForNewSlice:self.selectedEnergyClockSlice];
    self.selectedParticipantId = FirstSensorID; // select the default user
    [self.sliceDetailsView reloadPieChartForNewParticipant:self.selectedParticipantId];
    [self.participantSelector setSelectedIndex:0]; // select the first button/segment part per default
}

-(void)initValuesForNewDate:(NSDate *)date
{
    // check if data exists @todo
    NSArray *slicesData = [EnergyClockSlice findByAttribute:@"date" withValue:date andOrderBy:@"hour" ascending:YES];
    DLog(@"initValuesForNewDate: slicesData: %i Objs found", [slicesData count]);
    NSMutableArray *slotValuesForSliceTemp = [[NSMutableArray alloc] init];
    NSMutableArray *sliceValuesTemp = [[NSMutableArray alloc] init];
    NSMutableArray *dayUserConsumptionTemp = [[NSMutableArray alloc]init];
    // DEBUGGING
    for (int i=0; i<[slicesData count]; i++) {
        EnergyClockSlice *slice = slicesData[i];
        DLog(@"date: %@, hour: %@, consumption: %@, tempUsers: %@", slice.date, slice.hour, slice.consumption, [NSKeyedUnarchiver unarchiveObjectWithData:slice.temperatureUsers]);
    }
    if ([slicesData count] > 0) {
        
        // there must be exactly 12 objects in the slicesData-Array
        for (int insertIndex=0; insertIndex<[slicesData count]; insertIndex++) {
            // energy consumption of every user/partcipant
            NSMutableArray *innerArray = [[NSMutableArray alloc]initWithCapacity:numberOfParticipants];
            EnergyClockSlice *slice = slicesData[insertIndex];
            // Get User-Temp-Dict
            NSDictionary *userTemperatureValues = [[NSDictionary alloc] init];
            if (slice.temperatureUsers != nil) {
                userTemperatureValues = [NSKeyedUnarchiver unarchiveObjectWithData:slice.temperatureUsers];
            }
            [self.userTemperatureValues setObject:userTemperatureValues forKey:slice.hour];
            if (insertIndex > 0) {
                [self.temperatureValues replaceObjectAtIndex:insertIndex-1 withObject:slice.temperature];
            }
            else {
                [self.temperatureValues replaceObjectAtIndex:[slicesData count]-1 withObject:slice.temperature];
            }
            DLog(@"slice.date: %@, slice.hour: %@, slice.temperature: %@", slice.date, slice.hour, slice.temperature);
            NSMutableDictionary *slotValuesDict = [NSKeyedUnarchiver unarchiveObjectWithData:slice.slotValues];
            NSArray *sortedkeys = [[slotValuesDict allKeys]sortedArrayUsingSelector:@selector(compare:)];
            DLog(@"slotValuesDict: %@", slotValuesDict);
            DLog(@"sortedkeys: %@", sortedkeys);
            NSAssert(numberOfParticipants == [sortedkeys count], @"Check the number of users");
            for (int i = 0; i < numberOfParticipants; i++) {
                [innerArray insertObject:[slotValuesDict objectForKey:sortedkeys[i]] atIndex:i];
            }
            
            [slotValuesForSliceTemp insertObject:innerArray atIndex:insertIndex];
            // fill with 12 slice values for that selected date
            [sliceValuesTemp insertObject:((EnergyClockSlice *)slicesData[insertIndex]).consumption atIndex:insertIndex];
            
            [dayUserConsumptionTemp insertObject:slotValuesDict atIndex:insertIndex];
            
        }
        self.sliceValues = sliceValuesTemp;
        DLog(@"self.sliceValues: %@", self.sliceValues);
        self.slotValuesForSlice = slotValuesForSliceTemp;
        self.dayUserConsumption = dayUserConsumptionTemp;
        DLog(@"slotValuesForSlice: %@", self.slotValuesForSlice);
        DLog(@"original setting userTemperatureValues : %@", self.userTemperatureValues );
        DLog(@"dayUserConsumption: %@", self.dayUserConsumption);
        DLog(@"\n initValuesForNewDate self.temperatureValues %@ \n", self.temperatureValues);
    }
}


- (void)gotoPage:(BOOL)animated {
    NSInteger page = self.pageControl.currentPage;
    
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    if (page == 0)
    {
        [self loadScrollViewWithPage:page];
        [self loadScrollViewWithPage:page + 1];
    }
    else if (page == 1)
    {
        [self loadScrollViewWithPage:page - 1];
        [self loadScrollViewWithPage:page];
    }
    
	// update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = CGRectGetWidth(bounds) * page;
    bounds.origin.y = 0;
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (IBAction)changePage:(id)sender {
    DLog(@"<EnergyClockViewController> changePage...");
    [self gotoPage:YES];    // YES = animate
}

#pragma mark - BTSPieView Data Source

- (NSUInteger)numberOfSlicesInPieView:(BTSPieView *)pieView {
    DLog(@"numberOfSlicesInPieView:");
    DLog(@"sliceValues: %@", self.sliceValues);
    return [self.sliceValues count];
    //return numberSlices;
}

// TODO : new
- (NSUInteger)numberOfSlotsInPieView:(BTSPieView *)pieView {
    return numberOfParticipants;
}

- (CGFloat)pieView:(BTSPieView *)pieView valueForSliceAtIndex:(NSUInteger)index {
    
    CGFloat result = 0.0f;
    if (index < [self.sliceValues count]-1) {
        result = (CGFloat)[[self.sliceValues objectAtIndex:index+1]floatValue];
    }
    else {
        result = (CGFloat)[[self.sliceValues objectAtIndex:0]floatValue];
    }
    DLog(@"returning: %f", result);
    return result;
}

// TODO : new
- (CGFloat)pieView:(BTSPieView *)pieView valueForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex {
    return (CGFloat)[[[self.slotValuesForSlice objectAtIndex:sliceIndex] objectAtIndex:slotIndex] floatValue];
    
}
// for SliceDetailsView
- (NSNumber *)valueForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex {
    return [[self.slotValuesForSlice objectAtIndex:sliceIndex] objectAtIndex:slotIndex];
}

- (NSNumber *)detailsSliceValueAtIndex:(NSUInteger)index {
    // return 12 Values for the current participant
    // using dayUserConsumption-Array
    NSDecimalNumber *result = [[self.dayUserConsumption objectAtIndex:index] objectForKey: [NSString stringWithFormat:@"%i",self.selectedParticipantId] ];
    DLog(@"detailsSliceValueAtIndex - result: %@", result);
    DLog(@"detailsSliceValueAtIndex - self.selectedParticipantId: %i", self.selectedParticipantId);
    DLog(@"detailsSliceValueAtIndex - selectedParticipantId as string: %@", [NSString stringWithFormat:@"%i",self.selectedParticipantId]);
    DLog(@"detailsSliceValueAtIndex - [self.dayUserConsumption objectAtIndex:index] %@", [self.dayUserConsumption objectAtIndex:index]);
    DLog(@"detailsSliceValueAtIndex - self.dayUserConsumption: %@", self.dayUserConsumption);
    return result;
}

- (NSUInteger)getSlicesNumber {
    return [self.sliceValues count];
}

- (CPTColor *)getColorForParticipantId:(NSUInteger)idx {
    DLog(@"self.CPTColorsForParticipants: %@", self.CPTColorsForParticipants);
    DLog(@"input idx: %@", @(idx));
    return [self.CPTColorsForParticipants objectForKey:@(idx)];
}

- (UIColor *)getColorForTempLabel:(NSUInteger)idx {
    DLog(@"self.CPTColorsForParticipants: %@", self.availableSliceColors);
    DLog(@"input idx: %@", @(idx));
    DLog(@"getColorForTempLabel returning: %@", [self.availableSliceColors objectAtIndex:idx]);
    return [self.availableSliceColors objectAtIndex:idx];
}


// do i need this method?
- (CGFloat)pieView:(BTSPieView *)pieView radiusForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex {
    return (CGFloat)[[[self.radiusValuesForSlice objectAtIndex:sliceIndex] objectAtIndex:slotIndex] floatValue];
}

- (NSArray *)getRadiusArray {
    return self.radiusValuesForSlice;
}

- (NSArray *)getTemperatureValues {
    DLog(@"\n self.temperatureValues %@ !\n", self.temperatureValues);
    return self.temperatureValues;
}

- (NSDictionary *)getUserTemperatureValues {
    DLog(@"\n getUserTemperatureValues %@ !\n", self.userTemperatureValues);
    return self.userTemperatureValues;
}

- (NSArray *)getSlotValuesForSliceArray {
    return self.slotValuesForSlice;
}
/* DEPRECATED
 - (UIColor *)pieView:(BTSPieView *)pieView colorForSliceAtIndex:(NSUInteger)index sliceCount:(NSUInteger)sliceCount
 {
 return [(BTSSliceData *)[_slices objectAtIndex:index] color];
 }
 */

// TODO : new
- (UIColor *)pieView:(BTSPieView *)pieView colorForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex sliceCount:(NSUInteger)sliceCount {
    DLog(@"color for slotIndex %i found color: %@!", slotIndex, [self.availableSliceColors objectAtIndex:slotIndex]);
    
    return [self.availableSliceColors objectAtIndex:slotIndex];
}

#pragma mark - BTSPieView Delegate

- (void)pieView:(BTSPieView *)pieView willSelectSliceAtIndex:(NSInteger)index {
}

- (void)pieView:(BTSPieView *)pieView didSelectSliceAtIndex:(NSInteger)index {
    /*
     // save the index the user selected.
     _selectedSliceIndex = index;
     
     // update the selected slice UI components with the model values
     BTSSliceData *sliceData = [_slices objectAtIndex:(NSUInteger)_selectedSliceIndex];
     [_selectedSliceValueLabel setText:[NSString stringWithFormat:@"%d", [sliceData value]]];
     [_selectedSliceValueLabel setAlpha:1.0];
     
     [_selectedSliceValueSlider setValue:[sliceData value]];
     [_selectedSliceValueSlider setEnabled:YES];
     [_selectedSliceValueSlider setMinimumTrackTintColor:[sliceData color]];
     [_selectedSliceValueSlider setMaximumTrackTintColor:[sliceData color]];
     */
    
    DLog(@"slice %i ws selected!", index);
    self.selectedEnergyClockSlice = index;
    [self.sliceDetailsView reloadPieChartForNewSlice:index];
}

- (void)pieView:(BTSPieView *)pieView willDeselectSliceAtIndex:(NSInteger)index {
}

- (void)pieView:(BTSPieView *)pieView didDeselectSliceAtIndex:(NSInteger)index {
    /*
     [_selectedSliceValueSlider setMinimumTrackTintColor:nil];
     [_selectedSliceValueSlider setMaximumTrackTintColor:nil];
     
     // nothing is selected... so turn off the "selected value" controls
     _selectedSliceIndex = -1;
     [_selectedSliceValueSlider setEnabled:NO];
     [_selectedSliceValueSlider setValue:0.0];
     [_selectedSliceValueLabel setAlpha:0.0];
     
     [self updateSelectedSliceValue:_selectedSliceValueSlider];
     */
}


- (void)setupSegmentedControl {
    UIImage *backgroundImage = [[UIImage imageNamed:@"segmented-bg.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0)];
    [self.participantSelector setBackgroundImage:backgroundImage];
    [self.participantSelector setContentEdgeInsets:UIEdgeInsetsMake(2.0, 2.0, 3.0, 2.0)];
    //[self.participantSelector setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    [self.participantSelector setSeparatorImage:[UIImage imageNamed:@"segmented-separator.png"]];
    
    UIImage *buttonBackgroundImagePressedLeft = [[UIImage imageNamed:@"segmented-bg-pressed-left.png"]
                                                 resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 4.0, 0.0, 1.0)];
    UIImage *buttonBackgroundImagePressedCenter = [[UIImage imageNamed:@"segmented-bg-pressed-center.png"]
                                                   resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 4.0, 0.0, 1.0)];
    UIImage *buttonBackgroundImagePressedRight = [[UIImage imageNamed:@"segmented-bg-pressed-right.png"]
                                                  resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 1.0, 0.0, 4.0)];
    //
    //    // Button 1
    //    UIButton *buttonSocial = [[UIButton alloc] init];
    //    UIImage *buttonSocialImageNormal = [UIImage imageNamed:@"social-icon.png"];
    //
    //    [buttonSocial setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
    //    [buttonSocial setBackgroundImage:buttonBackgroundImagePressedLeft forState:UIControlStateHighlighted];
    //    [buttonSocial setBackgroundImage:buttonBackgroundImagePressedLeft forState:UIControlStateSelected];
    //    [buttonSocial setBackgroundImage:buttonBackgroundImagePressedLeft forState:(UIControlStateHighlighted|UIControlStateSelected)];
    //    [buttonSocial setImage:buttonSocialImageNormal forState:UIControlStateNormal];
    //    [buttonSocial setImage:buttonSocialImageNormal forState:UIControlStateSelected];
    //    [buttonSocial setImage:buttonSocialImageNormal forState:UIControlStateHighlighted];
    //    [buttonSocial setImage:buttonSocialImageNormal forState:(UIControlStateHighlighted|UIControlStateSelected)];
    
    NSMutableArray *buttonsArray = [[NSMutableArray alloc] initWithCapacity:numberOfParticipants];
    // Dynamically create buttons for segemented control
    for (NSUInteger i=0; i < numberOfParticipants; i++) {
        UIButton *userButton = [[UIButton alloc] init];
        NSString *buttonName = @"";
        if ([participants[i] isEqualToNumber:@(MySensorID)]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            buttonName = [defaults objectForKey:@"publicUserName"];
        }
        else {
            Participant *participant = [Participant findFirstByAttribute:@"sensorid" withValue:participants[i]];
            buttonName = participant.name;
        }
        //NSString *buttonName = [NSString stringWithFormat:@"Sensor %@", participants[i]];
        //        UIColor *colorWithApha = [[self.availableSliceColors objectAtIndex:i] colorWithAlphaComponent:0.6];
        //        UIColor *color = [self.availableSliceColors objectAtIndex:i];
        //        [userButton setBackgroundImage:[self imageFromColor:colorWithApha] forState:UIControlStateNormal];
        //        [userButton setBackgroundImage:[self imageFromColor:color] forState:UIControlStateHighlighted];
        //        [userButton setBackgroundImage:[self imageFromColor:color] forState:UIControlStateSelected];
        //        [userButton setBackgroundImage:[self imageFromColor:color] forState:(UIControlStateHighlighted|UIControlStateSelected)];
        //        [userButton setTitleColor:[self.availableSliceColors objectAtIndex:i] forState:UIControlStateHighlighted];
        //        [userButton setTitleColor:[self.availableSliceColors objectAtIndex:i] forState:UIControlStateNormal];
        //        [userButton setTitleColor:[self.availableSliceColors objectAtIndex:i] forState:UIControlStateSelected];
        
        if (i==0) {
            [userButton setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
            [userButton setBackgroundImage:buttonBackgroundImagePressedLeft forState:UIControlStateHighlighted];
            [userButton setBackgroundImage:buttonBackgroundImagePressedLeft forState:UIControlStateSelected];
            [userButton setBackgroundImage:buttonBackgroundImagePressedLeft forState:(UIControlStateHighlighted|UIControlStateSelected)];
        }
        else if (i==numberOfParticipants-1) {
            [userButton setBackgroundImage:buttonBackgroundImagePressedRight forState:UIControlStateHighlighted];
            [userButton setBackgroundImage:buttonBackgroundImagePressedRight forState:UIControlStateSelected];
            [userButton setBackgroundImage:buttonBackgroundImagePressedRight forState:(UIControlStateHighlighted|UIControlStateSelected)];
        }
        else {
            [userButton setBackgroundImage:buttonBackgroundImagePressedCenter forState:UIControlStateHighlighted];
            [userButton setBackgroundImage:buttonBackgroundImagePressedCenter forState:UIControlStateSelected];
            [userButton setBackgroundImage:buttonBackgroundImagePressedCenter forState:(UIControlStateHighlighted|UIControlStateSelected)];
        }
        
        DLog(@"[self.availableSliceColors objectAtIndex:i]: %@", [self.availableSliceColors objectAtIndex:i]);
        [userButton setImageEdgeInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 5.0)];
        [userButton setTitle:buttonName forState:UIControlStateNormal];
        [userButton setTitleColor:[self.availableSliceColors objectAtIndex:i] forState:UIControlStateNormal];
        [userButton setTitleShadowColor:[UIColor grayColor] forState:UIControlStateNormal];
        [userButton.titleLabel setShadowOffset:CGSizeMake(0.0, 1.0)];
        [userButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0]];
        [userButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 0.0)];
        userButton.layer.cornerRadius = 4; // this value vary as per your desire
        userButton.clipsToBounds = YES;
        buttonsArray[i] = userButton;
    }
    
    
    [self.participantSelector setButtonsArray:buttonsArray];
    [self.mainScrollView addSubview:self.participantSelector];
    
    DLog(@"self.participantSelector: %@", self.participantSelector);
    DLog(@"self.participantSelector: %@", self.mainScrollView.subviews);
}

#pragma mark - AKSegmentedControl callbacks

- (void)segmentedViewController:(id)sender
{
    AKSegmentedControl *segmentedControl = (AKSegmentedControl *)sender;
    NSIndexSet *indexSet = [segmentedControl selectedIndexes];
    if (segmentedControl == self.participantSelector) {
        self.selectedParticipantId = [participants[indexSet.firstIndex] integerValue];
        [self.sliceDetailsView reloadPieChartForNewParticipant:[participants[indexSet.firstIndex] integerValue]]; // sending sensor-id/user-id ?
        DLog(@"SegmentedControl #1 : Selected Index %@, selectedIndex: %i", [segmentedControl selectedIndexes], indexSet.firstIndex);
    }
}

//h3lp method, creates image from color
- (UIImage *) imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    //  [[UIColor colorWithRed:222./255 green:227./255 blue: 229./255 alpha:1] CGColor]) ;
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //    CALayer *imageLayer = [CALayer layer];
    //    imageLayer.frame = CGRectMake(0, 0, img.size.width, img.size.height);
    //    imageLayer.contents = (id) img.CGImage;
    //
    //    imageLayer.masksToBounds = YES;
    //    imageLayer.cornerRadius = 5.0;
    //    
    //    UIGraphicsBeginImageContext(img.size);
    //    [imageLayer renderInContext:UIGraphicsGetCurrentContext()];
    //    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    //    UIGraphicsEndImageContext();
    
    return img;
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

- (void)showProfileAfterUserLoggedIn {
    //DLog(@"!!!!! 1 calling showProfileAfterUserLoggedIn !!!!!!!!!!");
    //[navigationBarItems addObject:self.profileBarButtonItem];
    DLog(@"FirstDetail: user logged in: adding profileBarButtonItem: %@", self.profileBarButtonItem);
    [self.navigationBar.topItem setRightBarButtonItem:self.profileBarButtonItem animated:YES];
}

- (void)hideProfileAfterUserLoggedOff {
    if (self.profilePopover)
        [self.profilePopover dismissPopoverAnimated:YES];
    //[navigationBarItems removeObject:self.profileBarButtonItem];
    //DLog(@"FirstDetail: user logged off: removing profileBarButtonItem: %@", self.profileBarButtonItem);
    [self.navigationBar.topItem setRightBarButtonItem:nil animated:YES];
    //DLog(@"FirstDetail: user logged off: after removing profileBarButtonItem, navigationBarItems: %@", navigationBarItems);
}

@end
