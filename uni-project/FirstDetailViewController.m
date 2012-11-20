//
//  FirstDetailViewController.m
//  uni-project

//  Copyright (c) 2012 test. All rights reserved.
//

#import "FirstDetailViewController.h"
#import "ProfilePopoverViewController.h"

@interface FirstDetailViewController ()
- (void)showProfileAfterUserLoggedIn;
@end

@implementation FirstDetailViewController

NSMutableArray *navigationBarItems;


#pragma mark -
#pragma mark SubstitutableDetailViewController

// -------------------------------------------------------------------------------
//	setNavigationPaneBarButtonItem:
//  Custom implementation for the navigationPaneBarButtonItem setter.
//  In addition to updating the _navigationPaneBarButtonItem ivar, it
//  reconfigures the toolbar to either show or hide the
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
    if (navigationBarItems == nil) {
        navigationBarItems = [self.navigationBar.topItem.rightBarButtonItems mutableCopy];
    }
    
    // -setNavigationPaneBarButtonItem may have been invoked when before the
    // interface was loaded.  This will occur when setNavigationPaneBarButtonItem
    // is called as part of DetailViewManager preparing this view controller
    // for presentation as this is before the view is unarchived from the NIB.
    // When viewidLoad is invoked, the interface is loaded and hooked up.
    // Check if we are supposed to be displaying a navigationPaneBarButtonItem
    // and if so, add it to the toolbar.
    if (self.navigationPaneBarButtonItem) {
        [self.navigationBar.topItem setLeftBarButtonItem:self.navigationPaneBarButtonItem
                                                animated:NO];
    }
    
    // we use notification center for broadcasting information
    // Register to Receive a Notification
    NSString *notificationName = @"UserLoggedInNotification";
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(showProfileAfterUserLoggedIn)
     name:notificationName
     object:nil];
}

// -------------------------------------------------------------------------------
//	viewWillAppear:
// -------------------------------------------------------------------------------
- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"calling FirstDetailViewController - viewWillAppear start");
    [super viewWillAppear:animated];
    // NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    self.navigationBar.topItem.title = @"Summary";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"userLoggedIn"]) {
        [navigationBarItems removeObject:self.profileBarButtonItem];
        [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:NO];
    }
    
    
    //NSLog(@"calling FirstDetailViewController - viewWillAppear: rightBarButtonItems %@", self.navigationBar.topItem.rightBarButtonItems);
    
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
    //NSLog(@"!!!!! 1 calling showProfileAfterUserLoggedIn !!!!!!!!!!");
    [navigationBarItems addObject:self.profileBarButtonItem];
    [self.navigationBar.topItem setRightBarButtonItems:navigationBarItems animated:YES];
}
@end
