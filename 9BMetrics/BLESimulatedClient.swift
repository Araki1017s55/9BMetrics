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
    
    var datos : WheelTrack?
    var headersOk = false
    var sendTimer : Timer?    // Timer per enviar les dades periodicament
    var timerStep = 0.1        // Get data every step
    var watchTimerStep = 0.1        // Get data every step
    
    var gpsRefreshDistance = 100.0
    var gpsRefreshTime = 1.0
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(50,2), (58,1),  (62, 1), (182, 5)]
   // var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4), (34,4), (71,6)]
   
    var listaOpFast :[(UInt8, UInt8)] = [(97,2), (188,2), (180,2)]

    
    var buffer = [UInt8]()
    
    // Altimeter data
    
    var altimeter : CMAltimeter?
    var altQueue : OperationQueue?
    var queryQueue : OperationQueue?
    var watchQueue : OperationQueue?
    
    // General State
    
    var scanning = false
    var connected = false
    var subscribed = false
    
    // Watch control
    
    var timer : Timer?
    var wcsession : WCSession?
    var sendToWatch = false
    var oldState : Dictionary<String, Double>?
    
    var lastWatchUpdate = Date()
    
    // Ninebot Connection
    
    var connection : BLEMimConnection
    
    // Location Manager
    
    var locm = CLLocationManager()
    var deferringUpdates = false
    var lastLoc : CLLocation?
    var distanceGPS = 0.0
    
    var adapter : BLEWheelAdapterProtocol?
    
    override init() {
        
        self.connection = BLEMimConnection()
        super.init()
        self.connection.delegate = self
        self.queryQueue = OperationQueue()
        self.queryQueue!.maxConcurrentOperationCount = 1
       // self.watchQueue = OperationQueue()
       // self.watchQueue!.maxConcurrentOperationCount = 1
        
        
        self.initNotifications()
        
        locm.delegate = self
        locm.activityType = CLActivityType.fitness
        locm.desiredAccuracy = kCLLocationAccuracyBest
        locm.distanceFilter = kCLDistanceFilterNone
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined
            || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied {
            DispatchQueue.main.async(execute: { () -> Void in
                
                self.locm.requestAlwaysAuthorization()
            })
            
        }
        
        
        if WCSession.isSupported(){
            
            let session = WCSession.default()
            session.delegate = self
            session.activate()
            self.wcsession = session
            
            let paired = session.isPaired
            let installed = session.isWatchAppInstalled
            
            if paired {
                AppDelegate.debugLog("Session Paired")
                
            }
            
            if installed {
                AppDelegate.debugLog("Session Installed" )
            }
            
            if session.isPaired && session.isWatchAppInstalled{
                self.sendToWatch = true
            }
            
            
        }
    }
    
    func initNotifications()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(BLESimulatedClient.updateTitle(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kHeaderDataReadyNotification), object: nil)
    }
    
    // Connect is the start connection
    //
    //  First it recovers if it exists a device and calls
    func connect(){
        
        self.adapter = nil

        if let nb = self.datos{
            nb.clearAll()
        }

        
        // First we recover the last device and try to connect directly
        if self.connection.connecting || self.connection.subscribed{
            return
        }
        
        
        let store = UserDefaults.standard
        let device = store.string(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let dev = device {
            self.connection.connectToDeviceWithUUID(dev)
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStartConnection, data:["status":"Connecting"] )
        }else{
            self.connection.startScanning()
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStartConnection, data:["status":"Scanning"])
        }
        
        // Start looking for GPS Data
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways{
        
            locm.allowsBackgroundLocationUpdates = true
            lastLoc = nil
            distanceGPS = 0.0
            locm.startUpdatingLocation()
        }
        
        UIApplication.shared.isIdleTimerDisabled = store.bool(forKey: kBlockSleepMode)
    }
    
    func stop(){
        
        // First we disconnect the device
        
        UIApplication.shared.isIdleTimerDisabled = false     // Restore sleep mode
        if self.connection.connected{
            
            AppDelegate.debugLog("Stopping")
            
            
            self.connection.stopConnection()
            
            if let adp = self.adapter {
                adp.stopRecording()
            }
            
            if let altm = self.altimeter{
                altm.stopRelativeAltitudeUpdates()
                self.altimeter = nil
            }
            
            locm.stopUpdatingLocation() // Haurem de modificar posteriorment
            locm.allowsBackgroundLocationUpdates = false
            
            // Now we save the file
            
            if let nb = self.datos , nb.hasData(){
                
                let ldateFormatter = DateFormatter()
                let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
                
                ldateFormatter.locale = enUSPOSIXLocale
                let name : String
                
                ldateFormatter.dateFormat = "yyyyMMdd'_'HHmmss"
                if let date = nb.firstDate{
                    name = ldateFormatter.string(from: date as Date)
                }else{
                    name = ldateFormatter.string(from: Date())
                }

                
                _ = nb.createPackage(name)
            }
            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kStoppedRecording, data: [:])
            
        }
        self.adapter = nil
      
        if let info = getAppState(){
            self.sendDataToWatch(info)
        }
    }
    
    //MARK: Auxiliary functions
    
    
    class func sendNotification(_ notification: String, data:[AnyHashable: Any]? ){
        
        let notification = Notification(name:Notification.Name(rawValue: notification), object:self, userInfo: data)
        NotificationCenter.default.post(notification)
        
    }
    
    func updateTitle(_ not: Notification){
        
        if let wheel = datos, let adp = adapter {
            wheel.setName(adp.getName())
            wheel.setSerialNo(adp.getSN())
            wheel.setVersion(adp.getVersion())
            wheel.setAdapter(adp.wheelName())
        }
     }
    
    
    func startAltimeter(){
        
        if CMAltimeter.isRelativeAltitudeAvailable(){
            if self.altimeter == nil{
                self.altimeter = CMAltimeter()
            }
            if self.altQueue == nil{
                self.altQueue = OperationQueue()
                self.altQueue!.maxConcurrentOperationCount = 1
            }
            
            
            if let altm = self.altimeter, let queue = self.altQueue{
                
                altm.startRelativeAltitudeUpdates(to: queue,
                                                         withHandler: { (alts : CMAltitudeData?, error : Error?) -> Void in
                                                            
                                                            if let alt = alts, let nb = self.datos {
                                                                nb.addValue(.Altitude, value: alt.relativeAltitude.doubleValue)
                                                                if let adp = self.adapter {
                                                                    adp.giveTime(self.connection)
                                                                }

                                                            }
                } )
            }
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
            
            dict["temps"] = nb.getCurrentValueForVariable(.Duration)
            dict["distancia"]  = nb.getCurrentValueForVariable(.Distance)
            dict["speed"]  = nb.getCurrentValueForVariable(.Speed) * 3.6
            dict["battery"]  =  nb.getCurrentValueForVariable(.Battery)
            dict["remaining"]  =  0.0
            dict["temperature"]  =  nb.getCurrentValueForVariable(.Temperature)
            
            let v =  nb.getCurrentValueForVariable(.Speed) * 3.6
            
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
    
    func checkState(_ state_1 :[String : Double]?, state_2:[String : Double]?) -> Bool{
        
        if state_1 == nil && state_2 == nil {
            return true
        }
        else if state_1 == nil || state_2 == nil{
            return false
        }
        
        
        if let st1 = state_1, let st2 = state_2 {
            
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
    
    func sendStateToWatch(_ timer: Timer){
        
        self.doSendStateToWatch()
        
    }
    
    func doSendStateToWatch(){
        DispatchQueue.global().async( execute: {
            if #available(iOS 9.3, *) {     // A veure si així es una mica mes ràpid. Potser enviar coses quan no es activa li feia mal
                if let session = self.wcsession , session.activationState == .activated {
                    if self.sendToWatch {
                        if let info = self.getAppState(){
                            self.sendDataToWatch(info)
                        }
                    }
                }
            } else {
                if self.sendToWatch {
                    
                    if let info = self.getAppState(){
                        self.sendDataToWatch(info)
                    }
                    
                }
            }
        });
        
    }
    
    func olddoSendStateToWatch() {
    
        if let queue = watchQueue{
            
            queue.addOperation({ 
                if #available(iOS 9.3, *) {     // A veure si així es una mica mes ràpid. Potser enviar coses quan no es activa li feia mal
                    if let session = self.wcsession , session.activationState == .activated {
                        if self.sendToWatch {
                            if let info = self.getAppState(){
                                self.sendDataToWatch(info)
                            }
                        }
                    }
                } else {
                    if self.sendToWatch {
                        
                        if let info = self.getAppState(){
                            self.sendDataToWatch(info)
                        }
                        
                    }
                }
            })
            
        }
     }
    
    func sendDataToWatch(_ info : [String : Double]){
        
        if !self.checkState(info, state_2: self.oldState){
            if let session = wcsession{
                do {
                    self.lastWatchUpdate = Date()
                    try session.updateApplicationContext(info)
                    self.oldState = info
                }
                catch _{
                    AppDelegate.debugLog("Error sending data to watch")
                }
            }
        }
    }
 
    func sendDataToWatchMessage(){
        let info = self.getAppState()
        
        if !self.checkState(info, state_2: self.oldState){
            if let session = wcsession, let inf = info {
               
                    session.sendMessage(inf, replyHandler: nil, errorHandler: nil)
                     self.oldState = info
            }
        }
    }

    //MARK: Ninebot specific test functions. Should go to the adapter if generalised
    
    // setSerialNumber is a test function specific of Ninebot. Not to use in release
    func setSerialNumber(_ sn : String){
        
        if let dat = sn.data(using: String.Encoding.utf8){
            
            let count = dat.count / MemoryLayout<UInt8>.size
            var array = [UInt8](repeating: 0, count: count)
            (dat as NSData).getBytes(&array, length: count * MemoryLayout<UInt8>.size)
            var message = BLENinebotMessage(commandToWrite: UInt8(16), dat:array )
 
        
            if let st = message?.toString(){
                AppDelegate.debugLog("Command : %@", st)
            }
            
            if let dat = message?.toNSData(){
                self.connection.writeValue("FFE1", data: dat)
                //self.connection.writeValue(dat)
            }
          
            message = BLENinebotMessage(com: UInt8(16), dat:[UInt8(14)] )
            
            if let dat = message?.toNSData(){
                self.connection.writeValue("FFE1", data:dat)
            }
            
            
            message = BLENinebotMessage(com: UInt8(27), dat:[UInt8(14)] )
            
            if let dat = message?.toNSData(){
                self.connection.writeValue("FFE1", data:dat)
            }

        }
        
        
    }
    // Sets limit speed in km/h
    // setLimitSpeed is a test function specific of Ninebot. Not to use in release
   
    func setLimitSpeed(_ speed : Double){
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
            
            self.connection.writeValue("FFE1", data:dat)
        }
        
        // Get value to see if it is OK
        
        message = BLENinebotMessage(com: UInt8(BLENinebot.kSpeedLimit), dat:[UInt8(2)] )
        
        if let dat = message?.toNSData(){
            self.connection.writeValue("FFE1", data:dat)
        }
    }
    
    // setMaxSpeed is a test function specific of Ninebot. Not to use in release
    func setMaxSpeed(_ speed : Double){
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
            
            self.connection.writeValue("FFE1", data:dat)
        }
        
        // Get value to see if it is OK
        
        message = BLENinebotMessage(com: UInt8(BLENinebot.kAbsoluteSpeedLimit), dat:[UInt8(2)] )
        
        if let dat = message?.toNSData(){
            self.connection.writeValue("FFE1", data:dat)
        }
    }
    
    // setRidingLevel is a test function specific of Ninebot. Not to use in release
    func setRidingLevel(_ level : Int){
        
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
            
            self.connection.writeValue("FFE1", data:dat)
        }
        
        // Get value to see if it is OK
        
        message = BLENinebotMessage(com: UInt8(BLENinebot.kvRideMode), dat:[UInt8(2)] )
        
        if let dat = message?.toNSData(){
            self.connection.writeValue("FFE1", data:dat)
        }
        
    }
    

    
}
//MARK: BLENMimConnectionDelegate

extension BLESimulatedClient : BLEMimConnectionDelegate{
    internal func deviceAnalyzed(_ peripheral: CBPeripheral, services: [String : BLEService]) {
        // Don't do anything for the moment.
    }

    
    func deviceConnected(_ peripheral : CBPeripheral, adapter: BLEWheelAdapterProtocol? ){
        
        if let adp = self.adapter {
            adp.deviceConnected(self.connection, peripheral: peripheral)
        
        } else if let newAdp = adapter{
            
            self.adapter = newAdp
            if let adp = self.adapter {
                if let dat = datos {
                    dat.setUUID(peripheral.identifier.uuidString)
                }
                adp.startRecording()
                adp.deviceConnected(self.connection, peripheral: peripheral)
            }
        } else { // There is bi adapter, I can't interpret data!!!
            let deleg = UIApplication.shared.delegate as! AppDelegate
            deleg.displayMessageWithTitle("No driver available".localized()   , format: "I don't have a driver for this device".localized())
            AppDelegate.debugLog("I don't have a driver to connect to his device.")

            return
        }
        
        
        self.startAltimeter()
        self.connected = true
         
        if self.sendToWatch {
            if let tim = self.timer{
                tim.invalidate()
            }
            //self.timer = Timer.scheduledTimer(timeInterval: watchTimerStep, target: self, selector:#selector(BLESimulatedClient.sendStateToWatch(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func deviceDisconnected(_ peripheral : CBPeripheral ){

        if let adp = self.adapter {
            adp.deviceDisconnected(self.connection, peripheral: peripheral)
        }
        self.connected = false
        
        if let tim = self.timer {
            tim.invalidate()
            self.timer = nil
        }
        
        if let altm = self.altimeter{
            altm.stopRelativeAltitudeUpdates()
            self.altimeter = nil
        }
    }
    
    func charUpdated(_ char : CBCharacteristic, data: Data){
        if let adp = self.adapter {
            if let newData = adp.charUpdated(self.connection, char: char, data: data), let wheel = self.datos{
                
                var addPower = false
                var curDate = Date()
                
                for (vari, date, val) in newData {
                    //AppDelegate.debugLog("%@ = %@", vari.rawValue , val)
                    wheel.addValueWithDate(date, variable: vari, value: val)
                    if vari == .Current {
                        addPower = true
                        curDate = date
                    }
                }
                
                // Now there is the posibility that we must compute new values for Power and Energy
                
                if addPower{
                    let power = wheel.getCurrentValueForVariable(.Current) * wheel.getCurrentValueForVariable(.Voltage)
                    
                    // OK now energy = power * dt
                    
                    let dt = wheel.getTimeIntervalForVariable(.Energy, toDate : curDate)
                    let dE = dt * power     // Energy
                    let E = wheel.getCurrentValueForVariable(.Energy) + dE
                    
                    wheel.addValueWithDate(curDate, variable: .Power, value: power)
                    wheel.addValueWithDate(curDate, variable: .Energy, value: E)
                
                }
                
                if Date().timeIntervalSince(self.lastWatchUpdate) > watchTimerStep {
                    self.doSendStateToWatch()
                }

            }
        }
    }
}

//MARK: WCSessionDelegate

extension BLESimulatedClient :  WCSessionDelegate{
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        self.sendToWatch = true
     }
    
    
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
        self.sendToWatch = false
    }
    
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {
        
        
    }

    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
   
    
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        
        
        if session.isPaired && session.isWatchAppInstalled {
            self.sendToWatch = true
            //self.timer = Timer.scheduledTimer(timeInterval: self.watchTimerStep, target: self, selector:#selector(BLESimulatedClient.sendStateToWatch(_:)), userInfo: nil, repeats: true)
            
        }
        else{
            self.sendToWatch = false
            if let tim = self.timer {
                tim.invalidate()
                self.timer = nil
            }
        }
    }
    
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
        
        // For the moment the watch just listens
    }
    
    //TODO: Move Watch Support to AppDelegate or ViewController.
    
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let op = message["op"] as? String{
            
            switch op {
                
            case "start":
                self.connect()
                
                
            case "stop" :
                self.stop()
                
            case "waypoint" :
                break
                
            default:
                AppDelegate.debugLog("Op de Watch desconeguda", op)
            }
            
        }
    }
    
}

// CLLocationManagerDelegate

extension BLESimulatedClient : CLLocationManagerDelegate{
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        
        AppDelegate.debugLog("Location Manager Authorization Status Changed")
        
        
    }
    
    // As v. 2.3 added code to compute distance from GPS. That gives us a .DistaceGPS variable.
    // It will be used to compute a correction factor for wheel distance and speed
    // Generally shoud work well
    
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        AppDelegate.debugLog("LocationManager received locations")
        
        if let nb = self.datos {
            
            for loc : CLLocation in locations {
                
                
                if loc.horizontalAccuracy <= 20.0{  // Other data is really bad bad bad. probably GPS not fixed
                    
                    if let llc = self.lastLoc{
                        if llc.distance(from: loc) >= 2.0{       // one point every 2 meters. Not less
                            
                            nb.addValueWithDate(loc.timestamp, variable: .Latitude, value: loc.coordinate.latitude, forced: true, silent: false)
                            nb.addValueWithDate(loc.timestamp, variable: .Longitude, value: loc.coordinate.longitude, forced: true, silent: false)
                            nb.addValueWithDate(loc.timestamp, variable: .AltitudeGPS, value: loc.altitude, forced: true, silent: false)
                            
                            let d = loc.distance(from: llc)
                            distanceGPS += d
                            
                            nb.addValueWithDate(loc.timestamp, variable: .DistanceGPS, value: distanceGPS, forced: true, silent: false)
                            self.lastLoc = loc
                            
                            //nb.computeDistanceCorrection()
                        }
                    }
                    else
                    {
                        
                        nb.addValueWithDate(loc.timestamp, variable: .Latitude, value: loc.coordinate.latitude, forced: true, silent: false)
                        nb.addValueWithDate(loc.timestamp, variable: .Longitude, value: loc.coordinate.longitude, forced: true, silent: false)
                        nb.addValueWithDate(loc.timestamp, variable: .AltitudeGPS, value: loc.altitude, forced: true, silent: false)
                        
                        distanceGPS = 0.0
                        nb.addValueWithDate(loc.timestamp, variable: .DistanceGPS, value: distanceGPS, forced: true, silent: false)

                        self.lastLoc = loc
                        nb.computeDistanceCorrection()
                    }
                }
            }
            
            if let adp = self.adapter {
                adp.giveTime(self.connection)
            }
            if Date().timeIntervalSince(self.lastWatchUpdate) > watchTimerStep {
                self.doSendStateToWatch()
            }
        }
        
        if !self.deferringUpdates  {
            let distance : CLLocationDistance =  self.gpsRefreshDistance // Update every km
            let time : TimeInterval = self.gpsRefreshTime // Or every 1'
            
            manager.allowDeferredLocationUpdates(untilTraveled: distance,  timeout:time)
            self.deferringUpdates = true
            
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        
        self.deferringUpdates = false
    }
    
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    }
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    }
    
}



