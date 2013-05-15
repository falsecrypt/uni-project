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
            NSLog(@"Uncaught exception: %@", exception.name);
            NSLog(@"reason: %@", exception.reason);
            NSLog(@"userInfo: %@", exception.userInfo);
            NSLog(@"Stack trace: %@", [exception callStackSymbols]);
            @throw exception; //forward exception
        }
    }
}
