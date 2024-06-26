//
//  SPSecureLocationsManager.h
//  StewieMessenger
//
//  Created by jiska on 18.05.24.
//

#ifndef SPSecureLocationsManager_h
#define SPSecureLocationsManager_h

#import <Foundation/Foundation.h>
#import "SPSecureLocationsClientXPCProtocol.h"

@protocol OS_dispatch_queue, SPSecureLocationsXPCProtocol;
@class NSObject, FMXPCServiceDescription, FMXPCSession, NSString;

@interface SPSecureLocationsManager : NSObject <SPSecureLocationsClientXPCProtocol> {

    NSObject* _queue;
    FMXPCServiceDescription* _serviceDescription;
    FMXPCSession* _session;
    id<SPSecureLocationsXPCProtocol> _proxy;
    /*^block*/id _locationUpdates;
    /*^block*/id _clearCacheUpdates;
    /*^block*/id _stewieUpdateBlock;
    long long _lastUpdatedStewieState;
    unsigned long long _stewieRetryCount;
}

- (id)alloc;
- (id)init;
- (void)publishCurrentLocationToStewieWithReason:(int)reason completion:(id /*block*/)handler;

@property (nonatomic,retain) NSObject* queue;                        //@synthesize queue=_queue - In the implementation block
@property (nonatomic,retain) FMXPCServiceDescription * serviceDescription;              //@synthesize serviceDescription=_serviceDescription - In the implementation block
@property (nonatomic,retain) FMXPCSession * session;                                    //@synthesize session=_session - In the implementation block
@property (nonatomic,retain) id<SPSecureLocationsXPCProtocol> proxy;                    //@synthesize proxy=_proxy - In the implementation block
@property (nonatomic,copy) id locationUpdates;                                          //@synthesize locationUpdates=_locationUpdates - In the implementation block
@property (nonatomic,copy) id clearCacheUpdates;                                        //@synthesize clearCacheUpdates=_clearCacheUpdates - In the implementation block
@property (nonatomic,copy) id stewieUpdateBlock;                                        //@synthesize stewieUpdateBlock=_stewieUpdateBlock - In the implementation block
@property (assign,nonatomic) long long lastUpdatedStewieState;                          //@synthesize lastUpdatedStewieState=_lastUpdatedStewieState - In the implementation block
@property (assign,nonatomic) unsigned long long stewieRetryCount;                       //@synthesize stewieRetryCount=_stewieRetryCount - In the implementation block
@property (readonly) NSUInteger hash;
@property (readonly) Class superclass;
@property (copy,readonly) NSString * description;
@property (copy,readonly) NSString * debugDescription;
+(id)remoteInterface;
+(id)exportedInterface;
-(id<SPSecureLocationsXPCProtocol>)proxy;
-(void)setLocationUpdateBlock:(/*^block*/id)arg1 ;
-(void)setProxy:(id<SPSecureLocationsXPCProtocol>)arg1 ;
-(void)setServiceDescription:(FMXPCServiceDescription *)arg1 ;
-(void)interruptionHandler:(id)arg1 ;
-(void)receivedLocationPayload:(id)arg1 completion:(/*^block*/id)arg2 ;
-(void)invalidationHandler:(id)arg1 ;
-(FMXPCServiceDescription *)serviceDescription;
-(void)simulateFeatureDisabled:(BOOL)arg1 completion:(/*^block*/id)arg2 ;
-(void)startMonitoringFailedSubscriptions:(/*^block*/id)arg1 ;
-(void)setSession:(FMXPCSession *)arg1 ;
-(void)clearLocationsForFailedSubscriptions:(id)arg1 ;
-(void)shouldStartLocationMonitorWithCompletion:(/*^block*/id)arg1 ;
-(void)shareCurrentKeyWithId:(id)arg1 completion:(/*^block*/id)arg2 ;

-(void)stopMonitoringStewieStateWithCompletion:(/*^block*/id)arg1 ;
-(long long)lastUpdatedStewieState;
-(double)_decayedWaitIntervalForRetryCount:(unsigned long long)arg1 ;
-(void)setLastUpdatedStewieState:(long long)arg1 ;
-(FMXPCSession *)session;
-(id)locationUpdates;
-(void)stewiePublishStateWithCompletion:(/*^block*/id)arg1 ;
-(void)updateLocationCacheWith:(id)arg1 completion:(/*^block*/id)arg2 ;
-(void)isLocationPublishingDeviceWithCompletion:(/*^block*/id)arg1 ;
-(void)startMonitoringStewieStateWithBlock:(/*^block*/id)arg1 completion:(/*^block*/id)arg2 ;
//-(void)triggerStewieProactiveNotification;  // not on iOS 16.2
-(void)unsubscribeForIds:(id)arg1 context:(id)arg2 completion:(/*^block*/id)arg3 ;
-(unsigned long long)stewieRetryCount;
-(id)stewieUpdateBlock;
-(void)unsubscribeForId:(id)arg1 clientApp:(id)arg2 completion:(/*^block*/id)arg3 ;
-(void)currentStewieStateWithCompletion:(/*^block*/id)arg1 ;

-(void)setStewieRetryCount:(unsigned long long)arg1 ;

-(void)subscribeAndFetchLocationForIds:(id)arg1 context:(id)arg2 completion:(/*^block*/id)arg3 ;
-(void)setClearCacheUpdates:(id)arg1 ;
-(void)latestLocationFromCacheForId:(id)arg1 completion:(/*^block*/id)arg2 ;
-(void)performKeyRollWithCompletion:(/*^block*/id)arg1 ;
-(void)setStewieUpdateBlock:(id)arg1 ;
-(void)shareCurrentKeyWithId:(id)arg1 idsHandles:(id)arg2 completion:(/*^block*/id)arg3 ;
-(id)clearCacheUpdates;
-(void)publishLocation:(id)arg1 completion:(/*^block*/id)arg2 ;
-(void)subscribeAndFetchLocationForIds:(id)arg1 clientApp:(id)arg2 completion:(/*^block*/id)arg3 ;
-(void)receivedUpdatedLocations:(id)arg1 ;
-(void)stewieServiceStateChanged:(long long)arg1 ;
-(void)fetchConfigFromServerWithCompletion:(/*^block*/id)arg1 ;
-(void)receivedLocationCommand:(id)arg1 completion:(/*^block*/id)arg2 ;
-(void)setLocationUpdates:(id)arg1 ;
@end

#endif
