//
//  Bluetooth.swift
//  SimpleBLEPeripheral
//
//  Created by Rick Pasetto on 3/5/20.
//  Copyright © 2020 Rick Pasetto. All rights reserved.
//

import CoreBluetooth

let heartRateServiceID = CBUUID(string: "180D") // Heart Rate Service
let myCustomServiceID = CBUUID(string: "623B9814-B2EA-4E78-ABE8-CC9D1D76A836")
let myCustomCharacteristicID = CBUUID(string: "32745B79-D94C-4879-B063-AA3323EBBCC6")

class Bluetooth: NSObject {
    
    var peripheralManager: CBPeripheralManager!
    var characteristic: CBMutableCharacteristic?
    var service: CBMutableService!
    
    var isAdvertising: Bool {
        get {
            return peripheralManager.isAdvertising
        }
    }
    
    var counter: Int = 0 {
        didSet {
            update()
        }
    }
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    deinit {
        stopAdvertising()
    }
    
    func startAdvertising() {
        Logger.instance.output("")
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [ myCustomServiceID ]
        ])
    }
    
    func stopAdvertising() {
        Logger.instance.output("")
        peripheralManager.stopAdvertising()
    }
}

extension Bluetooth: CBPeripheralManagerDelegate {
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            Logger.instance.error("Error publishing BLE service: \(error)")
        } else {
            Logger.instance.output("")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            Logger.instance.error("Error starting to advertise: \(error)")
        } else {
            Logger.instance.output("")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == characteristic?.uuid else {
            Logger.instance.error("mismatched UUID: \(request.characteristic.uuid) != \(String(describing: characteristic?.uuid))")
            return
        }
        
        guard let length = characteristic?.value?.count else {
            Logger.instance.error("Invalid characteristic offset")
            return
        }
        
        guard request.offset <= length else {
            Logger.instance.error("Invalid offset  \(request.offset) > \(length)")
            return
        }
        let range = Range(request.offset...(length - request.offset))
        Logger.instance.output("Range = \(range)")
        
        request.value = characteristic?.value?.subdata(in: range)
        
        peripheralManager.respond(to: request, withResult: .success)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        Logger.instance.output("\(central) subscribed to \(characteristic)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        Logger.instance.output("\(central) unsubscribed from \(characteristic)")
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Logger.instance.output("update: \(peripheral.state)")
        
        if peripheral.state == .poweredOn {
            addService()
        }
    }
    
    private func update() {
        guard let characteristic = characteristic else {
            return
        }
        Logger.instance.output("counter: \(counter)")

        let value = Data(bytes: &counter, count: MemoryLayout.size(ofValue: counter))
        characteristic.value = value
        peripheralManager.updateValue(value, for: characteristic, onSubscribedCentrals: nil)
    }
    
    private func addService() {
        let characteristic = CBMutableCharacteristic(type: myCustomCharacteristicID,
                                                     properties: CBCharacteristicProperties([.read, .notify]),
                                                     value: nil,
                                                     permissions: .readable)
        service = CBMutableService(type: myCustomServiceID, primary: true)
        service.characteristics = [characteristic]
        peripheralManager.add(service)
        self.characteristic = characteristic
    }
}


extension CBManagerState: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .unknown:
        return "unknown"
    case .resetting:
        return "resetting"
    case .unsupported:
        return "unsupported"
    case .unauthorized:
        return "unauthorized"
    case .poweredOff:
        return "poweredOff"
    case .poweredOn:
        return "poweredOn"
    @unknown default:
        return "<unknown>"
    }
  }
}
