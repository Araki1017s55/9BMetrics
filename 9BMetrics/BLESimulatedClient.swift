//
//  BLESimulatedClient.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
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
import CoreMotion
import MapKit
import WatchConnectivity

class BLESimulatedClient: NSObject {
    
    static internal let kStartConnection = "startConnectinonNotification"
    static internal let kStoppedRecording = "stoppedRecordingNotification"
    static internal let kHeaderDataReadyNotification = "headerDataReadyNotification"
    static internal let kNinebotDataUpdatedNotification = "ninebotDataUpdatedNotification"
    static internal let kConnectionReadyNotification = "connectionReadyNotification"
    static internal let kConnectionLostNotification = "connectionLostNotification"
    static internal let kBluetoothManagerPoweredOnNotification = "bluetoothManagerPoweredOnNotification"
    static internal let kdevicesDiscoveredNotification = "devicesDiscoveredNotification"
    
    static internal let kLast9BDeviceAccessedKey = "9BDEVICE"
    
    
    // Ninebot control
    
    var datos : BLENinebot?
    var headersOk = false
    var sendTimer : NSTimer?    // Timer per enviar les dades periodicament
    var timerStep = 0.1        // Get data every step
    var watchTimerStep = 0.1        // Get data every step
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(50,2), (58,1),  (62, 1), (182, 5)]
   // var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4), (34,4), (71,6)]
   
    var listaOpFast :[(UInt8, UInt8)] = [(97,2), (188,2), (180,2)]

    
    var buffer = [UInt8]()
    
    // Altimeter data
    
    var altimeter : CMAltimeter?
    var altQueue : NSOperationQueue?
    var queryQueue : NSOperationQueue?
    
    // General State
    
    var scanning = false
    var connected = false
    var subscribed = false
    
    // Watch control
    
    var timer : NSTimer?
    var wcsession : WCSession?
    var sendToWatch = false
    var oldState : Dictionary<String, Double>?
    
    // Ninebot Connection
    
    var connection : BLEConnection
    
    // Location Manager
    
    var locm = CLLocationManager()
    var deferringUpdates = false
    var lastLoc : CLLocation?
    
    override init() {
        
        self.connection = BLEConnection()
        super.init()
        self.connection.delegate = self
        self.queryQueue = NSOperationQueue()
        self.queryQueue!.maxConcurrentOperationCount = 1
        
        locm.delegate = self
        locm.activityType = CLActivityType.Fitness
        locm.desiredAccuracy = kCLLocationAccuracyBest
        locm.distanceFilter = kCLDistanceFilterNone
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined
            || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.locm.requestAlwaysAuthorization()
            })
            
        }
        
        
        if WCSession.isSupported(){
            
            let session = WCSession.defaultSession()
            session.delegate = self
            session.activateSession()
            self.wcsession = session
            
            let paired = session.paired
            let installed = session.watchAppInstalled
            
            if paired {
                AppDelegate.debugLog("Session Paired")
                
            }
            
            if installed {
                AppDelegate.debugLog("Session Installed" )
            }
            
            if session.paired && session.watchAppInstalled{
                self.sendToWatch = true
            }
            
            
        }
    }
    
    func initNotifications()
    {
        //       NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("updateTitle:"), name: BLESimulatedClient.kHeaderDataReadyNotification, object: nil)
    }
    
    // Connect is the start connection
    //
    //  First it recovers if it exists a device and calls
    func connect(){
        
        // First we recover the last device and try to connect directly
        if self.connection.connecting || self.connection.subscribed{
            return
        }
        
        
        let store = NSUserDefaults.standardUserDefaults()
        let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let dev = device {
            self.connection.connectToDeviceWithUUID(dev)
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStartConnection, data:["status":"Connecting"] )
        }else{
            self.connection.startScanning()
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStartConnection, data:["status":"Scanning"])
        }
        
        // Start looking for GPS Data
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways{
        
            locm.allowsBackgroundLocationUpdates = true
            lastLoc = nil
            locm.startUpdatingLocation()
        }
        
    }
    
    func stop(){
        
        // First we disconnect the device
        
        if self.connection.connected{
            
            AppDelegate.debugLog("Stopping")
            
            
            self.connection.stopConnection()
            
            if let altm = self.altimeter{
                altm.stopRelativeAltitudeUpdates()
                self.altimeter = nil
            }
            
            locm.stopUpdatingLocation() // Haurem de modificar posteriorment
            locm.allowsBackgroundLocationUpdates = false
                
            
            // Now we save the file
            
            if let nb = self.datos where nb.data[BLENinebot.kCurrent].log.count > 0{
                nb.createTextFile()
            }
            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStoppedRecording, data: [:])
            
        }
        
        self.sendDataToWatch()
    }
    
    //MARK: Auxiliary functions
    
    
    class func sendNotification(notification: String, data:[NSObject : AnyObject]? ){
        
        let notification = NSNotification(name:notification, object:self, userInfo: data)
        NSNotificationCenter.defaultCenter().postNotification(notification)
        
    }
    
    
    func startAltimeter(){
        
        if CMAltimeter.isRelativeAltitudeAvailable(){
            if self.altimeter == nil{
                self.altimeter = CMAltimeter()
            }
            if self.altQueue == nil{
                self.altQueue = NSOperationQueue()
                self.altQueue!.maxConcurrentOperationCount = 1
            }
            
            
            if let altm = self.altimeter, queue = self.altQueue{
                
                altm.startRelativeAltitudeUpdatesToQueue(queue,
                                                         withHandler: { (alts : CMAltitudeData?, error : NSError?) -> Void in
                                                            
                                                            if let alt = alts, nb = self.datos {
                                                                nb.addValue(0, value: Int(round(alt.relativeAltitude.doubleValue * 100.0)))
                                                            }
                })
            }
        }
    }
    // MARK: NSOperationSupport
    
    func injectRequest(tim : NSTimer){
        self.sendNewRequest()
    }
    
    func sendNewRequest(){
        
        let request = BLERequestOperation(cliente: self)
        
        if let q = self.queryQueue{
            q.addOperation(request)
        }
    }
    
    
    //MARK: AppleWatch Support
    
    func getAppState() -> [String : Double]?{
        
        
        if let nb = self.datos{
            
            var dict  = [String : Double]()
            
            if self.connection.connected && self.connection.subscribed {
                dict["recording"] = 1.0
            }else {
                dict["recording"] = 0.0
            }
            
            dict["temps"] = nb.singleRuntime()
            dict["distancia"]  = nb.singleMileage()
            dict["speed"]  =  nb.speed()
            dict["battery"]  =  nb.batteryLevel()
            dict["remaining"]  =  nb.remainingMileage()
            dict["temperature"]  =  nb.temperature()
            
            let v = nb.speed()
            
            if v >= 18.0 && v < 20.0{
                dict["color"] = 1.0
            }else if v >= 20.0 {
                dict["color"] = 2.0
            }
            else{
                dict["color"] = 0.0
            }
            return dict
        }
        else {
            return nil
        }
        
    }
    
    func checkState(state_1 :[String : Double]?, state_2:[String : Double]?) -> Bool{
        
        if state_1 == nil && state_2 == nil {
            return true
        }
        else if state_1 == nil || state_2 == nil{
            return false
        }
        
        
        if let st1 = state_1, st2 = state_2 {
            
            if st1.count != st2.count {
                return false
            }
            
            for (k1, v1 ) in st1{
                
                let v2 = st2[k1]
                
                if let vv2 = v2 {
                    if vv2 != v1 {
                        return false
                    }
                }
                else
                {
                    return false
                }
            }
            return true
            
        }
        
        return false
    }
    
    func sendStateToWatch(timer: NSTimer){
        
        if self.sendToWatch{
            sendDataToWatch()
            
        }
    }
    
    func sendDataToWatch(){
        let info = self.getAppState()
        
        if !self.checkState(info, state_2: self.oldState){
            if let session = wcsession, inf = info {
                do {
                    try session.updateApplicationContext(inf)
                    self.oldState = info
                }
                catch _{
                    AppDelegate.debugLog("Error sending data to watch")
                }
            }
        }
    }
    
    // Sets limit speed in km/h
    
    func setLimitSpeed(speed : Double){
        // Check that level is between 0..9
        if speed < 0  {
            return
        }
        
        let speedm = Int(round(speed * 1000.0)) // speedm es la velocitat en m
        
        let b1 = UInt8(speedm / 256)
        let b0 = UInt8(speedm % 256)
        
        
        // That write riding level
        
        var message = BLENinebotMessage(commandToWrite: UInt8(BLENinebot.kSpeedLimit), dat:[b0, b1] )
        
        if let st = message?.toString(){
            AppDelegate.debugLog("Command : %@", st)
        }
        
        if let dat = message?.toNSData(){
            
            self.connection.writeValue(dat)
        }
        
        // Get value to see if it is OK
        
        message = BLENinebotMessage(com: UInt8(BLENinebot.kSpeedLimit), dat:[UInt8(2)] )
        
        if let dat = message?.toNSData(){
            self.connection.writeValue(dat)
        }
    }
    func setMaxSpeed(speed : Double){
        // Check that level is between 0..9
        if speed < 0  {
            return
        }
        
        let speedm = Int(round(speed * 1000.0)) // speedm es la velocitat en m
        
        let b1 = UInt8(speedm / 256)
        let b0 = UInt8(speedm % 256)
        
        
        // That write riding level
        
        var message = BLENinebotMessage(commandToWrite: UInt8(BLENinebot.kAbsoluteSpeedLimit), dat:[b0, b1] )
        
        if let st = message?.toString(){
            AppDelegate.debugLog("Command : %@", st)
        }
        
        if let dat = message?.toNSData(){
            
            self.connection.writeValue(dat)
        }
        
        // Get value to see if it is OK
        
        message = BLENinebotMessage(com: UInt8(BLENinebot.kAbsoluteSpeedLimit), dat:[UInt8(2)] )
        
        if let dat = message?.toNSData(){
            self.connection.writeValue(dat)
        }
    }
    
    
    func setRidingLevel(level : Int){
        
        // Check that level is between 0..9
        
        if level < 1 || level > 9 {
            return
        }
        
        
        // That write riding level
        
        var message = BLENinebotMessage(commandToWrite: UInt8(BLENinebot.kvRideMode), dat:[UInt8(level), UInt8(0)] )
        
        if let st = message?.toString(){
            AppDelegate.debugLog("Command : %@", st)
        }
        
        if let dat = message?.toNSData(){
            
            self.connection.writeValue(dat)
        }
        
        // Get value to see if it is OK
        
        message = BLENinebotMessage(com: UInt8(BLENinebot.kvRideMode), dat:[UInt8(2)] )
        
        if let dat = message?.toNSData(){
            self.connection.writeValue(dat)
        }
        
    }
    
    func sendData(){
        
        if let nb = self.datos {
            
            if nb.checkHeaders() {  // Get normal data
                
                if !self.headersOk {
                    self.headersOk = true
                    BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
                    
                }
                
                for (op, l) in listaOpFast{
                    let message = BLENinebotMessage(com: op, dat:[ l * 2] )
                    if let dat = message?.toNSData(){
                        self.connection.writeValue(dat)
                    }
                }
                
                let (op, l) = listaOp[contadorOp]
                contadorOp += 1
                
                if contadorOp >= listaOp.count{
                    contadorOp = 0
                }
                
                let message = BLENinebotMessage(com: op, dat:[ l * 2] )
                
                
                if let dat = message?.toNSData(){
                    self.connection.writeValue(dat)
                }
            }else {    // Get One time data (S/N, etc.)
                
                
                var message = BLENinebotMessage(com: UInt8(16), dat: [UInt8(22)])
                if let dat = message?.toNSData(){
                    self.connection.writeValue(dat)
                }
                
                // Get riding Level and max speeds
                
                message = BLENinebotMessage(com: UInt8(BLENinebot.kAbsoluteSpeedLimit), dat: [UInt8(4)])
                
                if let dat = message?.toNSData(){
                    self.connection.writeValue(dat)
                }
                
                message = BLENinebotMessage(com: UInt8(BLENinebot.kvRideMode), dat: [UInt8(2)])
                
                if let dat = message?.toNSData(){
                    self.connection.writeValue(dat)
                }
                
            }
        }
    }
    
    //MARK: Receiving Data
    
    func appendToBuffer(data : NSData){
        
        let count = data.length
        var buf = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buf, length:count * sizeof(UInt8))
        
        buffer.appendContentsOf(buf)
    }
    
    func procesaBuffer()
    {
        // Wait till header
        
        repeat {
            
            while buffer.count > 0 && buffer[0] != 0x55 {
                buffer.removeFirst()
            }
            
            // OK, ara hem de veure si el caracter següent es un aa
            
            if buffer.count < 2{    // Wait for more data
                return
            }
            
            if buffer[1] != 0xaa {  // Fals header. continue cleaning
                buffer.removeFirst()
                procesaBuffer()
                return
            }
            
            if buffer.count < 8 {   // Too small. Wait
                return
            }
            
            // Extract len and check size
            
            let l = Int(buffer[2])
            
            if l + 4 > 250 {
                buffer.removeFirst(3)
                return
            }
            
            if buffer.count < (6 + l){
                return
            }
            
            // OK ara ja podem extreure el block. Te len + 6 bytes
            
            let block = Array(buffer[0..<(l+6)])
            
            if let q = self.queryQueue where q.operationCount < 4{
                self.sendNewRequest()
            }
            let msg = BLENinebotMessage(buffer: block)
            
            if let m = msg {
                
                let d = m.interpret()
                
                var updated = false
                
                if let nb = self.datos{
                    
                    for (k, v) in d {
                        if k != 0{
                            let w = nb.data[k].value
                            if w != v{
                                updated = true
                            }
                            
                            nb.addValue(k, value: v)
                        }
                    }
                    
                    if updated{
                        BLESimulatedClient.sendNotification(BLESimulatedClient.kNinebotDataUpdatedNotification, data: nil)
                        
                        //let state = self.getAppState()
                        
                    }
                }
            }
            
            buffer.removeFirst(l+6)
            
        } while buffer.count > 6
    }
}

//MARK: BLENinebotConnectionDelegate

extension BLESimulatedClient : BLENinebotConnectionDelegate{
    
    func deviceConnected(peripheral : CBPeripheral ){
        
        
        self.startAltimeter()
        self.contadorOp = 0
        self.headersOk = false
        self.connected = true
        
        if let nb = self.datos{
            nb.clearAll()
            nb.firstDate = NSDate()
        }
        
        
        
        self.sendNewRequest()
        // Start timer for sending info to watch
        
        if self.sendToWatch {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(watchTimerStep, target: self, selector:#selector(BLESimulatedClient.sendStateToWatch(_:)), userInfo: nil, repeats: true)
        }
        
        // Just to be sure we start another timer to correct cases where we loose all requests
        // Will inject one request every timerStep
        
        self.sendTimer = NSTimer.scheduledTimerWithTimeInterval(timerStep, target: self, selector:#selector(BLESimulatedClient.injectRequest(_:)), userInfo: nil, repeats: true)
        
        
    }
    
    func deviceDisconnectedConnected(peripheral : CBPeripheral ){
        self.connected = false
        if let tim = self.sendTimer {
            tim.invalidate()
            self.sendTimer = nil
        }
        
        if let tim = self.timer {
            tim.invalidate()
            self.timer = nil
        }
        
        if let altm = self.altimeter{
            altm.stopRelativeAltitudeUpdates()
            self.altimeter = nil
        }
        
        
    }
    
    func charUpdated(char : CBCharacteristic, data: NSData){
        
        self.appendToBuffer(data)
        self.procesaBuffer()
    }
    
}

//MARK: WCSessionDelegate

extension BLESimulatedClient :  WCSessionDelegate{
    
    func sessionWatchStateDidChange(session: WCSession) {
        
        if session.paired && session.watchAppInstalled{
            self.sendToWatch = true
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector:#selector(BLESimulatedClient.sendStateToWatch(_:)), userInfo: nil, repeats: true)
            
        }
        else{
            self.sendToWatch = false
            if let tim = self.timer {
                tim.invalidate()
                self.timer = nil
            }
        }
    }
    
    func session(session: WCSession, didReceiveMessageData messageData: NSData) {
        
        
        // For the moment the watch just listens
    }
    
    //TODO: Move Watch Support to AppDelegate or ViewController.
    
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        if let op = message["op"] as? String{
            
            switch op {
                
            case "start":
                self.connect()
                
                
            case "stop" :
                self.stop()
                
            case "waypoint" :
                break
                
            default:
                NSLog("Op de Watch desconeguda", op)
            }
            
        }
    }
    
}

// CLLocationManagerDelegate

extension BLESimulatedClient : CLLocationManagerDelegate{
    
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus){
        
        AppDelegate.debugLog("Location Manager Authorization Status Changed")
        
        
    }
    
    func locationManager(manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        AppDelegate.debugLog("LocationManager received locations")
        
        if let nb = self.datos {
            
            for loc : CLLocation in locations {
                
                
                if loc.horizontalAccuracy <= 20.0{  // Other data is really bad bad bad. probably GPS not fixes
                    
                    if let llc = self.lastLoc{
                        if llc.distanceFromLocation(loc) >= 5.0{       // one point every 10 meters. Not less
                            
                            let lat : Int = Int(floor(loc.coordinate.latitude * 100000))
                            let lon : Int = Int(floor(loc.coordinate.longitude * 100000))
                            let alt : Int = Int(round(loc.altitude))
                            let speed : Int = Int(round(loc.speed) * 1000)
                            
                            nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kLatitude, value: lat, forced: true)
                            nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kLongitude, value: lon, forced: true)
                            nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kAltitudeGPS, value: alt, forced: true)
                            nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kSpeedGPS, value: speed, forced: true)
                           
                            self.lastLoc = loc
                        }
                    }
                    else
                    {
                        let lat : Int = Int(floor(loc.coordinate.latitude * 100000))
                        let lon : Int = Int(floor(loc.coordinate.longitude * 100000))
                        let alt : Int = Int(round(loc.altitude))
                        let speed : Int = Int(round(loc.speed) * 1000)
                        
                        nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kLatitude, value: lat, forced: true)
                        nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kLongitude, value: lon, forced: true)
                        nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kAltitudeGPS, value: alt, forced: true)
                        nb.addValueWithDate(loc.timestamp, variable: BLENinebot.kSpeedGPS, value: speed, forced: true)
                       self.lastLoc = loc
                    }
                }
            }
        }
        
        if !self.deferringUpdates  {
            let distance : CLLocationDistance =  1000.0 // Update every km
            let time : NSTimeInterval = 60.0 // Or every 1'
            
            manager.allowDeferredLocationUpdatesUntilTraveled(distance,  timeout:time)
            self.deferringUpdates = true
            
        }
    }
    
    
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        
        self.deferringUpdates = false
    }
    
    
    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    }
    
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    }
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
    }
    
    
    
    
}



