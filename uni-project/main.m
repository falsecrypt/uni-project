//
//  main.m

#import <UIKit/UIKit.h>

#import "EcoMeterAppDelegate.h"

CFAbsoluteTime StartTime;

int main(int argc, char *argv[])
{
    StartTime = CFAbsoluteTimeGetCurrent();
    @autoreleasepool {
        
        @try {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([EcoMeterAppDelegate class]));
        }
        @catch (NSException *exception) {
            DLog(@"Uncaught exception: %@", exception.name);
            DLog(@"reason: %@", exception.reason);
            DLog(@"userInfo: %@", exception.userInfo);
            DLog(@"Stack trace: %@", [exception callStackSymbols]);
            @throw exception; //forward exception
        }
    }
}
