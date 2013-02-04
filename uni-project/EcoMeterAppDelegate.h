//
//  MDAppDelegate.h
//  MultipleMasterDetailViews

#import <UIKit/UIKit.h>
#import "DetailViewManager.h"

@interface EcoMeterAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;

//@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;

// DetailViewManager is assigned as the Split View Controller's delegate.
// strong reference
@property (strong,nonatomic)DetailViewManager* detailViewManager;

@end
