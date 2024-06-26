//
//  MessageSenderOC.m
//  StewieMessenger
//
//  Created by jiska on 18.05.24.
//

#import <Foundation/Foundation.h>
#import "SPSecureLocationsManager.h"
#import "MessageSenderOC.h"
#include <dlfcn.h>


@class SPSecureLocationsManager;
@class SPSecureLocationsStewiePublishResult;

@implementation MessageSenderOC

void* SPOwnerHandle;
Class SPSecureLocationsManagerClass;
SPSecureLocationsManager* splm;
int publishError;  // errors starting at 10

// using framework to trigger sending message
// requires entitlement `com.apple.icloud.searchpartyd.securelocations.access`
-(id)init {
    self = [super init];
    
    SPOwnerHandle = dlopen("/System/Library/PrivateFrameworks/SPOwner.framework/SPOwner", RTLD_NOW);
    SPSecureLocationsManagerClass = (__bridge Class)dlsym(SPOwnerHandle, "OBJC_CLASS_$_SPSecureLocationsManager");
    splm = [[SPSecureLocationsManagerClass alloc] init];
    
    return self;
}

-(int)publishMessage {
    
    publishError = 0;
    
    NSLog(@"xxx Loading SPOwner into Obj-C...");
        
    // prints last publish state: <lastPublished 2024-05-18 21:43:00 +0000, nextAllowedPublish 1716069480.147459>
    [splm stewiePublishStateWithCompletion:^(SPSecureLocationsStewiePublishResult* result, NSError* err){NSLog(@"xxx Publish state block %@", result);}];
    
    [splm setStewieRetryCount: 0];  // the tweak deletes the message, don't retry or we sent the location instead
    [splm publishCurrentLocationToStewieWithReason:2 completion:^(SPSecureLocationsStewiePublishResult* result, NSError* err) {
        // on success:        Published location via objc class! result <lastPublished 2024-05-18 23:25:52 +0000, nextAllowedPublish 1716075652.019505>, err (null)
        // on error (<15min): Published location via objc class! result (null), err Error Domain=com.apple.findmy.SPSecureLocations.StewieErrorDomain Code=5 "(null)"
        NSLog(@"xxx Published location via objc class! result %@, err %@", result, err);
        if ([err code] == 5) {
            publishError = 10;  // throttled
        }
    }];
    
    [splm startMonitoringStewieStateWithBlock:^(){NSLog(@"xxx Completion state block");} completion:^(NSError* err){NSLog(@"xxx Completion monitoring %@", err);}];
    
    return 0;
}

// returns stewie state, unless we got a different publish error
-(int)getState {
    
    // errors start at 10, as stewieState goes up to 6
    if (publishError != 0) {
        return publishError;  // error state
    }
    int state = (int) [splm lastUpdatedStewieState];
    NSLog(@"xxx last updated stewie state: %i", state);
    
    return state;
}


@end



