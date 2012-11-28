// AFAppDotNetAPIClient.h

#import "AFAppDotNetAPIClient.h"

#import "AFJSONRequestOperation.h"

static NSString * const currentCostServerBaseURLString =
        @"http://www.hcm-lab.de/downloads/buehling/adaptiveart/CurrentCostTreeOnline/";

@implementation AFAppDotNetAPIClient

+ (AFAppDotNetAPIClient *)sharedClient {
    static AFAppDotNetAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[AFAppDotNetAPIClient alloc] initWithBaseURL:[NSURL URLWithString:currentCostServerBaseURLString]];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"text/plain"];
    
    return self;
}

@end
