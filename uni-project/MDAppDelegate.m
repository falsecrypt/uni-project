//
//  MDAppDelegate.m
//  MultipleMasterDetailViews
//
//  Created by Todd Bates on 11/14/11.
//  Copyright (c) 2011 Science At Hand LLC. All rights reserved.
//

#import "MDAppDelegate.h"
#import "MDMultipleMasterDetailManager.h"

@interface MDAppDelegate()
@property (strong,nonatomic)MDMultipleMasterDetailManager* masterDetailManager;
@end

@implementation MDAppDelegate

@synthesize window = _window;
@synthesize masterDetailManager = __masterDetailManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;

    UIViewController* detail1 = [splitViewController.viewControllers objectAtIndex:1];
    UIViewController* default1 = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"Detail_1"];
    UIViewController* pieChartRootController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"pieChartRootController"];
    UIViewController* barGraphRootController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"barGraphRootController"];
    UIViewController* scatterPlotRootController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"scatterPlotRootController"];
    UITabBarController* tabBarController = [splitViewController.viewControllers objectAtIndex:0];
    UITabBar* tabBar = tabBarController.tabBar;
    UIImage* tabBarBackground = [UIImage imageNamed:@"tabbar_back_opt.jpg"];
    tabBar.backgroundImage = tabBarBackground;
    
    self.masterDetailManager = [[MDMultipleMasterDetailManager alloc] initWithSplitViewController:splitViewController
                                withDetailRootControllers:[NSArray arrayWithObjects:detail1,default1,
                                                           pieChartRootController,barGraphRootController,scatterPlotRootController,nil]];
    
     
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
