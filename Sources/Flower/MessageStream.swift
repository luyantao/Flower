//
//  MessageStream.swift
//  Datable
//
//  Created by Dr. Brandon Wiley on 11/1/18.
//

import Foundation
import Transport
import Datable
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Network
#elseif os(Linux)
import NetworkLinux
#endif

extension Connection {
    
    public func readMessages(handler: @escaping (Message) -> Void) {
        
        self.receive(minimumIncompleteLength: 2, maximumLength: 2) { (maybeData, maybeContext, isComplete, maybeError) in
            
            if let error = maybeError {
                print("Error when calling receive (message length) from readMessages: \(error)")
                return
            }
            
            guard let data = maybeData else {
                return
            }
            
            let length = Int(data.uint16!)
            
            self.receive(minimumIncompleteLength: length, maximumLength: length, completion: { (maybeData, maybeContext, isComplete, maybeError) in

                if let error = maybeError {
                    print("Error when calling receive (message body) from readMessages: \(error)")
                    return
                }
                
                guard let data = maybeData else {
                    return
                }
                
                guard let message = Message(data: data) else {
                    return
                }
                
                handler(message)
                self.readMessages(handler: handler)
            })
        }
    }

    public func writeMessage(message: Message, completion: @escaping (NWError?) -> Void) {
        var data = Data()
        data.append(UInt8(0))
        data.append(UInt16(message.data.count).data)
        data.append(message.data)
        
        self.send(content: data, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed( { (maybeLengthError) in
                
                if let lengthError = maybeLengthError {
                    print("Error sending length bytes. Error: \(lengthError)")
                    completion(lengthError)
                    return
                }
        }))
    }
}
