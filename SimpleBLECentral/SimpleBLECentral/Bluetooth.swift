//
//  Bluetooth.swift
//  SimpleBLECentral
//
//  Created by Rick Pasetto on 3/5/20.
//  Copyright © 2020 Rick Pasetto. All rights reserved.
//

import CoreBluetooth
import UIKit

let myCustomServiceID = CBUUID(string: "623B9814-B2EA-4E78-ABE8-CC9D1D76A836")
let myCustomCharacteristicID = CBUUID(string: "32745B79-D94C-4879-B063-AA3323EBBCC6")

let serviceCBUUIDs = [myCustomServiceID]

protocol BluetoothDelegate: class {
    func connectedUpdated(value: Bool)
    func valueUpdated(value: Int)
    func scanningUpdated(value: Bool)
}

class Bluetooth: NSObject {
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    
    weak var delegate: BluetoothDelegate?
    
    var onPoweredOn: (() -> Void)?
    
    var scanStart: Date? {
        didSet {
            if let scanStart = scanStart {
                UserDefaults.standard.set(ISO8601DateFormatter().string(from: scanStart), forKey: "SimpleBLECentral.scanStart")
            } else {
                UserDefaults.standard.set(nil, forKey: "SimpleBLECentral.scanStart")
            }
        }
    }
    
    var miscData: String? {
        didSet {
            if let miscData = miscData {
                UserDefaults.standard.set(miscData, forKey: "SimpleBLECentral.miscData")
            } else {
                UserDefaults.standard.set(nil, forKey: "SimpleBLECentral.miscData")
            }
        }
    }
    
    
    init(delegate: BluetoothDelegate?) {
        self.delegate = delegate
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil,
                                          options: [ CBCentralManagerOptionRestoreIdentifierKey: "SimpleBLECentralID" ])
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) {_ in
            self.applicationDidEnterBackground()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) {_ in
            self.applicationWillEnterForeground()
        }
        
    }
    
    func connect() {
        Logger.instance.output("")
        startScanning()
    }
    
    func disconnect() {
        Logger.instance.output("")
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        delegate?.connectedUpdated(value: false)
        peripheral = nil
    }
    
    private func applicationDidEnterBackground() {
        Logger.instance.output("\(#function)")
        store()
    }
    
    private func applicationWillEnterForeground() {
        dump()
        Logger.instance.output("\(#function)")
    }
    
}

extension Bluetooth: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            Logger.instance.output("central.state is .unknown")
        case .resetting:
            Logger.instance.output("central.state is .resetting")
        case .unsupported:
            Logger.instance.output("central.state is .unsupported")
        case .unauthorized:
            Logger.instance.output("central.state is .unauthorized")
        case .poweredOff:
            Logger.instance.output("central.state is .poweredOff")
        case .poweredOn:
            Logger.instance.output("central.state is .poweredOn")
            onPoweredOn?()
            onPoweredOn = nil
        @unknown default:
            Logger.instance.error("central.state is unknown \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Logger.instance.output("\(peripheral), rssi: \(RSSI), data: \(advertisementData)")
        connect(to: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Logger.instance.output("Peripheral: \(peripheral.state)")
        delegate?.connectedUpdated(value: true)
        peripheral.discoverServices(serviceCBUUIDs)
        //        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Logger.instance.output("Peripheral: \(peripheral.state)")
        delegate?.connectedUpdated(value: false)
        self.peripheral = nil
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        defer {
            dump()
        }
        guard let peripheralsConnectedToPreviously = dict[ CBCentralManagerRestoredStatePeripheralsKey ] as? [CBPeripheral] else {
            Logger.instance.output("No restored peripherals")
            return
        }
        
        Logger.instance.output("peripheralsConnectedToPreviously = \(String(describing: peripheralsConnectedToPreviously))")
        
        for peripheral in peripheralsConnectedToPreviously {
            connect(to: peripheral)
        }
    }
    
}

extension Bluetooth: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            Logger.instance.error("No services")
            return
        }
        
        for service in services {
            Logger.instance.output("\(service): \(String(describing: service.characteristics))")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            Logger.instance.output("\(service): \(characteristic) read: \(characteristic.properties.contains(.read)) notify: \(characteristic.properties.contains(.notify))")
            
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //        Logger.instance.output("Updated value for \(characteristic.uuid): \(String(describing: characteristic.value))")
        guard characteristic.uuid == myCustomCharacteristicID else {
            Logger.instance.error("Updated unknown Characteristic \(characteristic)")
            return
        }
        let value = characteristic.value?.withUnsafeBytes { $0.bindMemory(to: Int.self)[0] }
        guard let counter = value else {
            Logger.instance.error("Could not read int value")
            return
        }
        Logger.instance.output("Counter is \(counter)")
        miscData = "\(counter)"
        delegate?.valueUpdated(value: counter)
    }
}

extension Bluetooth {
    private func startScanning() {
        if centralManager.state != .poweredOn {
            Logger.instance.error("Not powered on")
            return
        }
        Logger.instance.output("")
        scanStart = Date()
        centralManager.scanForPeripherals(withServices: serviceCBUUIDs)
        delegate?.scanningUpdated(value: true)
    }
    
    private func connect(to peripheral: CBPeripheral) {
        let function = { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.centralManager.isScanning {
                strongSelf.centralManager.stopScan()
                strongSelf.delegate?.scanningUpdated(value: false)
            }
            strongSelf.peripheral = peripheral
            strongSelf.peripheral?.delegate = self
            strongSelf.centralManager.connect(peripheral, options: [
                CBConnectPeripheralOptionNotifyOnNotificationKey: true,
                CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
                CBConnectPeripheralOptionNotifyOnConnectionKey: true
            ])
        }
        if centralManager.state == .poweredOn {
            function()
            onPoweredOn = nil
        } else {
            onPoweredOn = function
        }
    }
}


extension CBPeripheralState: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        @unknown default:
            return "<unknown>"
        }
    }
}
