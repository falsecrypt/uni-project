// AFAppDotNetAPIClient.h


#import <Foundation/Foundation.h>
#import "AFHTTPClient.h"

@interface AFAppDotNetAPIClient : AFHTTPClient

+ (AFAppDotNetAPIClient *)sharedClient;

@end
