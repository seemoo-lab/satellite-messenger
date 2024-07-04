//
//  MessageSender.swift
//  StewieMessenger
//
//  Created by jiska on 17.05.24.
//

import Foundation
import OSLog

class MessageSender {

    static let shared = MessageSender()
    private let messageFile = "/private/var/mobile/Library/com.apple.icloud.searchpartyd/satellite.txt"
    private let ms = MessageSenderOC.init()  // Objective-C instance
    
    private init() {
        
    }
        
    
    func sendMessage(message: Message) -> MessageSenderError {
        
        let textMessage = message.getText()
        NSLog("Peparing to send Stewie message: %{public}@", textMessage)
        
        // Apple now seems to block messages of wrong lengths and if not starting with 0x04 like the encryption key.
        // After the message header, we have 82 bytes, starting with 0x04 = 81 bytes max. message length.
        
        var b: Data = Data(capacity: 82)

        if (textMessage.allSatisfy(\.isASCII)) {
            b.append(UInt8(0x4))
            guard let encoded = textMessage.data(using: .ascii) else { return MessageSenderError.nonAscii }
            b.append(encoded)  // message
            let paddingLength = 82 - b.count
            b.append(Data.init(repeating: 0x20, count: paddingLength))
        } else {
            return MessageSenderError.nonAscii
        }
        
        
        do {
            //try textMessage.write(toFile: messageFile, atomically: true, encoding: String.Encoding.ascii)
            try b.write(to: URL.init(filePath: messageFile), options: Data.WritingOptions())
        }
        catch {
            // TODO maybe entitlement com.apple.icloud.searchpartyd.access is sufficient for file access, but currently running unsandboxed
            return MessageSenderError.noFileWrite
            
        }
            

        // using Objective-C for the framework invocation
        ms?.publishMessage()

        return MessageSenderError.success
    }
    
    // get message send state
    //  0 - no previous state
    //
    //  5 - transmission in progress
    func getState() -> Int {
        return Int(ms?.getState() ?? 0)
    }
    
}

enum MessageSenderError: Error {
    case success
    case nonAscii
    case noFileWrite
}
