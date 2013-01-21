//
//  MDMultipleMasterDetailManager.m
//  MultipleMasterDetailViews
//
//  Created by Todd Bates on 11/14/11.
//  Copyright (c) 2011 Science At Hand LLC. All rights reserved.
//

#import "MDMultipleMasterDetailManager.h"
#import "MDDetailViewController.h"

@interface MDMultipleMasterDetailManager()
@property (weak,nonatomic)UISplitViewController* splitViewController;
@property (strong,nonatomic)NSArray* detailControllers;
@property (weak,nonatomic)UIViewController* currentDetailController;

// management of the UISplitViewController button and popover
@property (strong,nonatomic) UIBarButtonItem* masterBarButtonItem;
@property (strong,nonatomic) UIPopoverController* masterPopoverController;

@end

@implementation MDMultipleMasterDetailManager

@synthesize splitViewController = __splitViewController;
@synthesize detailControllers = __detailControllers;
@synthesize masterBarButtonItem = __masterBarButtonItem;
@synthesize masterPopoverController = __masterPopoverController;
@synthesize currentDetailController = __currentDetailController;

-(id)initWithSplitViewController:(UISplitViewController*)splitViewController withDetailRootControllers:(NSArray*)detailControllers
{
    self = [super init];
    if(self){
        __splitViewController = splitViewController;
        __detailControllers = [detailControllers copy];
        UINavigationController* detailRoot = (splitViewController.viewControllers)[1];
        __currentDetailController = detailRoot.topViewController;
        
        splitViewController.delegate = self;
        UITabBarController* tabBar = (splitViewController.viewControllers)[0];
        tabBar.delegate = self;
    }
    
    return self;
}

#pragma mark - UISplitViewControllerDelegate

/* forward the message to the current detail view
 * all detail views must implement UISplitViewControllerDelegate
 */
-(void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    self.masterBarButtonItem = barButtonItem;
    self.masterPopoverController = pc;
    
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    
    [self.currentDetailController.navigationItem setLeftBarButtonItem:self.masterBarButtonItem animated:YES];
}

/* forward the message to the current detail view
 * all detail views must implement UISplitViewControllerDelegate
 */
-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.masterBarButtonItem = nil;
    self.masterPopoverController = nil;
    
    [self.currentDetailController.navigationItem setLeftBarButtonItem:nil animated:YES];
    
}

#pragma mark - UITabBarControllerDelegate

// change detail view to reflect the current master controller
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    NSLog(@"Manager,self.detailControllers: %@", self.detailControllers);
    
    UINavigationController* detailRootController;
    if(tabBarController.selectedIndex == 1){
        detailRootController = (self.detailControllers)[tabBarController.selectedIndex + 1];
    }
    else {
        detailRootController = (self.detailControllers)[tabBarController.selectedIndex];
    }
    
    UIViewController* detailControler = detailRootController.topViewController;
    NSLog(@"Manager,detailRootController: %@", detailRootController);
    NSLog(@"Manager,detailControler: %@", detailControler);
    NSLog(@"Manager,tabBarController.selectedIndex: %i", tabBarController.selectedIndex);
    if(detailControler != self.currentDetailController)
    {
        // swap button in detail controller
        [self.currentDetailController.navigationItem setLeftBarButtonItem:nil animated:NO];
        self.currentDetailController = detailControler;
        [self.currentDetailController.navigationItem setLeftBarButtonItem:self.masterBarButtonItem animated:NO];
        
        // update controllers in splitview
        UIViewController* tabBarController = (self.splitViewController.viewControllers)[0];
        self.splitViewController.viewControllers = @[tabBarController,detailRootController];
        
        // replace the passthrough views with current detail navigationbar
        if([self.masterPopoverController isPopoverVisible]){
            self.masterPopoverController.passthroughViews = @[detailRootController.navigationBar];
        }
    }
    if(tabBarController.selectedIndex == 1){
        [(MDDetailViewController *)detailControler setDetailItem:@"Pie Chart"];
    }
    NSLog(@"Manager,self.splitViewController.viewControllers: %@", self.splitViewController.viewControllers); 
}

@end
