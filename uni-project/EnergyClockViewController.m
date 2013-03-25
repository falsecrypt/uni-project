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

static const int numberPages    = 2;
static const int numberSlices   = 12; // 12 time intervalls, 00:00-02:00-...
static const int numberOfParticipants = 3; // ask the server for this number


@interface EnergyClockViewController ()<UIScrollViewDelegate, BTSPieViewDataSource, BTSPieViewDelegate>

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (weak, nonatomic) IBOutlet BTSPieView *energyClockView;
@property (nonatomic, strong) NSMutableArray *sliceValues;
@property (nonatomic, strong) NSMutableArray *slotValuesForSlice;
@property (nonatomic, strong) NSArray *availableSliceColors;
@property (nonatomic, assign) NSInteger selectedSliceIndex;
@property (nonatomic, assign) CGFloat energyClockViewRadius;
@property (nonatomic, strong) NSDate *currentDate;

@end

@implementation EnergyClockViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        NSLog(@"EnergyClockViewController-initWithNibName");
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    // OK we're done, lets reload the energyclock
    //[self.energyClockView reloadData];

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // a page is the width of the scroll view
    self.scrollView.contentSize =
    CGSizeMake(CGRectGetWidth(self.scrollView.frame) * numberPages, CGRectGetHeight(self.scrollView.frame));

    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
    
    CGRect parentLayerBounds = [self.energyClockView bounds];
    CGFloat centerX = parentLayerBounds.size.width / 2.0f;
    CGFloat centerY = parentLayerBounds.size.height / 2.0f;
    
    // Reduce the radius just a bit so the the pie chart layers do not hug the edge of the view.
    self.energyClockViewRadius = MIN(centerX, centerY) - 10;
    
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
    [self.energyClockView reloadData];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(initEnergyClockAfterSavingData) // when the data has been saved we will be notified
     name:AggregatedDaysSaved
     object:nil];
    
    [[EnergyClockDataManager sharedClient] calculateValuesWithMode:DayChartsMode];

    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    for (NSUInteger i = 0; i < numberPages; i++)
    {
		[controllers addObject:[NSNull null]];
    }
    self.viewControllers = controllers;
    
    self.scrollView.delegate = self;
    self.pageControl.numberOfPages = numberPages;
    self.pageControl.currentPage = 0;
    
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
    
    // set up the data source and delegate
    [self.energyClockView setDataSource:self];
    [self.energyClockView setDelegate:self];
    self.selectedSliceIndex = -1;
    //float animationDuration = 1.0f;
    //[self.energyClockView setAnimationDuration:animationDuration];
    
    //[self.energyClockView reloadData];
    [self checkSyncStatus];
    
    NSLog(@"viewDidLoad-after checkSyncStatus, self.sliceValues: %@", self.sliceValues);
    NSLog(@"viewDidLoad-after checkSyncStatus, self.slotValuesForSlice: %@", self.slotValuesForSlice);

}

// should we display the energyclock of the last date immediately
// or should we wait to the 'AggregatedDaysSaved'-Notification?
-(void)checkSyncStatus
{
    /* Get last sync date, ==today? -> then do nothing! */
    NSDateComponents *todayComponents =
    [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    System *systemObj = [System findFirstByAttribute:@"identifier" withValue:@"primary"];
    NSAssert(systemObj!=nil, @"System Object with id=primary doesnt exist");
    NSLog(@"checkSyncStatus systemObj: %@", systemObj);
    NSDate *lastSyncDate = systemObj.daysupdated;
    NSLog(@"checkSyncStatus lastSyncDate: %@", lastSyncDate);
    NSLog(@"checkSyncStatus todayComponents: %@", todayComponents);
    
    if (lastSyncDate && !FORCEDAYCHARTSUPDATE)
    { // we have synced today already
        NSDateComponents *lastSyncComponents =
        [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:lastSyncDate];
        
        if(([todayComponents year]  == [lastSyncComponents year])  &&
           ([todayComponents month] == [lastSyncComponents month]) &&
           ([todayComponents day]   == [lastSyncComponents day]))
        {
            NSLog(@"checkSyncStatus, we synced already");
            EnergyClockSlice *slice = [EnergyClockSlice findFirstOrderedByAttribute:@"date" ascending:NO];
            [self initValuesForNewDate:slice.date];
            self.currentDate = slice.date;
        }
    }
}

-(void)initEnergyClockAfterSavingData
{
    EnergyClockSlice *slice = [EnergyClockSlice findFirstOrderedByAttribute:@"date" ascending:NO];
    [self initValuesForNewDate:slice.date];
    // OK we're done, lets reload the energyclock
    [self.energyClockView reloadData];
}

-(NSMutableArray*)sliceValues
{
    if(!_sliceValues)
    {
        _sliceValues = [[NSMutableArray alloc]initWithCapacity:numberSlices];
        // TEST
        /*for (int i=0; i<numberSlices; i++) {
            [_sliceValues insertObject:[NSNumber numberWithFloat:i+0.53] atIndex:i];
        }*/
        /*for (int i=0; i<numberSlices; i++) {
            [_sliceValues insertObject:[NSNull null] atIndex:i];
        }*/
    }
    return _sliceValues;
}

-(NSMutableArray*)slotValuesForSlice
{
    if(!_slotValuesForSlice)
    {
        _slotValuesForSlice = [[NSMutableArray alloc]initWithCapacity:numberSlices];
        
        /*for (int i=0; i<numberSlices; i++) {
         NSMutableArray *innerArray = [[NSMutableArray alloc]initWithCapacity:numberOfParticipants];
         // TEST
         for (int i=0; i<numberOfParticipants; i++) {
         [innerArray insertObject:@(arc4random()/21*0.1) atIndex:1];
         }
         [_slotValuesForSlice insertObject:innerArray atIndex:i];
         }*/
        for (int i=0; i<numberSlices; i++) {
            [_slotValuesForSlice insertObject:[NSNull null] atIndex:i];
        }
    }
    return _slotValuesForSlice;
}

// random values
-(NSMutableArray*)radiusValuesForSlice
{
    if(!_radiusValuesForSlice)
    {
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
    NSLog(@"loadScrollViewWithPage...");
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
        NSLog(@"<EnergyClockViewController> controller.view: %@", controller.view);
        NSLog(@"<EnergyClockViewController> controller.view.subviews: %@", controller.view.subviews);
        
        /*
        NSDictionary *numberItem = [self.contentList objectAtIndex:page];
        controller.numberImage.image = [UIImage imageNamed:[numberItem valueForKey:kImageKey]];
        controller.numberTitle.text = [numberItem valueForKey:kNameKey];
         */
    }
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"<EnergyClockViewController> scrollViewWillBeginDecelerating...");

}

// at the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSLog(@"<EnergyClockViewController> scrollViewDidEndDecelerating...");
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
    
    // a possible optimization would be to unload the views+controllers which are no longer visible
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Load the pages which are now on screen
    NSLog(@"<EnergyClockViewController> scrollViewDidScroll...");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// this method is called after the user touched one of the day charts
-(void)loadEnergyClockForDate:(NSDate *)date
{
    if ([self.currentDate isEqualToDate:date]) {
        NSLog(@"<EnergyClockViewController> -loadEnergyClockForWeekDay, plot with date: %@ touched, same date as the current -> returning..", date);
        return;
    }
    NSLog(@"<EnergyClockViewController> -loadEnergyClockForWeekDay, plot with date: %@ touched", date);

    [self initValuesForNewDate:date];
    self.currentDate = date;
    [self.energyClockView reloadData];
}

-(void)initValuesForNewDate:(NSDate *)date
{
    // check if data exists @todo
    NSArray *slicesData = [EnergyClockSlice findByAttribute:@"date" withValue:date andOrderBy:@"hour" ascending:YES];
    NSMutableArray *slotValuesForSliceTemp = [[NSMutableArray alloc] init];
    NSMutableArray *sliceValuesTemp = [[NSMutableArray alloc] init];
    // DEBUGGING
    for (int i=0; i<[slicesData count]; i++) {
        EnergyClockSlice *slice = slicesData[i];
        NSLog(@"date: %@, hour: %@, consumption: %@", slice.date, slice.hour, slice.consumption);
    }
    if ([slicesData count] > 0) {
        
        // there must be exactly 12 objects in the slicesData-Array
        for (int insertIndex=0; insertIndex<[slicesData count]; insertIndex++) {
            NSMutableArray *innerArray = [[NSMutableArray alloc]initWithCapacity:numberOfParticipants];
            EnergyClockSlice *slice = slicesData[insertIndex];
            NSMutableDictionary *slotValuesDict = [NSKeyedUnarchiver unarchiveObjectWithData:slice.slotValues];
            NSArray *sortedkeys = [[slotValuesDict allKeys]sortedArrayUsingSelector:@selector(compare:)];
            NSLog(@"slotValuesDict: %@", slotValuesDict);
            NSLog(@"sortedkeys: %@", sortedkeys);
            for (int i=0; i<numberOfParticipants; i++) {
                [innerArray insertObject:[slotValuesDict objectForKey:sortedkeys[i]] atIndex:i];
            }
            [slotValuesForSliceTemp insertObject:innerArray atIndex:insertIndex];
            // fill with 12 slice values for that selected date
            [sliceValuesTemp insertObject:((EnergyClockSlice *)slicesData[insertIndex]).consumption atIndex:insertIndex];
        }
        self.sliceValues = sliceValuesTemp;
        self.slotValuesForSlice = slotValuesForSliceTemp;
        
        
    }
}


- (void)gotoPage:(BOOL)animated
{
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

- (IBAction)changePage:(id)sender
{
    NSLog(@"<EnergyClockViewController> changePage...");
    [self gotoPage:YES];    // YES = animate
}

#pragma mark - BTSPieView Data Source

- (NSUInteger)numberOfSlicesInPieView:(BTSPieView *)pieView
{
    NSLog(@"numberOfSlicesInPieView:");
    NSLog(@"sliceValues: %@", self.sliceValues);
    return [self.sliceValues count];
    //return numberSlices;
}

// TODO : new
- (NSUInteger)numberOfSlotsInPieView:(BTSPieView *)pieView
{
    return numberOfParticipants;
}

- (CGFloat)pieView:(BTSPieView *)pieView valueForSliceAtIndex:(NSUInteger)index
{
    NSLog(@"valueForSliceAtIndex, returning: %f", (CGFloat)[[self.sliceValues objectAtIndex:index]floatValue]);
    
    return (CGFloat)[[self.sliceValues objectAtIndex:index]floatValue];
    
    //return 10;
    
    //return (arc4random()%80)+ 10;
    
    /*int result = 0;
    
    // night values
    if (index >= 9 || index <= 3) {
        result = (arc4random() % (10))+5;
        NSLog(@"pieView:valueForSliceAtIndex: 'night' - index: %i, result: %i", index, result);
    }
    // day values
    else {
        result = (arc4random() % (40))+40;
        NSLog(@"pieView:valueForSliceAtIndex: 'day'- index: %i, result: %i", index, result);
    }
    //return index * 10 + 10;
    return result; */
}

// TODO : new
- (CGFloat)pieView:(BTSPieView *)pieView valueForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex
{
    return (CGFloat)[[[self.slotValuesForSlice objectAtIndex:sliceIndex] objectAtIndex:slotIndex] floatValue];

}
// do i need this method?
- (CGFloat)pieView:(BTSPieView *)pieView radiusForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex
{
    return (CGFloat)[[[self.radiusValuesForSlice objectAtIndex:sliceIndex] objectAtIndex:slotIndex] floatValue];
}

- (NSArray *)getRadiusArray
{
    return self.radiusValuesForSlice;
}

- (NSArray *)getSlotValuesForSliceArray
{
    return self.slotValuesForSlice;
}
/* DEPRECATED
- (UIColor *)pieView:(BTSPieView *)pieView colorForSliceAtIndex:(NSUInteger)index sliceCount:(NSUInteger)sliceCount
{
    return [(BTSSliceData *)[_slices objectAtIndex:index] color];
}
 */

// TODO : new
- (UIColor *)pieView:(BTSPieView *)pieView colorForSlotAtIndex:(NSUInteger)slotIndex sliceAtIndex:(NSUInteger)sliceIndex sliceCount:(NSUInteger)sliceCount
{
    return [self.availableSliceColors objectAtIndex:slotIndex];
}

#pragma mark - BTSPieView Delegate

- (void)pieView:(BTSPieView *)pieView willSelectSliceAtIndex:(NSInteger)index
{
}

- (void)pieView:(BTSPieView *)pieView didSelectSliceAtIndex:(NSInteger)index
{
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
}

- (void)pieView:(BTSPieView *)pieView willDeselectSliceAtIndex:(NSInteger)index
{
}

- (void)pieView:(BTSPieView *)pieView didDeselectSliceAtIndex:(NSInteger)index
{
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


@end
