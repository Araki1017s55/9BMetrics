//
//  BLEConnection.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 12/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//( at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


import UIKit
import CoreBluetooth

struct BLEService {
    var id : String = ""
    var characteristics : [String : BLECharacteristic] = [:]
    var service : CBService?
    var done = false
    
}

struct BLECharacteristic {
    var service : String
    var id : String
    var flags : String
    var characteristic : CBCharacteristic?
    
    
}


class BLEMimConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    internal let kUUIDDeviceInfoService = "180A"
    internal let kUUIDManufacturerNameVariable = "2A29"
    internal let kUUIDModelNameVariable = "2A24"
    internal let kUUIDSerialNumberVariable = "2A25"
    internal let kUUIDHardwareVersion = "2A27"
    internal let kUUIDFirmwareVersion = "2A26"
    internal let kUUIDSoftwareVersion = "2A28"
    
    internal static let kLast9BDeviceAccessedKey = "9BDEVICE"
    
    
    
    var centralManager : CBCentralManager?
    var discoveredPeripheral : CBPeripheral?
    
    var wheelServices : [String : BLEService] = [:]
    
    var caracteristica : CBCharacteristic?
    
    
    var scanning = false
    var connected = false
    var subscribed = false
    var connecting = false
    
    var connectionRetries = 0
    var maxConnectionRetries = 5
    
    // These characteristics are not used usually
    
    var manufacturer : String?
    var model : String?
    var serial : String?
    var hardwareVer : String?
    var firmwareVer : String?
    var softwareVer : String?
    
    
    var delegate : BLEMimConnectionDelegate?
    
    override init()
    {
        AppDelegate.debugLog("Init")
        
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil) // Startup Central Manager
        
        
    }
    
    
    internal func connectToDeviceWithUUID(device : String){
        AppDelegate.debugLog("Connect to device")
        
        if let central = self.centralManager{
            self.connecting = true
            
            if central.state == CBCentralManagerState.PoweredOn{
                
                let ids = [NSUUID(UUIDString:device)!]
                
                let devs : [CBPeripheral] = self.centralManager!.retrievePeripheralsWithIdentifiers(ids)
                if devs.count > 0
                {
                    let peripheral : CBPeripheral = devs[0]
                    self.connectPeripheral(peripheral)
                    
                    return
                }
            }
        }
    }
    
    func lookupChar(uuid : String) -> CBCharacteristic? {
        
  
        
        for (_, srv) in wheelServices{
            
            if let blch = srv.characteristics[uuid] {
                return blch.characteristic
            }
        }
        
        return nil
        
    }
    internal func stopConnection()
    {
        AppDelegate.debugLog("Stop Connection")
        
        
        self.scanning = false
        if let cm = self.centralManager {
            if cm.state == CBCentralManagerState.PoweredOn{
                cm.stopScan()
            }
        }
        
        self.cleanup()
        //        self.centralManager = nil
        
    }
    
    
    internal func cleanup() {
        
        // See if we are subscribed to a characteristic on the peripheral
        AppDelegate.debugLog("Cleanup")
        
        if let thePeripheral = self.discoveredPeripheral  {
            if let theServices = thePeripheral.services {
                
                for service : CBService in theServices {
                    
                    if let theCharacteristics = service.characteristics {
                        for characteristic : CBCharacteristic in theCharacteristics {
                            if characteristic.isNotifying {
                                self.discoveredPeripheral!.setNotifyValue(false, forCharacteristic:characteristic)
                                //return;
                            }
                        }
                    }
                }
            }
            if let peri = self.discoveredPeripheral {
                if let central = self.centralManager{
                    central.cancelPeripheralConnection(peri) //**
                }
            }
        }
        
        self.connected = false
        self.subscribed = false
        self.connecting = false
        self.discoveredPeripheral = nil //**
    }
    
    //MARK: CBCentralManagerDelegate
    
    
    internal func centralManagerDidUpdateState(central : CBCentralManager)
    {
        AppDelegate.debugLog("Update state")
        
        self.scanning = false;
        
        if central.state == CBCentralManagerState.PoweredOn && connecting {
            
            let store = NSUserDefaults.standardUserDefaults()
            let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
            
            if let dev = device {
                self.connectToDeviceWithUUID(dev)
            }else {
                startScanning()
            }
            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kBluetoothManagerPoweredOnNotification, data: nil)
        }
    }
    
    // MARK: Scanning for Bluetooth Devices
    
    func startScanning(){
        AppDelegate.debugLog("Start Scanning")
        
        
        let services : [CBUUID] = []
        let moreDevs : [CBPeripheral] = self.centralManager!.retrieveConnectedPeripheralsWithServices(services)
        
        if  moreDevs.count > 0
        {
            BLESimulatedClient.sendNotification(BLESimulatedClient.kdevicesDiscoveredNotification, data: ["peripherals" : moreDevs])
            return
        }
        
        // OK, nothing works so we go for the scanning
        
        self.doRealScan()
    }
    
    func doRealScan(){
        
        let _ = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BLEMimConnection.scanForDevices(_:)), userInfo: nil, repeats: false)
    
    }
    
    func scanForDevices(tim : NSTimer){
        
        tim.invalidate()
    
        if let central = self.centralManager{
            if central.state == CBCentralManagerState.PoweredOn{
                 self.centralManager!.scanForPeripheralsWithServices(nil, options:[CBCentralManagerScanOptionAllowDuplicatesKey : false ])
                 self.scanning = true
                 AppDelegate.debugLog("Scanning started")
            }else{
                doRealScan()
            }
        }
        
    }
        
        
    
    
    internal func centralManager(central: CBCentralManager,
                                 didDiscoverPeripheral peripheral: CBPeripheral,
                                                       advertisementData: [String : AnyObject],
                                                       RSSI: NSNumber){
        
        BLESimulatedClient.sendNotification(BLESimulatedClient.kdevicesDiscoveredNotification, data: ["peripherals" : [peripheral]])
        
        var name = "Unknown"
        
        if let nam = peripheral.name {
            name = nam
        }
        
        AppDelegate.debugLog("Discovered %@ - %@ (%@)", name, peripheral.identifier, BLESimulatedClient.kdevicesDiscoveredNotification );
        return
    }
    
    func connectPeripheral(peripheral : CBPeripheral)
    {
        AppDelegate.debugLog("Connect to peripheral")
        
        if let central = self.centralManager{
            self.connecting = true
            AppDelegate.debugLog("Connecting to peripheral %@", peripheral);
            
            central.stopScan()     // Just in the case, stop scan when finished to looking for more devices
            
            self.discoveredPeripheral = peripheral;
            central.connectPeripheral(peripheral, options:nil)
        }
        else{
            
            if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error",format:"There is no Central Manager!!!")
            }
            
            AppDelegate.debugLog("No Central Manager")
        }
    }
    
    
    internal func centralManager(central : CBCentralManager, didFailToConnectPeripheral peripheral : CBPeripheral,  error : NSError?)
    {
        BLESimulatedClient.sendNotification(BLESimulatedClient.kConnectionLostNotification, data: ["peripheral" : peripheral])
        self.cleanup()
        
    }
    
    internal func centralManager(central : CBCentralManager, didConnectPeripheral peripheral :CBPeripheral){
        AppDelegate.debugLog("Connected to peripheral");
        
        if self.scanning    // Just in case!!!
        {
            self.centralManager!.stopScan()
            self.scanning = false
            AppDelegate.debugLog("Scanning stopped")
        }
        
        peripheral.delegate = self;
        
        //[peripheral discoverServices:nil];
        
        manufacturer = ""
        model = ""
        serial = ""
        hardwareVer = ""
        firmwareVer = ""
        softwareVer = ""
        self.wheelServices.removeAll()
        
        peripheral.discoverServices(nil)
        AppDelegate.debugLog("Discovering services");

    }
    
    internal func centralManager(central: CBCentralManager,
                                 didDisconnectPeripheral peripheral: CBPeripheral,
                                                         error: NSError?)
        
    {
        AppDelegate.debugLog("DidDisconnectPeripheral")
        
        if self.connected && self.subscribed    {   // Try to reconnect
            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStartConnection, data:["status":"Connecting"] )
            
            
            self.connectionRetries = connectionRetries + 1
            
            if connectionRetries < maxConnectionRetries{
                let store = NSUserDefaults.standardUserDefaults()
                let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
                
                if let dev = device  // Try to connect to last connected peripheral
                {
                    
                    if let theId = NSUUID(UUIDString:dev){
                        
                        let ids  = [theId]
                        let devs : [CBPeripheral] = self.centralManager!.retrievePeripheralsWithIdentifiers(ids)
                        
                        if devs.count > 0
                        {
                            let peri : CBPeripheral = devs[0]
                            
                            self.connectPeripheral(peri)
                            
                            //TODO: Probablement modificar per establir la connexio directament
                            //self.centralManager(central,  didDiscoverPeripheral:peri,  advertisementData:["Hello" : "Hello"],  RSSI:NSNumber())
                            return;
                        }
                    }
                }
                    
                else {
                    
                }
            }
        }
        self.connected = false
        self.subscribed = false
        
        BLESimulatedClient.sendNotification(BLESimulatedClient.kConnectionLostNotification, data: ["peripheral" : peripheral])
        
        if let dele = self.delegate{
            dele.deviceDisconnected(peripheral)
        }
        self.discoveredPeripheral = nil;
    }
    
    //MARK: writeValue
    
    func subscribeToChar(char: CBCharacteristic){
        if let ch = lookupChar(char.UUID.UUIDString){
            if let peri = self.discoveredPeripheral {
                peri.setNotifyValue(true, forCharacteristic:ch)
            }
        }
    }
    
    func unsubscribeToChar(char: CBCharacteristic){
        if let ch = lookupChar(char.UUID.UUIDString){
            if let peri = self.discoveredPeripheral {
                peri.setNotifyValue(false, forCharacteristic:ch)
            }
        }
    }
    
    func writeValue(char : CBCharacteristic, data : NSData){
        
        if let ch = lookupChar(char.UUID.UUIDString){
            if let peri = self.discoveredPeripheral {
                peri.writeValue(data, forCharacteristic: ch, type: .WithoutResponse)
            }
        }
    }
    
    func readValue(char : CBCharacteristic){
        
        if let ch = lookupChar(char.UUID.UUIDString){
            if let peri = self.discoveredPeripheral {
                peri.readValueForCharacteristic(ch)
            }
        }
    }

    
    //MARK: CBPeripheralDelegate
    
    internal func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?)
    {
        AppDelegate.debugLog("Services Discovered. Discovering characteristics");
        
        if let serv = peripheral.services{
            for sr in serv
            {
                AppDelegate.debugLog("Service %@", sr.UUID.UUIDString)
                peripheral.discoverCharacteristics(nil, forService:sr)
                
                //TODO : Afegir sr a la llista de serveis de l'aplicacio
                
                if self.wheelServices[sr.UUID.UUIDString] == nil{
                    self.wheelServices[sr.UUID.UUIDString] = BLEService(id: sr.UUID.UUIDString, characteristics: [:], service: sr, done: false)
                }
            }
        }
    }
    
    
    
    internal func peripheral(peripheral: CBPeripheral,
                             didDiscoverCharacteristicsForService service: CBService,
                                                                  error: NSError?)
    {
        
        AppDelegate.debugLog("Characteristics discovered");

        // Sembla una bona conexio, la guardem per mes endavant
        
        
        // Sembla una bona conexio, la guardem per mes endavant
        let store = NSUserDefaults.standardUserDefaults()
        let idPeripheral = peripheral.identifier.UUIDString
        
        store.setObject(idPeripheral, forKey:BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let  srv = wheelServices[service.UUID.UUIDString]{
            
            var sr = srv
            
            
            if let characteristics = service.characteristics {
                for ch in characteristics {
                    
                    
                    var flags = ""
                    
                    if ch.properties.contains(.Read){
                        flags = flags + "r"
                    }
                    
                    
                    if ch.properties.contains(.Write){
                        flags = flags + "w"
                    }

                    if ch.properties.contains(.WriteWithoutResponse){
                        flags = flags + "x"
                    }

                    if ch.properties.contains(.Notify){
                        flags = flags + "n"
                    }
                    if ch.properties.contains(.Indicate){
                        flags = flags + "i"
                    }
                    
                    let blechr = BLECharacteristic(service: sr.id, id: ch.UUID.UUIDString, flags: flags, characteristic: ch)
                    
                    sr.characteristics[ch.UUID.UUIDString] = blechr
               
                     AppDelegate.debugLog("Characteristic  %@ / %@ (%@)", blechr.service, blechr.id,flags)
                }
            }
            
            sr.done = true
            wheelServices[service.UUID.UUIDString] = sr
        }
        
        if allDone() {
            
            // OK Now we send back to interestes parties the complete service
            
            if let dele = delegate {
                dele.deviceAnalyzed(peripheral, services: self.wheelServices)
                self.connected = true
                self.connecting = false
            }

            NSLog("All services read")
        }
    }
    
    func allDone () -> Bool{
        
        for (_, serv) in wheelServices{
            if !serv.done {
                return false
            }
            
        }
        return true
    }
    
    
    func peripheral(peripheral: CBPeripheral,
                    didUpdateValueForCharacteristic characteristic: CBCharacteristic,
                                                    error: NSError?){
        
        // Primer obtenim el TMKPeripheralObject
        
        
        
        if let data = characteristic.value {
            self.delegate?.charUpdated(characteristic, data: data)
        }
            
        else if characteristic.UUID.UUIDString==self.kUUIDManufacturerNameVariable  {
            
            if let data = characteristic.value {
                self.manufacturer = String(data:data, encoding: NSUTF8StringEncoding)
                AppDelegate.debugLog("Manufacturer : %@", self.manufacturer!)
            }
        }
        else if characteristic.UUID.UUIDString==self.kUUIDModelNameVariable  {
            
            if let data = characteristic.value {
                self.model = String(data:data, encoding: NSUTF8StringEncoding)
                AppDelegate.debugLog("Model : %@", self.model!)
            }
        }
        else if characteristic.UUID.UUIDString==self.kUUIDSerialNumberVariable  {
            
            if let data = characteristic.value {
                self.serial = String(data:data, encoding: NSUTF8StringEncoding)
                AppDelegate.debugLog("Serial : %@", self.serial!)
            }
        }
        else if characteristic.UUID.UUIDString==self.kUUIDHardwareVersion  {
            
            if let data = characteristic.value {
                self.hardwareVer = String(data:data, encoding: NSUTF8StringEncoding)
                AppDelegate.debugLog("Hardware Version : %@", self.hardwareVer!)
            }
        }
        else if characteristic.UUID.UUIDString==self.kUUIDFirmwareVersion  {
            
            if let data = characteristic.value {
                self.firmwareVer = String(data:data, encoding: NSUTF8StringEncoding)
                AppDelegate.debugLog("Firmware Version : %@", self.firmwareVer!)
            }
        }
        else if characteristic.UUID.UUIDString==self.kUUIDSoftwareVersion {
            
            if let data = characteristic.value {
                self.softwareVer = String(data:data, encoding: NSUTF8StringEncoding)
                AppDelegate.debugLog("Software Ver : %@", self.softwareVer!)
            }
        }
    }
}
