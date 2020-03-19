//
//  Logger.swift
//  SimpleBLECentral
//
//  Created by Rick Pasetto on 3/5/20.
//  Copyright © 2020 Rick Pasetto. All rights reserved.
//

import os.log

class Logger {
    static public let instance = Logger()
    private let log = OSLog(category: "SimpleBLECentral")
    static public var prefixFunc: () -> String = { return "" }
    
    func output(_ message: String, function: StaticString = #function) {
        logEntry(log.default, message, function)
    }
    
    func error(_ message: String, function: StaticString = #function) {
        logEntry(log.error, message, function)
    }
    
    private func logEntry(_ logFunc: (_ message: StaticString, _ args: CVarArg...) -> Void, _ message: String, _ function: StaticString) {
        logFunc("%{public}@%{public}@: %{public}@", Logger.prefixFunc(), function.description, message)
    }
}

extension OSLog {
    convenience init(category: String) {
        self.init(subsystem: "com.rickpasetto.ble", category: category)
    }
    
    func debug(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .debug, args)
    }
    
    func info(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .info, args)
    }
    
    func `default`(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .default, args)
    }
    
    func error(_ message: StaticString, _ args: CVarArg...) {
        log(message, type: .error, args)
    }
    
    private func log(_ message: StaticString, type: OSLogType, _ args: [CVarArg]) {
        switch args.count {
        case 0:
            os_log(message, log: self, type: type)
        case 1:
            os_log(message, log: self, type: type, args[0])
        case 2:
            os_log(message, log: self, type: type, args[0], args[1])
        case 3:
            os_log(message, log: self, type: type, args[0], args[1], args[2])
        case 4:
            os_log(message, log: self, type: type, args[0], args[1], args[2], args[3])
        case 5:
            os_log(message, log: self, type: type, args[0], args[1], args[2], args[3], args[4])
        default:
            os_log(message, log: self, type: type, args)
        }
    }
}
