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
/*
 
 CONNECTIONS :
 
 - Main connection is to delegate.
 
 deviceAnalyzed when analyzing a device
    it is called when all service and chars data have been read
 
 deviceConnected when getting the connection
    it is called when there is an adapter for the wheel
 
 deviceDisconnected when receiving a disconnection
    it is called when received a BLE device disconnect
 
 charUpdated when receiving data
    it is called when received an updated value for a characteristic
 
 
 - Notifications
 
    kBluetoothManagerPoweredOnNotification : When CM is Powered On && Connecting (veure estats). No feta servir de moment
 
    kDevicesDiscoveredNotification : Sends an array of devices either when already connected or new ones
        It is received in BLEDeviceSelector and adds the devices to the list
        It is received in Dashboards and prompts them to open the selector with the devices as initial list
            Now they also add to the selector but probably may be removed as they are removed as listeners
            when the selector opens over them
        It is received by BLEMim. Same as Dashboards
 
    kConnectionLostNotification : Sent when not able to connect or lost connection for peripheral. No feta servir de moment
 
    kStartConnecting : When trying to reconnect
        It is sent also by BLESimulatedCLient when starting a new recording (connect)
        It is received by Dashboards to Start Animation
        It is received in ViewController but is legacy that must be removed
 
 
 
 */


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


class BLEMimConnection: NSObject, CBCentralManagerDelegate  {
    
    
    enum ConnectionState {
        case disconnected
        case scanning
        case connecting
        case connected
    }
    
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
    
    
    var state : ConnectionState = .disconnected
    var uuidToConnect : String?
    
/*    var scanning = false
    var connected = false
    var subscribed = false
    var connecting = false
 
 */
    
    
    
    
    var connectionRetries = 0
    var maxConnectionRetries = 5
    
    // These characteristics are not used usually
    
    var manufacturer : String?
    var model : String?
    var serial : String?
    var hardwareVer : String?
    var firmwareVer : String?
    var softwareVer : String?
    
    // Lasr Adapter returned
    
    var lastAdapter : BLEWheelAdapterProtocol?
    
    var delegate : BLEMimConnectionDelegate?
    
    override init()
    {
        AppDelegate.debugLog("Init")
        
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil) // Startup Central Manager
        
        
    }
    
    
    //MARK: Public Interface
    
     
    func connectToUUID(_ device : String){
        
        if state == .scanning{
            stopScanning()
        }
        
        state = .connecting
        uuidToConnect = device
        connectToDeviceWithUUID(device)
        
    }
    
    func disconnect(){
        
        self.stopConnection()

    }
    
    
    func startScanning(){
        
        if state != .disconnected{
            AppDelegate.debugLog("Desconnecteu abans de tornar a fer un scan")
            return
        }
        
        AppDelegate.debugLog("Start Scanning")
        
        state = .scanning
        let services : [CBUUID] = []
        let moreDevs : [CBPeripheral] = self.centralManager!.retrieveConnectedPeripherals(withServices: services)
        
        if  moreDevs.count > 0
        {
            BLESimulatedClient.sendNotification(BLESimulatedClient.kdevicesDiscoveredNotification, data: ["peripherals" : moreDevs])
            return
        }
        
        // OK, nothing works so we go for the scanning
        
        self.doRealScan()
    }
    
    func stopScanning(){
        
        if state == .scanning {
            if let mgr = self.centralManager {
                mgr.stopScan()
            }
            
        }
        state = .disconnected

    }
    
    
    //MARK: Exchanging data
    
    func subscribeToChar(_ char: String){
        
        if state != .connected {
            AppDelegate.debugLog("Trying to subscribeToChar without being connected")
            return
        }
        if let ch = lookupChar(char){
            if let peri = self.discoveredPeripheral {
                peri.setNotifyValue(true, for:ch)
            }
        }
    }
    
    func unsubscribeToChar(_ char: String){
        if state != .connected {
            AppDelegate.debugLog("Trying to unsubscribeToChar without being connected")
            return
        }
        if let ch = lookupChar(char){
            if let peri = self.discoveredPeripheral {
                peri.setNotifyValue(false, for:ch)
            }
        }
    }
    
    func writeValue(_ char : String, data : Data){
        if state != .connected {
            AppDelegate.debugLog("Trying to writeValue without being connected")
            return
        }
        
        if let ch = lookupChar(char){
            if let peri = self.discoveredPeripheral {
                peri.writeValue(data, for: ch, type: .withoutResponse)
            }
        }
    }
    
    func readValue(_ char : String){
        if state != .connected {
            AppDelegate.debugLog("Trying to readValue without being connected")
            return
        }
        
        if let ch = lookupChar(char){
            if let peri = self.discoveredPeripheral {
                peri.readValue(for: ch)
            }
        }
    }

    
    //MARK: Private Functions
    
    private func connectToDeviceWithUUID(_ device : String){
        AppDelegate.debugLog("Connect to device")
        
        if let central = self.centralManager{
            self.state = .connecting
            
            if central.state == .poweredOn{
                
                let ids = [UUID(uuidString:device)!]
                
                let devs : [CBPeripheral] = self.centralManager!.retrievePeripherals(withIdentifiers: ids)
                if devs.count > 0
                {
                    let peripheral : CBPeripheral = devs[0]
                    self.connectPeripheral(peripheral)
                    
                    return
                }
            }
        }
    }


    
    private func lookupChar(_ uuid : String) -> CBCharacteristic? {
        
        for (_, srv) in wheelServices{
            if let blch = srv.characteristics[uuid] {
                return blch.characteristic
            }
        }
        
        return nil
        
    }
    private  func stopConnection()
    {
        AppDelegate.debugLog("Stop Connection")
  
        if let cm = self.centralManager {
            if cm.state == .poweredOn{
                cm.stopScan()
            }
        }
        
        self.cleanup()
        
        self.uuidToConnect = nil
        self.state = .disconnected
        //        self.centralManager = nil
        
    }
    
    
    private func cleanup() {
        
        // See if we are subscribed to a characteristic on the peripheral
        AppDelegate.debugLog("Cleanup")
        
        if let thePeripheral = self.discoveredPeripheral  {
            if let theServices = thePeripheral.services {
                
                for service : CBService in theServices {
                    
                    if let theCharacteristics = service.characteristics {
                        for characteristic : CBCharacteristic in theCharacteristics {
                            if characteristic.isNotifying {
                                self.discoveredPeripheral!.setNotifyValue(false, for:characteristic)
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
        
        self.discoveredPeripheral = nil //**
    
    }
    
    //MARK: CBCentralManagerDelegate
    
    
    internal func centralManagerDidUpdateState(_ central : CBCentralManager)
    {
        AppDelegate.debugLog("Update state")
        
        if central.state == .poweredOn && state == .connecting {
            
            
                //let store = UserDefaults.standard
                //let device = store.string(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
            
                if let dev = uuidToConnect {
                    self.connectToDeviceWithUUID(dev)
                    BLESimulatedClient.sendNotification(BLESimulatedClient.kBluetoothManagerPoweredOnNotification, data: nil)
                }
        } else if central.state == .poweredOn && state == .scanning {
            startScanning()
            
        }
    }
    
    // MARK: Scanning for Bluetooth Devices
    
    
    private func doRealScan(){
        
        let _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(BLEMimConnection.scanForDevices(_:)), userInfo: nil, repeats: false)
        
    }
    
    func scanForDevices(_ tim : Timer){
        
        tim.invalidate()
        
        if let central = self.centralManager{
            if central.state == .poweredOn{
                
    //TODO : Modificar epr seleccionar els serveis amb un switch
                
                let theService =  [CBUUID(string: "FFE0")];
                
              
                self.centralManager!.scanForPeripherals(withServices: nil, options:[CBCentralManagerScanOptionAllowDuplicatesKey : false ])

                AppDelegate.debugLog("Scanning started")
            }else{
                doRealScan()
            }
        }
        
    }
    
    
    
    
    internal func centralManager(_ central: CBCentralManager,
                                 didDiscover peripheral: CBPeripheral,
                                 advertisementData: [String : Any],
                                 rssi RSSI: NSNumber){
        
        BLESimulatedClient.sendNotification(BLESimulatedClient.kdevicesDiscoveredNotification, data: ["peripherals" : [peripheral]])
        
        var name = "Unknown"
        
        if let nam = peripheral.name {
            name = nam
        }
        
        AppDelegate.debugLog("Discovered %@ - %@ (%@)", name, peripheral.identifier as CVarArg, BLESimulatedClient.kdevicesDiscoveredNotification );
        
        for (k, v) in advertisementData{
            AppDelegate.debugLog("   Advertising  %@ = %@", k, v as! CVarArg)
        }
        return
    }
    
    func connectPeripheral(_ peripheral : CBPeripheral)
    {
        AppDelegate.debugLog("Connect to peripheral")
        
        state = .connecting
        
        if let central = self.centralManager{

            AppDelegate.debugLog("Connecting to peripheral %@", peripheral);
            
            central.stopScan()     // Just in the case, stop scan when finished to looking for more devices
            
            self.discoveredPeripheral = peripheral;
            central.connect(peripheral, options:nil)
        }
        else{
            
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"There is no Central Manager!!!".localized())
            }
            
            AppDelegate.debugLog("No Central Manager")
        }
    }
    
    
    internal func centralManager(_ central : CBCentralManager, didFailToConnect peripheral : CBPeripheral,  error : Error?)
    {
        BLESimulatedClient.sendNotification(BLESimulatedClient.kConnectionLostNotification, data: ["peripheral" : peripheral])
        self.cleanup()
        
        
    }
    
    internal func centralManager(_ central : CBCentralManager, didConnect peripheral :CBPeripheral){
        
        AppDelegate.debugLog("Connected to peripheral");
        
        if state == .scanning    // Just in case!!!
        {
            self.centralManager!.stopScan()
            self.state =  .connecting
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
    
    internal func centralManager(_ central: CBCentralManager,
                                 didDisconnectPeripheral peripheral: CBPeripheral,
                                 error: Error?)
        
    {
        AppDelegate.debugLog("DidDisconnectPeripheral")
        
        if state == .connected || state == .connecting    {   // Try to reconnect

            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kConnectionLostNotification, data: ["peripheral" : peripheral])
            
            if let dele = self.delegate{
                dele.deviceDisconnected(peripheral)
            }

            state = .connecting
            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStartConnection, data:["status":"Connecting"] )
            self.connectionRetries = connectionRetries + 1
            
            if connectionRetries < maxConnectionRetries{
                let store = UserDefaults.standard
                let device = store.string(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
                
                if let dev = device  // Try to connect to last connected peripheral
                {
                    
                    if let theId = UUID(uuidString:dev){
                        
                        let ids  = [theId]
                        let devs : [CBPeripheral] = self.centralManager!.retrievePeripherals(withIdentifiers: ids)
                        
                        if devs.count > 0
                        {
                            let peri : CBPeripheral = devs[0]
                            
                            self.connectPeripheral(peri)
                            return
                        }
                    }
                }
                    
                else {
                    
                }
            }
        }
 
        disconnect()
    }
    
    
}
extension BLEMimConnection : CBPeripheralDelegate{
    
    internal func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        AppDelegate.debugLog("Services Discovered. Discovering characteristics");
        
        if let serv = peripheral.services{
            for sr in serv
            {
                AppDelegate.debugLog("Service %@", sr.uuid.uuidString)
                peripheral.discoverCharacteristics(nil, for:sr)
                
                //TODO : Afegir sr a la llista de serveis de l'aplicacio
                
                if self.wheelServices[sr.uuid.uuidString] == nil{
                    self.wheelServices[sr.uuid.uuidString] = BLEService(id: sr.uuid.uuidString, characteristics: [:], service: sr, done: false)
                }
            }
        }
    }
    
    
    
    internal func peripheral(_ peripheral: CBPeripheral,
                             didDiscoverCharacteristicsFor service: CBService,
                             error: Error?)
    {
        
        AppDelegate.debugLog("Characteristics discovered");
        
        // Sembla una bona conexio, la guardem per mes endavant
        
        
        // Sembla una bona conexio, la guardem per mes endavant
        let store = UserDefaults.standard
        let idPeripheral = peripheral.identifier.uuidString
        
        store.set(idPeripheral, forKey:BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let  srv = wheelServices[service.uuid.uuidString]{
            
            var sr = srv
            
            
            if let characteristics = service.characteristics {
                for ch in characteristics {
                    
                    
                    var flags = ""
                    
                    if ch.properties.contains(.read){
                        flags = flags + "r"
                    }
                    
                    
                    if ch.properties.contains(.write){
                        flags = flags + "w"
                    }
                    
                    if ch.properties.contains(.writeWithoutResponse){
                        flags = flags + "x"
                    }
                    
                    if ch.properties.contains(.notify){
                        flags = flags + "n"
                    }
                    if ch.properties.contains(.indicate){
                        flags = flags + "i"
                    }
                    
                    let blechr = BLECharacteristic(service: sr.id, id: ch.uuid.uuidString, flags: flags, characteristic: ch)
                    
                    sr.characteristics[ch.uuid.uuidString] = blechr
                    
                    AppDelegate.debugLog("Characteristic  %@ / %@ (%@)", blechr.service, blechr.id,flags)
                }
            }
            
            sr.done = true
            wheelServices[service.uuid.uuidString] = sr
        }
        
        if allDone() {
            
            // OK Now we send back to interestes parties the complete service
            AppDelegate.debugLog("All services read")
            
            self.state = .connected
            
            if let dele = delegate {
                dele.deviceAnalyzed(peripheral, services: self.wheelServices)
                
                if let adp = lastAdapter, let nam = peripheral.name{
                    if adp.isComptatible(services: self.wheelServices) && adp.getName() == nam{
                        dele.deviceConnected(peripheral, adapter: adp)
                        return
                    }
                }
                
                if let adapter = BLEWheelSelector.sharedInstance.getAdapter(wheelServices: self.wheelServices){
                    if let nam = peripheral.name {
                        adapter.setDefaultName(nam)
                    }
                    lastAdapter = adapter
                    dele.deviceConnected(peripheral, adapter: adapter)
                }

            }
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
    
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?){
        
        // Primer obtenim el TMKPeripheralObject
        
        
        
        if let data = characteristic.value {
            self.delegate?.charUpdated(characteristic, data: data)
        }
            
        else if characteristic.uuid.uuidString==self.kUUIDManufacturerNameVariable  {
            
            if let data = characteristic.value {
                self.manufacturer = String(data:data, encoding: String.Encoding.utf8)
                AppDelegate.debugLog("Manufacturer : %@", self.manufacturer!)
            }
        }
        else if characteristic.uuid.uuidString==self.kUUIDModelNameVariable  {
            
            if let data = characteristic.value {
                self.model = String(data:data, encoding: String.Encoding.utf8)
                AppDelegate.debugLog("Model : %@", self.model!)
            }
        }
        else if characteristic.uuid.uuidString==self.kUUIDSerialNumberVariable  {
            
            if let data = characteristic.value {
                self.serial = String(data:data, encoding: String.Encoding.utf8)
                AppDelegate.debugLog("Serial : %@", self.serial!)
            }
        }
        else if characteristic.uuid.uuidString==self.kUUIDHardwareVersion  {
            
            if let data = characteristic.value {
                self.hardwareVer = String(data:data, encoding: String.Encoding.utf8)
                AppDelegate.debugLog("Hardware Version : %@", self.hardwareVer!)
            }
        }
        else if characteristic.uuid.uuidString==self.kUUIDFirmwareVersion  {
            
            if let data = characteristic.value {
                self.firmwareVer = String(data:data, encoding: String.Encoding.utf8)
                AppDelegate.debugLog("Firmware Version : %@", self.firmwareVer!)
            }
        }
        else if characteristic.uuid.uuidString==self.kUUIDSoftwareVersion {
            
            if let data = characteristic.value {
                self.softwareVer = String(data:data, encoding: String.Encoding.utf8)
                AppDelegate.debugLog("Software Ver : %@", self.softwareVer!)
            }
        }
    }
}
