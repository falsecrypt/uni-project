//
//  MDAppDelegate.h
//  MultipleMasterDetailViews

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@interface EcoMeterAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;

//@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;

/** This property is assigned as the Split View Controller's delegate, holds strong reference to the DetailViewManager instance
 
 */
@property (nonatomic, strong) DetailViewManager* detailViewManager;

@property (nonatomic, assign) BOOL deviceIsOnline;

@end
