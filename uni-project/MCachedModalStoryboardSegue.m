/** 
 \addtogroup Marshmallows
 \author     Created by Hari Karam Singh on 22/11/2012.
 \copyright  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
 @{
 */

/**
 * modified by Pavel Ermolin
 */


#import "MCachedModalStoryboardSegue.h"
#import "DetailViewManager.h"
#import "EcoMeterAppDelegate.h"
#import "PublicDetailViewController.h"
#import "PublicScoreTVC.h"

/////////////////////////////////////////////////////////////////////////
#pragma mark - Statics
/////////////////////////////////////////////////////////////////////////

static NSMutableDictionary * _MCachedModalStoryboardSegueCache;
static NSMutableDictionary * _Cached_PublicDetailViews;


/////////////////////////////////////////////////////////////////////////
#pragma mark - Private Class - _MCachedSegueKey
/////////////////////////////////////////////////////////////////////////

@interface _MCachedSegueKey : NSObject <NSCopying>
{
    Class _vcClass;
    NSString *_identifier;
}
+ (id)keyWithIdentifier:(NSString *)anId viewController:(UIViewController *)aVC;
@end

@implementation _MCachedSegueKey

+ (id)keyWithIdentifier:(NSString *)anId viewController:(UIViewController *)aVC
{
    _MCachedSegueKey *me = [[self alloc] init];
    me->_vcClass = aVC.class;
    me->_identifier = [anId copy];
    return me;
}

- (BOOL)isEqual:(id)object
{
    _MCachedSegueKey *obj = (_MCachedSegueKey *)object;
    BOOL e = ([obj->_identifier isEqualToString:self->_identifier] &&
            obj->_vcClass == self->_vcClass);
    return e;
}

- (NSUInteger)hash
{
    NSUInteger hash = 0;
    hash = ((NSUInteger)_vcClass * 0x1f1f1f1f) ^ _identifier.hash;
    return hash;
}

- (id)copyWithZone:(NSZone *)zone
{
    _MCachedSegueKey *copy = [_MCachedSegueKey new];
    copy->_identifier = [_identifier copy];
    copy->_vcClass = _vcClass;
    return copy;
}

@end




/////////////////////////////////////////////////////////////////////////
#pragma mark - MCachedModalStoryboardSegue
/////////////////////////////////////////////////////////////////////////

@implementation MCachedModalStoryboardSegue

/////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods
/////////////////////////////////////////////////////////////////////////

+ (void)drainCache
{
    _MCachedModalStoryboardSegueCache = nil;
    _Cached_PublicDetailViews = nil;
}


/////////////////////////////////////////////////////////////////////////
#pragma mark - Overrides
/////////////////////////////////////////////////////////////////////////


- (id)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination
{
    NSLog(@"<MCachedModalStoryboardSegue> start identifier= %@, destination=%@, source=%@", identifier, destination, source);
    UIViewController *newDest;
    // Alloc the static dict if required
    if (!_MCachedModalStoryboardSegueCache) {
        _MCachedModalStoryboardSegueCache = [NSMutableDictionary dictionary];
    }
    if (!_Cached_PublicDetailViews) {
        _Cached_PublicDetailViews = [NSMutableDictionary dictionary];
    }
    _destinationWasCached = YES;
    if ([destination isKindOfClass:[PublicDetailViewController class]]) {
        PublicScoreTVC *Newsource = (PublicScoreTVC *)source;
        if (![[_Cached_PublicDetailViews allKeys] containsObject:Newsource.selectedParticipantId]) {
            NSLog(@"<MCachedModalStoryboardSegue> adding destination: %@", destination);
            [_Cached_PublicDetailViews setObject:destination forKey:Newsource.selectedParticipantId];
            _destinationWasCached = NO;
        }
        newDest = [_Cached_PublicDetailViews objectForKey:Newsource.selectedParticipantId];
        NSLog(@"<MCachedModalStoryboardSegue> return newDest: %@", newDest);
        NSLog(@"<MCachedModalStoryboardSegue> _Cached_PublicDetailViews: %@", _Cached_PublicDetailViews);
    }
    else {
        
        // Add it to the cache if doesn't exist...
        _MCachedSegueKey *key = [_MCachedSegueKey keyWithIdentifier:identifier viewController:destination];
        
        //_Cached_PublicDetailViews = nil;
        
        _destinationWasCached = YES;
        if (!([_MCachedModalStoryboardSegueCache.allKeys containsObject:key])) {
            _MCachedModalStoryboardSegueCache[key] = destination;
            _destinationWasCached = NO;
        }
        
        // Swizzle for the cached destination
        newDest = _MCachedModalStoryboardSegueCache[key];
        
    }
    
    return [super initWithIdentifier:identifier source:source destination:newDest];
    
}

/////////////////////////////////////////////////////////////////////////

- (void)perform
{

    EcoMeterAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    DetailViewManager *detailViewManager = appDelegate.detailViewManager;
    // some kind of a custom replace segue with detail split as destination ;)
    //if (![detailViewManager.detailViewController isEqual:self.destinationViewController]) {
    detailViewManager.detailViewController = self.destinationViewController;
    NSLog(@"<MCachedModalStoryboardSegue> custom segue, destinationViewController: %@", self.destinationViewController);
    NSLog(@"<MCachedModalStoryboardSegue> detailViewManager.detailViewController.view.subviews: %@", detailViewManager.detailViewController.view.subviews);
    NSLog(@"<MCachedModalStoryboardSegue> detailViewManager.detailViewController.view: %@", detailViewManager.detailViewController.view);
    //}

}

@end

/// @}