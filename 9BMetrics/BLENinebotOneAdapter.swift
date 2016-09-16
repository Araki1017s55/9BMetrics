//
//  BLENinebotOneAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth

class BLENinebotOneAdapter : NSObject {
    
    var headersOk = false
    var sendTimer : NSTimer?    // Timer per enviar les dades periodicament
    var timerStep = 0.1        // Get data every step
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(50,2), (58,1),  (62, 1), (182, 5)]
    // var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4), (34,4), (71,6)]
    
    var listaOpFast :[(UInt8, UInt8)] = [(97,2), (188,2), (180,2)]
    
    var buffer = [UInt8]()
    
    var queryQueue : NSOperationQueue?
    
    static var conversion = Array<WheelTrack.WheelValue?>(count : 256, repeatedValue: nil)
    static var scales = Array<Double>(count : 256, repeatedValue: 1.0)
    static var signed = [Bool](count: 256, repeatedValue: false)
    
    var values : [Int] = Array(count: 256, repeatedValue: -1)

    
    
    // Called when lost connection. perhaps should do something. If not forget it
    
    
    // Data Received. Analyze, extract, convert and prosibly return a dictionary of characteristics and values
    
    
    // Called by connection when we got device characteristics
    
    override init(){
        super.init()
        queryQueue = NSOperationQueue()
        queryQueue!.maxConcurrentOperationCount = 1
        
        BLENinebotOneAdapter.initConversion()
        
    }
    
    static func initConversion(){
        
        conversion[BLENinebot.kAltitude] = WheelTrack.WheelValue.Altitude
        conversion[BLENinebot.kPower] = WheelTrack.WheelValue.Power
        conversion[BLENinebot.kEnergy] = WheelTrack.WheelValue.Energy
        conversion[BLENinebot.kLatitude] = WheelTrack.WheelValue.Latitude
        conversion[BLENinebot.kLongitude] = WheelTrack.WheelValue.Longitude
        conversion[BLENinebot.kAltitudeGPS] = WheelTrack.WheelValue.AltitudeGPS
        conversion[BLENinebot.kvPowerRemaining] = WheelTrack.WheelValue.Battery
        conversion[BLENinebot.kvSpeed] = WheelTrack.WheelValue.Speed
        conversion[BLENinebot.kSingleRuntime] = WheelTrack.WheelValue.Duration
        conversion[BLENinebot.kTemperature] = WheelTrack.WheelValue.Temperature
        conversion[BLENinebot.kvDriveVoltage] = WheelTrack.WheelValue.Voltage
        conversion[BLENinebot.kvCurrent] = WheelTrack.WheelValue.Current
        conversion[BLENinebot.kPitchAngle] = WheelTrack.WheelValue.Pitch
        conversion[BLENinebot.kRollAngle] = WheelTrack.WheelValue.Roll
        conversion[BLENinebot.kAbsoluteSpeedLimit] = WheelTrack.WheelValue.MaxSpeed
        conversion[BLENinebot.kSpeedLimit] = WheelTrack.WheelValue.LimitSpeed
        conversion[BLENinebot.kBattery] = WheelTrack.WheelValue.Battery
        conversion[BLENinebot.kCurrentSpeed] = WheelTrack.WheelValue.Speed
        conversion[BLENinebot.kvSingleMileage] = WheelTrack.WheelValue.Distance
        conversion[BLENinebot.kvTemperature] = WheelTrack.WheelValue.Temperature
        conversion[BLENinebot.kVoltage] = WheelTrack.WheelValue.Voltage
        conversion[BLENinebot.kCurrent] = WheelTrack.WheelValue.Current
        conversion[BLENinebot.kvPitchAngle] = WheelTrack.WheelValue.Pitch
        conversion[BLENinebot.kvMaxSpeed] = WheelTrack.WheelValue.MaxSpeed
        conversion[BLENinebot.kvRideMode] = WheelTrack.WheelValue.RidingLevel
        
        
        scales[BLENinebot.kvSpeed] = 1.0 / 3600.0
        scales[BLENinebot.kTemperature] = 0.1
        scales[BLENinebot.kvDriveVoltage] = 0.01
        scales[BLENinebot.kvCurrent] = 0.01
        scales[BLENinebot.kPitchAngle] = 0.01
        scales[BLENinebot.kRollAngle] = 0.01
        scales[BLENinebot.kAbsoluteSpeedLimit] = 1.0 / 3600.0
        scales[BLENinebot.kSpeedLimit] = 1.0 / 3600.0
        scales[BLENinebot.kCurrentSpeed] = 1.0 / 3600.0
        scales[BLENinebot.kvSingleMileage] = 10.0
        scales[BLENinebot.kvTemperature] = 0.1
        scales[BLENinebot.kVoltage] = 0.01
        scales[BLENinebot.kCurrent] = 0.01
        scales[BLENinebot.kvPitchAngle] = 0.01
        scales[BLENinebot.kvMaxSpeed] = 1.0 / 3600.0
        
        signed[BLENinebot.kPitchAngle] = true
        signed[BLENinebot.kRollAngle] = true
        signed[BLENinebot.kPitchAngleVelocity] = true
        signed[BLENinebot.kRollAngleVelocity] = true
        signed[BLENinebot.kCurrent] = true
        signed[BLENinebot.kvPitchAngle] = true

    }
   
    //MARK: Receiving Data. Append data to buffer
    
    func appendToBuffer(data : NSData){
        
        let count = data.length
        var buf = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buf, length:count * sizeof(UInt8))
        
        buffer.appendContentsOf(buf)
    }
    
    // Here we process received information.
    // We maintain a buffer (buffer) and data is appended in appendToBuffer
    // as each block is received. Logical Data may span more than one block and not be aligned.
    //
    //
    //  So we call procesaBuffer to extract any posible data. It is returned as an array of 
    //  3 values, the variable, the date and the value all aready converted to ggeneric values
    // and SI units
    
    
    func procesaBuffer(connection: BLEConnection) -> [(WheelTrack.WheelValue, NSDate, Double)]?
    {
        // Wait till header. We wait till we find a 0x55
        
        var outarr : [(WheelTrack.WheelValue, NSDate, Double)]?
        
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
                    outarr!.appendContentsOf(moreData)
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
            
            if let q = self.queryQueue where q.operationCount < 4{
                self.sendNewRequest(connection)
            }
            
            // BLENinebotMessage interprets a logical block of information
            
            let msg = BLENinebotMessage(buffer: block)
            
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
                        
                        if k == BLENinebot.kError{
                            NSLog("Error %d ", v)
                        }else if k == BLENinebot.kWarn{
                            NSLog("Warning %d", v)
                        }
                        // Convert to SI by an scale and assign to generic variable
                        
                        let dv = Double(sv) * BLENinebotOneAdapter.scales[k]
                        if let wv = BLENinebotOneAdapter.conversion[k]{
                            outarr!.append((wv, NSDate(), dv))
                                                        
                        }
                    }
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
        
        if values[BLENinebot.kSpeedLimit] == -1{
            filled = false
        }
        
        if values[BLENinebot.kAbsoluteSpeedLimit] == -1{
            filled = false
        }
        
        if values[BLENinebot.kvRideMode] == -1{
            filled = false
        }
        
        
        
        headersOk = filled

        if headersOk {  // Notify the world we have all the data :)
            BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
        }
        
        
        
        return filled
    }
   
    
    
    //MARK: Sending Requests
    
    func sendData(connection : BLEConnection){
        
        
        if self.headersOk {  // Get normal data
            
              
            for (op, l) in listaOpFast{
                let message = BLENinebotMessage(com: op, dat:[ l * 2] )
                if let dat = message?.toNSData(){
                    connection.writeValue(dat)
                }
            }
            
            let (op, l) = listaOp[contadorOp]
            contadorOp += 1
            
            if contadorOp >= listaOp.count{
                contadorOp = 0
            }
            
            let message = BLENinebotMessage(com: op, dat:[ l * 2] )
            
            if let dat = message?.toNSData(){
                connection.writeValue(dat)
            }
        }else {    // Get One time data (S/N, etc.)
            
            
            var message = BLENinebotMessage(com: UInt8(16), dat: [UInt8(22)])
            if let dat = message?.toNSData(){
                connection.writeValue(dat)
            }
            
            // Get riding Level and max speeds
            
            message = BLENinebotMessage(com: UInt8(BLENinebot.kAbsoluteSpeedLimit), dat: [UInt8(4)])
            
            if let dat = message?.toNSData(){
                connection.writeValue(dat)
            }
            
            message = BLENinebotMessage(com: UInt8(BLENinebot.kvRideMode), dat: [UInt8(2)])
            
            if let dat = message?.toNSData(){
                connection.writeValue(dat)
            }
            
        }
    }
    
    // MARK: NSOperationSupport
    
    func injectRequest(tim : NSTimer){
        
        if let connection = tim.userInfo as? BLEConnection {
            self.sendNewRequest(connection)
        }
    }
    
    func sendNewRequest(connection : BLEConnection){
        
        let request = BLERequestOperation(adapter: self, connection: connection)
        
        if let q = self.queryQueue{
            q.addOperation(request)
        }
    }
    
    
}

//MARK: BLEWheelAdapterProtocol Extension

extension BLENinebotOneAdapter : BLEWheelAdapterProtocol{
    
    func startRecording(){
        headersOk = false
        contadorOp = 0
        contadorOpFast = 0
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
        }
        if let tim  = sendTimer {
            tim.invalidate()
            sendTimer = nil
        }
    }
    
    func deviceConnected(connection: BLEConnection, peripheral : CBPeripheral ){
        
        
        self.contadorOp = 0
        self.headersOk = false
        
        self.sendNewRequest(connection)
        
        // Just to be sure we start another timer to correct cases where we loose all requests
        // Will inject one request every timerStep
        
        self.sendTimer = NSTimer.scheduledTimerWithTimeInterval(timerStep, target: self, selector:#selector(BLENinebotOneAdapter.injectRequest(_:)), userInfo: connection, repeats: true)
        
        
    }
    func deviceDisconnected(connection: BLEConnection, peripheral : CBPeripheral ){
        
        
        if let tim = self.sendTimer {
            tim.invalidate()
            self.sendTimer = nil
        }
        
    }
    
    func charUpdated(connection: BLEConnection,  char : CBCharacteristic, data: NSData) -> [(WheelTrack.WheelValue, NSDate, Double)]?{
        
        self.appendToBuffer(data)
        return self.procesaBuffer(connection)
    }
    
    
    func getName() -> String{
        return getSN()
    }
    
    func getVersion() -> String{
        
        let clean = values[BLENinebot.kVersion] & 4095
        
        let v0 = clean / 256
        let v1 = (clean - (v0 * 256) ) / 16
        let v2 = clean % 16
        
        return String(format: "%d.%d.%d",v0, v1, v2)
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
            
            let ch1 = Character(UnicodeScalar(v1))
            let ch2 = Character(UnicodeScalar( v2))
            
            no.append(ch1)
            no.append(ch2)
        }
        
        return no
    }
}


