//
//  BLENinebotOneAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth

class GotawayAdapter : NSObject {
    
    var headersOk = false
    var sendTimer : Timer?    // Timer per enviar les dades periodicament
    var timerStep = 0.1        // Get data every step
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(50,2), (58,1),  (62, 1), (182, 5)]
    // var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4), (34,4), (71,6)]
    
    var listaOpFast :[(UInt8, UInt8)] = [(97,2), (188,2), (180,2)]
    
    var buffer = [UInt8]()
    
    var queryQueue : OperationQueue?
    
    static var conversion = Array<WheelTrack.WheelValue?>(repeating: nil, count: 256)
    static var scales = Array<Double>(repeating: 1.0, count: 256)
    static var signed = [Bool](repeating: false, count: 256)
    
    var values : [Int] = Array(repeating: -1, count: 256)
    
    
    
    // Called when lost connection. perhaps should do something. If not forget it
    
    
    // Data Received. Analyze, extract, convert and prosibly return a dictionary of characteristics and values
    
    
    // Called by connection when we got device characteristics
    
    override init(){
        super.init()
        GotawayAdapter.initConversion()
        
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
            
            // We have 20 bytes and 10 bytes buffers
            
            switch(buffer.count){
                
                case 10, 20:
                    let block = Array(buffer)
                    
                break
                
                
            default:
                return outarr
                
                
            }
            let l = 1
            
            // OK ara ja podem extreure el block. Te len + 6 bytes
            
            let block = Array(buffer[0..<(l+6)])
            
            
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
                            AppDelegate.debugLog("Error %d ", v)
                        }else if k == BLENinebot.kWarn{
                            AppDelegate.debugLog("Warning %d", v)
                        }
                        // Convert to SI by an scale and assign to generic variable
                        
                        let dv = Double(sv) * BLENinebotOneAdapter.scales[k]
                        if let wv = BLENinebotOneAdapter.conversion[k]{
                            outarr!.append((wv, Date(), dv))
                            
                        }
                    }
                }
                
                
                
            }
            
             
        } while buffer.count > 6
        return outarr
    }
    
    
    
    
}

//MARK: BLEWheelAdapterProtocol Extension

extension GotawayAdapter : BLEWheelAdapterProtocol{
    
    
    func wheelName() -> String {
        return "Gotaway"
    }
    
    func isComptatible(services : [String : BLEService]) -> Bool{
        
        if let srv = services["FFE0"]{
            if let chr = srv.characteristics["FFE1"] {
                if chr.flags == "rxn"{
                    return true
                }
            }
        }
        
        return false
    }
    
    
    func startRecording(){

        buffer.removeAll()
        
    }
    
    func stopRecording(){
        buffer.removeAll()
    }
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FFE1")
        

        
    }
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        
    }
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        self.appendToBuffer(data)
        return self.procesaBuffer(connection)
    }
    
    
    func getName() -> String{
        return "Gotaway"
    }
    
    func getVersion() -> String{
        
        return "1.0!"
    }
    
    func getSN() -> String{
        return "0123456789"
    }
}


