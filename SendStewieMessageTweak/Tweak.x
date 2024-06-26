#import <Foundation/Foundation.h>
#import "CTStewieFindMyMessage.h"

// A group that explicitly must be initialized which is only done for the searchpartyd process
%group searchpartyd 


%hook CTStewieDataClient
-(BOOL)sendMessage:(CTStewieFindMyMessage*)msg completion:(void (^)(id data))block {  //CTStewieFindMyMessage
	// logs: 
	// May 17 18:32:35 searchpartyd(SendStewieMessage.dylib)[1643] <Notice>: -[<CTStewieDataClient: 0x742b521b0> sendMessage:<CTStewieFindMyMessage 0x742b40cc0, encryptedData={length = 82, bytes = 0x0442d968 9485e381 543edaf2 17334497 ... c0f6f496 17090b07 }> completion:<__NSMallocBlock__: 0x742a65580>]
	%log;

	// read message from file 
	NSString *filePath = @"/private/var/mobile/Library/com.apple.icloud.searchpartyd/satellite.txt";
	NSString *messageFromFile = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

	// only overwrite if file exists
	if (messageFromFile) {
		NSLog(@"Found satellite message in file: %@", messageFromFile);

		NSData *newMessageData = [messageFromFile dataUsingEncoding:1];
		[msg setEncryptedData:newMessageData];

		// delete file to allow for normal find my friends messages later on
		NSError *error = nil;
		[[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
	}

	// Call the original implementation and get the array
	BOOL r = %orig;

	NSLog(@"Replaced message with tweak: %@", msg);

	return r;
}

%end

%end


%ctor {
	// We're using CoreTelephony framework but only want to inject into searchpartyd
	NSString* programName = [NSString stringWithUTF8String: argv[0]];
	if ([programName isEqualToString:@"/usr/libexec/searchpartyd"]) {
		NSLog(@"Hello from the SendStewieMessage tweak %@", programName);
		// Only enable the tweak for the process searchpartyd
		%init(searchpartyd)
	}
	
}

%dtor {
	NSLog(@"Bye from tweak");

}