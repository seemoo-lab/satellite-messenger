//
//  SPSecureLocationsClientXPCProtocol.h
//  
//
//  Created by jiska on 18.05.24.
//

#import <Foundation/Foundation.h>

@protocol SPSecureLocationsClientXPCProtocol <NSObject>

@required
-(void)clearLocationsForFailedSubscriptions:(id)arg1;
-(void)receivedUpdatedLocations:(id)arg1;
-(void)stewieServiceStateChanged:(long long)arg1;
@end
