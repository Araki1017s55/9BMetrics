//
//  BLENinebotOneAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
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

import Foundation
import CoreBluetooth
import GyrometricsDataModel

class BLENinebotOneAdapter : NSObject, BLEWheelAdapterProtocol {
    
    static let kAltitude = 0        // Obte les dades de CMAltimeterManager. 0 es l'inici i serveix per variacions unicament
    static let kPower = 1           // Calculada com V * I
    static let kEnergy = 2          // Total Energy = Integral (Power, dt)
    static let kLatitude = 3          // Latitut del GPS * 100000
    static let kLongitude = 4          // Longitut dek GPS * 100000
    static let kAltitudeGPS = 5          // Altitut GPS en m
    static let kSpeedGPS = 6          // Velocitat del GPS * 1000 (m/s * 1000)
    static let kSerialNo = 16       // 16-22
    static let kPinCode = 23        // 23-25
    static let kVersion = 26
    static let kError = 27
    static let kWarn = 28
    static let kWorkMode = 31
    static let kvPowerRemaining = 34
    static let kRemainingDistance = 37
    static let kvSpeed = 38
    static let kvTotalMileage0 = 41
    static let kvTotalMileage1 = 42
    static let kTotalRuntime0 = 50
    static let kTotalRuntime1 = 51
    static let kSingleRuntime = 58
    static let kTemperature = 62
    static let kvDriveVoltage = 71
    static let kElectricVoltage12v = 74
    static let kvCurrent = 80
    static let kPitchAngle = 97
    static let kRollAngle = 98
    static let kPitchAngleVelocity = 99
    static let kRollAngleVelocity = 100
    static let kLockWheel = 112
    static let kEnableSpeedLimit = 114
    static let kAbsoluteSpeedLimit = 115
    static let kSpeedLimit = 116
    
    static let kvCodeError = 176
    static let kvCodeWarning = 177
    static let kvFlags = 178
    static let kvWorkMode = 179
    static let kBattery = 180
    static let kCurrentSpeed = 181
    static let kvAverageSpeed = 182
    static let kTotalMileage0 = 183
    static let kTotalMileage1 = 184
    static let kvSingleMileage = 185
    static let kvTemperature = 187
    static let kVoltage = 188
    static let kCurrent = 189
    static let kvPitchAngle = 190
    static let kvMaxSpeed = 191
    static let kvRideMode = 210

    
    var headersOk = false
    var sendTimer : Timer?    // Timer per enviar les dades periodicament
    var timerStep = 0.1        // Get data every step
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(50,2), (58,1),  (62, 1), (182, 5)]
    // var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4), (34,4), (71,6)]
    
    var listaOpFast :[(UInt8, UInt8)] = [(97,2), (188,2), (180,5)]
    
    var buffer = [UInt8]()
    
    var queryQueue : OperationQueue?
    
    var lastConnection : BLEMimConnection?
    
    var wheel : Wheel?
    
    static var conversion = Array<WheelTrack.WheelValue?>(repeating: nil, count: 256)
    static var scales = Array<Double>(repeating: 1.0, count: 256)
    static var signed = [Bool](repeating: false, count: 256)
    
    var values : [Int] = Array(repeating: -1, count: 256)
    
    var name : String = "Ninebot"
    
    var sending : Bool = false
    
    var startDistance : Double?
    
    var writeChar = "FFE1"
    var readChar = "FFE1"
    var fixed : UInt8 = 0x09
    
    // Called when lost connection. perhaps should do something. If not forget it
    
    
    // Data Received. Analyze, extract, convert and prosibly return a dictionary of characteristics and values
    
    
    // Called by connection when we got device characteristics
    
    override init(){
        super.init()
        queryQueue = OperationQueue()
        queryQueue!.maxConcurrentOperationCount = 1
        
        BLENinebotOneAdapter.initConversion()
        
    }
    
    static func initConversion(){
        
        conversion[kAltitude] = WheelTrack.WheelValue.Altitude
        conversion[kPower] = WheelTrack.WheelValue.Power
        conversion[kEnergy] = WheelTrack.WheelValue.Energy
        conversion[kLatitude] = WheelTrack.WheelValue.Latitude
        conversion[kLongitude] = WheelTrack.WheelValue.Longitude
        conversion[kAltitudeGPS] = WheelTrack.WheelValue.AltitudeGPS
        conversion[kvPowerRemaining] = WheelTrack.WheelValue.Battery
        conversion[kvSpeed] = WheelTrack.WheelValue.Speed
        conversion[kSingleRuntime] = WheelTrack.WheelValue.Duration
        conversion[kTemperature] = WheelTrack.WheelValue.Temperature
        conversion[kvDriveVoltage] = WheelTrack.WheelValue.Voltage
        conversion[kvCurrent] = WheelTrack.WheelValue.Current
        conversion[kPitchAngle] = WheelTrack.WheelValue.Pitch
        conversion[kRollAngle] = WheelTrack.WheelValue.Roll
        conversion[kAbsoluteSpeedLimit] = WheelTrack.WheelValue.MaxSpeed
        conversion[kSpeedLimit] = WheelTrack.WheelValue.LimitSpeed
        conversion[kBattery] = WheelTrack.WheelValue.Battery
        conversion[kCurrentSpeed] = WheelTrack.WheelValue.Speed
        conversion[kvSingleMileage] = WheelTrack.WheelValue.Distance
        conversion[kvTemperature] = WheelTrack.WheelValue.Temperature
        conversion[kVoltage] = WheelTrack.WheelValue.Voltage
        conversion[kCurrent] = WheelTrack.WheelValue.Current
        conversion[kvPitchAngle] = WheelTrack.WheelValue.Pitch
        conversion[kvMaxSpeed] = WheelTrack.WheelValue.MaxSpeed
        conversion[kvRideMode] = WheelTrack.WheelValue.RidingLevel
        conversion[kEnableSpeedLimit] = WheelTrack.WheelValue.limitSpeedEnabled
        conversion[kLockWheel] = WheelTrack.WheelValue.lockEnabled
       
        
        scales[kvSpeed] = 1.0 / 3600.0
        scales[kTemperature] = 0.1
        scales[kvDriveVoltage] = 0.01
        scales[kvCurrent] = 0.01
        scales[kPitchAngle] = 0.01
        scales[kRollAngle] = 0.01
        scales[kAbsoluteSpeedLimit] = 1.0 / 3600.0
        scales[kSpeedLimit] = 1.0 / 3600.0
        scales[kCurrentSpeed] = 1.0 / 3600.0
        scales[kvSingleMileage] = 10.0
        scales[kvTemperature] = 0.1
        scales[kVoltage] = 0.01
        scales[kCurrent] = 0.01
        scales[kvPitchAngle] = 0.01
        scales[kvMaxSpeed] = 1.0 / 3600.0
        
        signed[kPitchAngle] = true
        signed[kRollAngle] = true
        signed[kPitchAngleVelocity] = true
        signed[kRollAngleVelocity] = true
        signed[kCurrent] = true
        signed[kvPitchAngle] = true
        
    }
    
    //MARK: Receiving Data. Append data to buffer
    
    func appendToBuffer(_ data : Data){
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        
        buffer.append(contentsOf: buf)
    }
    
    // Here we process received information.
    // We maintain a buffer (buffer) and data is appended in appendToBuffer
    // as each block is received. Logical Data may span more than one block and not be aligned.
    //
    //
    //  So we call procesaBuffer to extract any posible data. It is returned as an array of
    //  3 values, the variable, the date and the value all aready converted to ggeneric values
    // and SI units
    
    
    func procesaBuffer(_ connection: BLEMimConnection) -> [(WheelTrack.WheelValue, Date, Double)]?
    {
        // Wait till header. We wait till we find a 0x55
        
        var outarr : [(WheelTrack.WheelValue, Date, Double)]?
        
        repeat {
            
            while buffer.count > 0 && buffer[0] != 0x55 {
                buffer.removeFirst()
            }
            
            // Following character must be 0xaa, if not is noise
            
            
            if buffer.count < 2{    // Wait for more data
                return outarr
            }
            
            if buffer[1] != 0xaa {  // Fals header. continue cleaning
                buffer.removeFirst()
                if outarr == nil {
                    outarr = []
                }
                if let  moreData = procesaBuffer(connection){
                    outarr!.append(contentsOf: moreData)
                }
                
                return outarr
            }
            
            if buffer.count < 8 {   // Too small. Wait
                return outarr
            }
            
            // Extract len and check size
            
            let l = Int(buffer[2])
            
            if l + 4 > 250 {
                buffer.removeFirst(3)
                return outarr
            }
            
            if buffer.count < (6 + l){
                return outarr
            }
            
            // OK ara ja podem extreure el block. Te len + 6 bytes
            
            let block = Array(buffer[0..<(l+6)])
            
            if let q = self.queryQueue , q.operationCount < 4{
                self.sendNewRequest(connection)
            }
            
            // BLENinebotMessage interprets a logical block of information
            
            let msg = BLENinebotMessage(buffer: block , fixed: fixed)
            
            if let m = msg {
                
                // Here we do the actual interpretation and convert byte values to variable/value
                
                let d = m.interpret()
                
                for (k, v) in d {
                    if k != 0{
                        
                        if outarr == nil{
                            outarr = []
                        }
                        
                        values[k] = v   // Will use current value for checkHeaders
                        
                        var sv = v
                        
                        // Treat signed values
                        
                        if BLENinebotOneAdapter.signed[k]{
                            if v >= 32768 {
                                sv = v - 65536
                            }
                        }
                        
                        
                        //TODO: Verify that conversion is OK. First treat two Ninebot variables
                        // For the moment not found any value
                        
                        if k == BLENinebotOneAdapter.kError{
                            AppDelegate.debugLog("Error %d ", v)
                        }else if k == BLENinebotOneAdapter.kWarn{
                            AppDelegate.debugLog("Warning %d", v)
                        }
                        // Convert to SI by an scale and assign to generic variable
                        
                        

                        var dv = Double(sv) * BLENinebotOneAdapter.scales[k]

                        if let wv = BLENinebotOneAdapter.conversion[k]{
                            
                            if wv == .Distance{
                                if let sd = startDistance{
                                    dv = dv - sd
                                }else {
                                    startDistance = dv
                                    dv = 0.0
                                }
                            }
                            outarr!.append((wv, Date(), dv))
                            
                        }
                        
                    }
                    
                   }
                // Check special case for total distance
                
                if let v0 = d[BLENinebotOneAdapter.kTotalMileage0], let v1 = d[BLENinebotOneAdapter.kTotalMileage1]{
                    
                    let total = Double(v1) * 65536.0 + Double(v0)
                    outarr!.append(WheelTrack.WheelValue.AcumDistance, Date(), total)
                }
                
                
                // Checkheaders is used to know if we have already received static information
                // That is asked at the beginning, as the model, serial number...
                _ = checkHeaders()
                
            }
            
            buffer.removeFirst(l+6)
            
        } while buffer.count > 6
        return outarr
    }
    
    func checkHeaders() -> Bool{
        
        if headersOk {
            return true
        }
        
        var filled = true
        
        for i in 16..<27 {
            if values[i] == -1{
                filled = false
            }
        }
        
        if values[BLENinebotOneAdapter.kSpeedLimit] == -1{
            filled = false
        }
        
        if values[BLENinebotOneAdapter.kAbsoluteSpeedLimit] == -1{
            filled = false
        }
        
        if values[BLENinebotOneAdapter.kvRideMode] == -1{
            filled = false
        }
        
        
        
        headersOk = filled
        
        if headersOk {  // Notify the world we have all the data :)
            
            if let wh = self.wheel {    // Update wheel data
                
                let db = WheelDatabase.sharedInstance
                
                wh.model = getModel()
                wh.serialNo = getSN()
                wh.version = getVersion()
                wh.maxSpeed = getMaxSpeed()
                
                db.setWheel(wheel: wh)
                
            }

            
            BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
        }
        
        
        
        return filled
    }
    
    
    
    //MARK: Sending Requests
    
    func sendData(_ connection : BLEMimConnection){
        sendData(connection, message: nil)
    }
    
    func sendData(_ connection : BLEMimConnection, message :BLENinebotMessage?){
        
        
        
        if let msg = message {
            
            if let dat = msg.toNSData(){
                connection.writeValue(writeChar, data:dat)
                AppDelegate.debugLog("Sending a non standard messagen%@", msg.description)
                
            }
        }else if self.headersOk {  // Get normal data
            
            
            for (op, l) in listaOpFast{
                let message = BLENinebotMessage(com: op, dat:[ l * 2] , fixed: fixed )
                if let dat = message?.toNSData(){
                    connection.writeValue(writeChar, data:dat)
                }
            }
            
            let (op, l) = listaOp[contadorOp]
            contadorOp += 1
            
            if contadorOp >= listaOp.count{
                contadorOp = 0
            }
            
            let message = BLENinebotMessage(com: op, dat:[ l * 2] , fixed: fixed )
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }
        }else {    // Get One time data (S/N, etc.)
            
            
            var message = BLENinebotMessage(com: UInt8(16), dat: [UInt8(22)] , fixed: fixed)
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }
            
            // Get riding Level and max speeds
            
            message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kSpeedLimit), dat: [UInt8(4)] , fixed: fixed)
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }
            
            message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kAbsoluteSpeedLimit), dat: [UInt8(4)] , fixed: fixed)
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }
            
            
            message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kvRideMode), dat: [UInt8(2)] , fixed: fixed)
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }

            message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kEnableSpeedLimit), dat: [UInt8(2)] , fixed: fixed)
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }

            message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kLockWheel), dat: [UInt8(2)] , fixed: fixed)
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }

            
        }
    }
    
    // MARK: NSOperationSupport
    
    func injectRequest(_ tim : Timer){
        
        if let connection = tim.userInfo as? BLEMimConnection {
            self.sendNewRequest(connection)
        }
    }
    
    func sendNewRequest(_ connection : BLEMimConnection){
        
        if sending {
            let request = BLERequestOperation(adapter: self, connection: connection)
            
            if let q = self.queryQueue {
                q.addOperation(request)
            }
        }
    }
    
    
    //}
    
    //MARK: BLEWheelAdapterProtocol Extension
    
    //extension BLENinebotOneAdapter : BLEWheelAdapterProtocol{
    
    
    func wheelName() -> String {
        return "Ninebot One"
    }
    
    func isComptatible(services : [String : BLEService]) -> Bool{
        
        if let srv = services["6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]{
            if let _ = srv.characteristics["6E400003-B5A3-F393-E0A9-E50E24DCCA9"], let _ = srv.characteristics["6E400002-B5A3-F393-E0A9-E50E24DCCA9E"], let _ = srv.characteristics["FEC9"] {
                
                readChar = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
                writeChar = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
                
                fixed = 0x11
                return true
                
            }
        } else if let srv = services["FEE7"]{      // Tambe podria ser 0x0001 i les readChar i writeChar
            if let _ = srv.characteristics["FEC7"], let _ = srv.characteristics["FEC8"], let _ = srv.characteristics["FEC9"] {
                
                readChar = "FEC8"
                writeChar = "FEC7"
                fixed = 0x11
                return true
                
            }
        }

        else if let srv = services["FFE0"]{
            if let chr = srv.characteristics["FFE1"] {
                if chr.flags == "rxn"{
                    readChar = "FFE1"
                    writeChar = "FFE1"
                    fixed = 0x09
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func startRecording(){
        headersOk = false
        contadorOp = 0
        contadorOpFast = 0
        startDistance = nil
        buffer.removeAll()
        if let qu = queryQueue {
            qu.cancelAllOperations()

        }
        
    }
    
    func stopRecording(){
        headersOk = false
        contadorOp = 0
        contadorOpFast = 0
        buffer.removeAll()
        if let qu = queryQueue {
            qu.cancelAllOperations()
            sending = false
        }
        if let tim  = sendTimer {
            tim.invalidate()
            sendTimer = nil
        }
    }
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar(readChar)
        
        self.contadorOp = 0
        self.headersOk = false
        self.sending = true
        
        
        let database = WheelDatabase.sharedInstance
        let uuid = peripheral.identifier.uuidString
        
        // Get password
        
        var pwd = "000000"
        let store = UserDefaults.standard
        if let pw = store.string(forKey: kPassword){
            pwd = pw
        }
        
        if let wh = database.getWheelFromUUID(uuid: uuid){
            self.wheel = wh
            
        } else {
            self.wheel = Wheel(uuid: uuid, name: self.name)
            wheel!.brand = "Ninebot"
            wheel!.password = pwd
            database.setWheel(wheel: wheel!)
        }
       
        
        
        
        
        self.sendNewRequest(connection)
        
        self.lastConnection = connection
        
        
        // Just to be sure we start another timer to correct cases where we loose all requests
        // Will inject one request every timerStep
        
        self.sendTimer = Timer.scheduledTimer(timeInterval: timerStep, target: self, selector:#selector(BLENinebotOneAdapter.injectRequest(_:)), userInfo: connection, repeats: true)
        
        
    }
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        if let qu = queryQueue {
            sending = false
            qu.cancelAllOperations()
            
        }

        if let tim = self.sendTimer {
            tim.invalidate()
            self.sendTimer = nil
        }
        
        self.lastConnection = nil
        
        
    }
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        self.appendToBuffer(data)
        return self.procesaBuffer(connection)
    }
    
    func giveTime(_ connection: BLEMimConnection) {
        
        if let q = self.queryQueue{
            if q.operationCount < 4{
                self.sendNewRequest(connection)
            }
        }
    }
    
    
    func getName() -> String{
        return name
    }
    
    func getVersion() -> String{
        
        let clean = values[BLENinebotOneAdapter.kVersion] & 4095
        
        let v0 = clean / 256
        let v1 = (clean - (v0 * 256) ) / 16
        let v2 = clean % 16
        
        return String(format: "%d.%d.%d",v0, v1, v2)
    }
    
    func getModel() -> String{
        if !self.checkHeaders(){
            return ""
        }
        
        var no = ""
        
        
        
        for i in 16 ..< 18{
            
            
            let v = values[i]
            
            
            let v1 = v % 256
            let v2 = v / 256
            
            let ch1 = Character(UnicodeScalar(v1)!)
            let ch2 = Character(UnicodeScalar( v2)!)
            
            no.append(ch1)
            no.append(ch2)
        }
        
        return no
    }
    
    func getSN() -> String{
        
        if !self.checkHeaders(){
            return ""
        }
        
        var no = ""
        
        
        
        for i in 16 ..< 23{
            
            
            let v = values[i]
            
            
            let v1 = v % 256
            let v2 = v / 256
            
            let ch1 = Character(UnicodeScalar(v1)!)
            let ch2 = Character(UnicodeScalar( v2)!)
            
            no.append(ch1)
            no.append(ch2)
        }
        
        return no
    }
    
    func getRidingLevel() -> Int{
        return 0
    }
    
    func getMaxSpeed() -> Double {
        return 20.0
    }
    
    func setDefaultName(_ name : String){
        self.name = name
    }
    
    func setDrivingLevel(_ level: Int){
        
        
        // Check that level is between 0..9
        
        if level < 1 || level > 9 {
            return
        }
        
        
        if let connection = self.lastConnection {
            
            // That write riding level
            
            var message = BLENinebotMessage(commandToWrite: UInt8(BLENinebotOneAdapter.kvRideMode), dat:[UInt8(level), UInt8(0)]  , fixed: fixed)
            
            if let st = message?.toString(){
                AppDelegate.debugLog("Command : %@", st)
            }
            
            if let dat = message?.toNSData(){
                
                connection.writeValue(writeChar, data:dat)
            }
            
            // Get value to see if it is OK
            
            message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kvRideMode), dat:[UInt8(2)] , fixed: fixed )
            
            if let dat = message?.toNSData(){
                connection.writeValue(writeChar, data:dat)
            }
        }
        
        
    }
    func setLights(_ level: Int) {   // 0->Off 1->On....
        
        // Sorry, no ligths in Ninebot :(
    }
    
    func setLimitSpeed(_ speed : Double){
        // Check that level is between 0..9
        if speed < 0  {
            return
        }
        
        if let connection = self.lastConnection {
            
            let speedm = Int(round(speed * 1000.0)) // speedm es la velocitat en m
            
            let b1 = UInt8(speedm / 256)
            let b0 = UInt8(speedm % 256)
            
            
            // That write riding level
            
            if let message = BLENinebotMessage(commandToWrite: UInt8(BLENinebotOneAdapter.kSpeedLimit), dat:[b0, b1]  , fixed: fixed){
                
                let st = message.toString()
                AppDelegate.debugLog("Command : %@", st)
                
                let request = BLERequestOperation(adapter: self, connection: connection, message: message)
                if let q = self.queryQueue{
                    sending = false
                    q.cancelAllOperations()
                    q.addOperation(request)
                    sending = true
                }
                
            }
            
            // Get value to see if it is OK
            
            if let message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kSpeedLimit), dat:[UInt8(2)]  , fixed: fixed){
                let request = BLERequestOperation(adapter: self, connection: connection, message: message)
                
                if let q = self.queryQueue{
                    q.addOperation(request)
                }
            }
            
        }
    }
    
    func enableLimitSpeed(_ enable : Bool){
        
        if let connection = self.lastConnection {
            
            var b : UInt8 = 0
            
            if enable {
                b = 1
            }
            
            if let message = BLENinebotMessage(commandToWrite: UInt8(BLENinebotOneAdapter.kEnableSpeedLimit), dat:[b]  , fixed: fixed){
                if let q = self.queryQueue{
                    sending = false
                    q.isSuspended = true
                    q.cancelAllOperations()
                    usleep(250000)
                    
                    for _ in 0..<1{
                        let request = BLERequestOperation(adapter: self, connection: connection, message: message)
                        q.addOperation(request)
                    }
                    q.isSuspended = false
                    usleep(250000)
                    sending = true
                }
            }
            
            // Get value to see if it is OK
            
            if let message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kEnableSpeedLimit), dat:[UInt8(2)]  , fixed: fixed){
                if let q = self.queryQueue{
                    
                    for _ in 0..<1{
                        let request = BLERequestOperation(adapter: self, connection: connection, message: message)
                        q.addOperation(request)
                    }
                }
                
            }
            
        }
        
    }
    
    func lockWheel(_ lock : Bool){
        
        if let connection = self.lastConnection {
            
            var b : UInt8 = 0
            
            if lock {
                b = 1
            }
            
            if let message = BLENinebotMessage(commandToWrite: UInt8(BLENinebotOneAdapter.kLockWheel), dat:[b]  , fixed: fixed) {
                if let q = self.queryQueue{
                    
                    sending = false
                    q.isSuspended = true
                    q.cancelAllOperations()
                    usleep(250000)
 
                    for _ in 0..<1{
                        let request = BLERequestOperation(adapter: self, connection: connection, message: message)
                        q.addOperation(request)
                    }
                    q.isSuspended = false
                    usleep(250000)
                    sending = true
                }
                
            }
            if let message = BLENinebotMessage(com: UInt8(BLENinebotOneAdapter.kLockWheel), dat:[UInt8(2)]  , fixed: fixed){
                if let q = self.queryQueue{
                    
                    for _ in 0..<1{
                        let request = BLERequestOperation(adapter: self, connection: connection, message: message)
                        q.addOperation(request)
                    }
                }
                
            }
            
        }
        
    }
    
    
}


