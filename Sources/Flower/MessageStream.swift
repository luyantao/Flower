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
                    
        self.receive(minimumIncompleteLength: 1, maximumLength: 10000, completion: { (maybeData, maybeContext, isComplete, maybeError) in

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
        })
    }

    public func writeMessage(message: Message, completion: @escaping (NWError?) -> Void) {
        var data2 = Data()

        switch message {
        
        case .IPDataV4(let data):
            data2.append(UInt8(0))
            data2.append(UInt16(data.count).data)
            data2.append(data)

        default:
            completion(nil) // TODO
            return
        }
        
        self.send(content: data2, contentContext: NWConnection.ContentContext.defaultMessage, isComplete: false, completion: NWConnection.SendCompletion.contentProcessed( { (maybeLengthError) in
                
                if let lengthError = maybeLengthError {
                    print("Error sending length bytes. Error: \(lengthError)")
                    completion(lengthError)
                    return
                }
        }))
    }
}
