//
//  EnergyClockViewController.m
//  uni-project
//
//  Created by Pavel Ermolin on 28.02.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "EnergyClockViewController.h"
#import "ScrollViewContentVC.h"

static const int numberPages    = 2;

@interface EnergyClockViewController ()

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *viewControllers;

@end

@implementation EnergyClockViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated]; 

}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // a page is the width of the scroll view
    self.scrollView.contentSize =
    CGSizeMake(CGRectGetWidth(self.scrollView.frame) * numberPages, CGRectGetHeight(self.scrollView.frame));
    NSLog(@"<EnergyClockViewController> self.scrollView.frame.size.width: %f", self.scrollView.frame.size.width);

    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    //
    [self loadScrollViewWithPage:0];
    [self loadScrollViewWithPage:1];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
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
    
}

- (void)loadScrollViewWithPage:(NSUInteger)page
{
    
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


@end
