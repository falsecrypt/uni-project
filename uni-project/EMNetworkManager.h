// AFAppDotNetAPIClient.h


#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@interface EMNetworkManager : AFHTTPClient

+ (EMNetworkManager *)sharedClient;

@end
