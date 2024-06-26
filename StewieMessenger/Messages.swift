//
//  Messages.swift
//  StewieMessenger
//
//  Caches the sent and received messages
//
//  Created by jiska on 18.05.24.
//

import Foundation
import SwiftUI

struct Messages {
    static let shared = Messages()
    static var maxMessageId = 0
}


class Message: Hashable, Comparable {
    let id: Int
    let text: String
    var direction: Bool // send direction = false
    var stewieState: Int
    var sender: String?
    var timestamp: Date
    
    init(withText: String, directionReceive: Bool, sender: String?=nil, timestamp:Date = Date(), stewieState: Int = 0) {
        id = Messages.maxMessageId
        Messages.maxMessageId = Messages.maxMessageId + 1
        text = withText
        direction = directionReceive
        self.sender = sender
        self.timestamp = timestamp
        self.stewieState = stewieState
    }
    
    func getText() -> String {
        return text;
    }
    
    func isSendDirection() -> Bool {
        return direction;
    }
    
    func setStewieState(state: Int) {
        self.stewieState = state
    }
    
    func getColor() -> Color {

        // blue in send direction
        if !direction {
            switch stewieState {
            // 0 and 1 are default states I thin?
            case 0:  // uninitialized
                return Color.secondary.opacity(0.2)
            case 1:  // last send failed
                return Color.secondary.opacity(0.2)
            case 5:  // sending in progress
                return Color(UIColor.systemBlue).opacity(0.4)
            case 6:  // success
                return Color(UIColor.systemBlue)
            case 10: // custom state for throttled
                return Color.secondary.opacity(0.2)
            default:
                return Color.secondary.opacity(0.3)
            }
        }
        // gray in receive direction
        else {
            return Color.secondary
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(sender)
        hasher.combine(direction)
    }
    
    static func < (lhs: Message, rhs: Message) -> Bool {
        return lhs.timestamp < rhs.timestamp
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.text == rhs.text && lhs.sender == rhs.sender
    }
}
