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

/**
 - author: Francisco Gorina
 - copyright: ©2016 by Francisco Gorina
 - date: 12/02/16
 - version: 2.6

 Represents a BLEService with easy to use data. 
 done is a flag uses to mark that characteristics have been read from the device
 */
struct BLEService {
    var id : String = ""
    var characteristics : [String : BLECharacteristic] = [:]
    var service : CBService?
    var done = false
    
}

/**
 - author: Francisco Gorina
 - copyright: ©2016 by Francisco Gorina
 - date: 12/02/16
 - version: 2.6
 
 Represents a BLECharacteristic with easy to use data.

 *flags* are a read/write/subscribing/indicate flags in string format
 */
struct BLECharacteristic {
    var service : String
    var id : String
    var flags : String
    var characteristic : CBCharacteristic?
    
    
}
/**
 
    - author: Francisco Gorina
    - copyright: ©2016 by Francisco Gorina
    - date: 12/02/16
    - version: 2.6
 
 BLEMimConnection is the main Bluetooth Intetface hiding all Bluetooth complexity from the application.
 
 It supports :
    
    - Scanning for getting nearby devices
    - Connecting to a device and getting all services and characteristics
    - Selecting the apropiate Wheel Adapter from this information
    - Reading, Writing and Subscribing
    - Handling disconnections anbd automatic reconnects
    - Disconnecting the connection
 
 BLEMimConnection talks with the rest of the program through two methods:
 
    - Using the delegate (BLEMimConnectionDelegate protocol)
    - Through Notifications
 
## Delegate
 
 Must support the BLEMimConnectionDelegate methods which are called when :
 
 - *deviceAnalyzed* is called when a device has been fully analyzed (all services and characteristics read)
 - *deviceConnected* is called when the connection is done and an adapter is selected
 - *deviceDisconnected* is called when the Bluetooth connection is lost. Will try to reconnect automatically
 - *charUpdated* when data is received with an update from the subscribed or read characteristics
 
 
## Notifications
 
 BLEMimConnection sends some notifications to comunicate with other modules. The idea is that the User Interface classes may subscribe and present state in a simple way.
 
- *kBluetoothManagerPoweredOnNotification* is sent when Central manager is Powered On i estem conectant. De moment ningú ho fa servir.
- *kDevicesDiscoveredNotification* is called when new devices are discovered, either the connected ones or new ones.
 
    Is used by BLEDeviceSelector to update the list when new devices appear.
 
    Is used by Dashboards to add devices to the initial device list and open the Device Selector.
 
    Now they also add to the selector but probably may be removed as they are removed as listeners when the selector opens over them.
 
    It is received by BLEMim which uses it the same way as Dashboards.
 
 - *kConnectionLostNotification* is sent when connection is lost. Usually a terminal lost that is not recovered.
 
 - *kStartConnecting*  is sent when trying to reconnect.
 
    It is sent also by BLESimulatedCLient when starting a new recording (start).
 
    It is received by Dashboards to Start Animation.
 
    It is received in ViewController but is legacy that must be removed.
 
 
 
 */
class BLEMimConnection: NSObject, CBCentralManagerDelegate  {
    
    
    /**
        ConnectionState represents the state of the connection. values are
 
     - *disconnected* just sits idling
     - *scanning* scanning is started and the connection waits for discovered devices
     - *connecting* conection to a device has been started and waiting for it to respond and read all services and characteristics to analyze the device
     - *connected* the device has been identified and an adapter has been instantiated
 
 */
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
    
    /**
     
     Starts connection to a device represented as an UUID String
     
    - parameters:
        - device: String with the uuid of the device to connect to
    */
    func connectToUUID(_ device : String){
        
        if state == .scanning{
            stopScanning()
        }
        
        state = .connecting
        uuidToConnect = device
        connectToDeviceWithUUID(device)
        
    }
    
    /**
     
     Disconnects from the current device
     */
    
    func disconnect(){
        
        self.stopConnection()

    }
    
    
    /**
     
     Starts scanning for devices
     
     */
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
    
    /**
     
     Stops scanning for devices
     
     */
    func stopScanning(){
        
        if state == .scanning {
            if let mgr = self.centralManager {
                mgr.stopScan()
            }
            
        }
        state = .disconnected

    }
    
    
    //MARK: Exchanging data
    
    
    /**
     
     Subscribes to a characteristic identified by a String UUID. First lookups in its database all the details
     
     - parameters:
        - char: String with the UUID of the characteristic to connect
     
     */
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
    
    /**
     
     Removes the subscription to a characteristic identified by a String UUID. First lookups in its database all the details
     
     - parameters:
        - char: String with the UUID of the characteristic to disconnect
     
     */
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
    
    /**
     
     Writed the Data to the characteristic identified by a UUID String
     
     - parameters:
        - char: String with the UUID of the characteristic to write to
     
        - data: Value to write
     
     */
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
