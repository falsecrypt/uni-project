//
//  WeatherApiCommManager.h
//  uni-project
//
//  Created by Pavel Ermolin on 28.04.13.
//  Copyright (c) 2013 test. All rights reserved.
//

#import "AFHTTPClient.h"

@interface WeatherApiCommManager : AFHTTPClient

+ (WeatherApiCommManager *)sharedClient;

@end
