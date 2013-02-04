//
//  main.m

#import <UIKit/UIKit.h>

#import "EcoMeterAppDelegate.h"

CFAbsoluteTime StartTime;

int main(int argc, char *argv[])
{
    StartTime = CFAbsoluteTimeGetCurrent();
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([EcoMeterAppDelegate class]));
    }
}
