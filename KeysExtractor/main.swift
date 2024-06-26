//
//  main.swift
//  KeysExtractor
//
//  Created by Alex - SEEMOO on 26.06.24.
//

import Foundation
import Network
import OSLog



func setupSocket() {
    let listener = try! NWListener(using: .tcp, on: .init(rawValue: 5345)!)
    listener.start(queue: .global(qos: .default))
    listener.newConnectionHandler = { connection in
        listenForMessages(connection: connection)
    }
}


func listenForMessages(connection: NWConnection) {
}
