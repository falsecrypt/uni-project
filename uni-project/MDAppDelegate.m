//
//  MDAppDelegate.m
//  MultipleMasterDetailViews

#import "MDAppDelegate.h"
#import "DetailViewManager.h"
#import "KeychainItemWrapper.h"

@interface MDAppDelegate()
@property (weak,nonatomic)UISplitViewController* splitViewController;
@end

@implementation MDAppDelegate
//!!! @synthesize command is generated by default when using properties, yeahh ;-)
//@synthesize window, detailViewManager, splitViewController;

//@synthesize masterDetailManager = __masterDetailManager;


// -------------------------------------------------------------------------------
//	applicationDidFinishLaunching:application
// -------------------------------------------------------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
	// Initialize the app window
    /*
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
     */
    
    [self customizeAppearance];
    
    //--------------------------------------------------------------------
    // MagicalRecord Setup - creating the NSPersistentStoreCoordinator,
    // the NSManagedObjectModel and the NSManagedObjectContext. We are using
    // the active record pattern.
    //--------------------------------------------------------------------
    [MagicalRecord setupCoreDataStackWithStoreNamed:@"ecoMeterDB.sqlite"];
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    self.splitViewController = splitViewController;
    
    // The new popover look for split views was added in iOS 5.1.
    // This checks if the setting to enable it is available and
    // sets it to YES if so.
    if ([self.splitViewController respondsToSelector:@selector(setPresentsWithGesture:)])
        [self.splitViewController setPresentsWithGesture:YES];
    
    self.detailViewManager = [[DetailViewManager alloc] initWithSplitViewController:splitViewController];
    NSLog(@"calling didFinishLaunchingWithOptions, detailViewManager: %@", self.detailViewManager);
    self.splitViewController.delegate = self.detailViewManager;
    

    // Log off user
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"userLoggedIn"];
    NSLog(@"calling didFinishLaunchingWithOptions, userLoggedIn: %i", [defaults boolForKey:@"userLoggedIn"]);
     */

    
    
    // -------------------------------------------------------------------------------
    //	old code
    // -------------------------------------------------------------------------------
    //UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    //UIViewController* detail1 = [splitViewController.viewControllers objectAtIndex:1];
    //UIViewController* default1 = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"Detail_1"];
    //UIViewController* pieChartRootController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"pieChartRootController"];
    //UIViewController* barGraphRootController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"barGraphRootController"];
    //UIViewController* scatterPlotRootController = [splitViewController.storyboard instantiateViewControllerWithIdentifier:@"scatterPlotRootController"];
    //UITabBarController* tabBarController = [splitViewController.viewControllers objectAtIndex:0];
    //UITabBar* tabBar = tabBarController.tabBar;
    //UIImage* tabBarBackground = [UIImage imageNamed:@"tabbar_back_opt.jpg"];
    //tabBar.backgroundImage = tabBarBackground;
    //self.masterDetailManager = [[MDMultipleMasterDetailManager alloc] initWithSplitViewController:splitViewController
                               // withDetailRootControllers:[NSArray arrayWithObjects:detail1,default1,
                                                       //    pieChartRootController,barGraphRootController,scatterPlotRootController,nil]];
    
     
    return YES;
}

// using new appearance proxy (since iOS 5)
- (void)customizeAppearance
{
    // Create resizable images
    UIImage *gradientImage44 = [[UIImage imageNamed:@"navBarBg.png"]
                                resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    //UIImage *gradientImage32 = [[UIImage imageNamed:@"surf_gradient_textured_32"]
                                //resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    
    // Set the background image for *all* UINavigationBars
    [[UINavigationBar appearance] setBackgroundImage:gradientImage44
                                       forBarMetrics:UIBarMetricsDefault];
    //[[UINavigationBar appearance] setBackgroundImage:gradientImage32
                                       //forBarMetrics:UIBarMetricsLandscapePhone];
    
    // Customize the title text for *all* UINavigationBars
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:155/255.0f green:155/255.0f blue:155/255.0f alpha:1.0f], UITextAttributeTextColor,
                                                           [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6],UITextAttributeTextShadowColor,
                                                           [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],
                                                           UITextAttributeTextShadowOffset,
                                                           [UIFont fontWithName:@"QuicksandBold-Regular" size:21.0], UITextAttributeFont, nil]];
    
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
    [MagicalRecord cleanUp];

}

@end
