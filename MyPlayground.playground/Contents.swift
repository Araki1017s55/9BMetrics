//: Playground - noun: a place where people can play

import UIKit
//
//  BLENinebotMessage.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 4/2/16.
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
//
// Buffer structure
//
//  +---+---+---+---+---+---+---+---+---+
//  |x55|xAA| l |x09|x01| c |...|ck0|ck1|
//  +---+---+---+---+---+---+---+---+---+
//
//  ... Are a UInt8 array of l-2 elements
//  ck0, ck1 are computed from the elements from l to the last of ...
//  x55 and xAA are fixed and are Beggining of buffer
//  l is the size of ... + 2
//  x09 and x01 seem fixed for Ninebot One but it is not clear
//  c is a command or variable. For the same value the data is similar

enum WheelValue : String{
    
    case StartDate
    case Name
    case SerialNo
    case Version
    
    case LimitSpeed
    case MaxSpeed
    case RidingLevel
    case AcumDistance
    case AcumRuntime
    
    case Altitude
    case Latitude
    case Longitude
    case AltitudeGPS
    
    case Distance
    case Duration
    
    case Speed
    case Pitch
    case Roll
    
    case Voltage
    case Current
    case Power
    case Energy
    case Battery
    case Temperature
    case DistanceGPS
    
    case limitSpeedEnabled
    case lockEnabled
    
}




class BLENinebotMessage: NSObject {
    
    let CUSTOMER_ACTION_MASK : UInt16 = 0xFFFF
    
    
    // h0, h1 representen els headers
    
    var h0 : UInt8 = 0x55
    var h1 : UInt8 = 0xaa
    
    var len : UInt8 = 2         // length of data + 2
    
    var fixed1 : UInt8 = 0x11   // Seems always constant for NB One E+
    var fixed2 : UInt8 = 0x01   // Seems always constant for NB One E+
    
    var command : UInt8 = 0x00  // Seems to be a command or variable index
    
    var data : [UInt8] = []     // Data
    
    var ck0 : UInt8 = 0x00      // Check0
    var ck1 : UInt8 = 0x00      // Check1
    
    
    
    override init() {
        
        super.init()
    }
    
    init?(com : UInt8, dat : [UInt8]){
        super.init()
        
        if dat.count > 253 {    // Max buffer size must be 253
            return nil
        }
        
        self.command = com
        self.data = dat
        self.len = UInt8(dat.count + 2)
        
        // OK build a buffer, compute checks and store
        
        var buff = [UInt8](repeating: 0, count: 6)
        buff[0] = h0
        buff[1] = h1
        buff[2] = len
        buff[3] = fixed1
        buff[4] = fixed2
        buff[5] = command
        
        buff.append(contentsOf: dat)
        
        let (check0, check1) = self.check(buff, len: buff.count-2)
        
        self.ck0 = check0
        self.ck1 = check1
        
        
    }
    
    // Aquest cas es per enviar ua comanda de escriptura. buff[4] = 03
    
    init?(commandToWrite command : UInt8, dat : [UInt8]){
        super.init()
        
        if dat.count > 253 {    // Max buffer size must be 253
            return nil
        }
        
        self.command = command
        self.data = dat
        self.len = UInt8(dat.count + 2)
        self.fixed2 = 0x03  // Writing values
        
        // OK build a buffer, compute checks and store
        
        var buff = [UInt8](repeating: 0, count: 6)
        buff[0] = h0
        buff[1] = h1
        buff[2] = len
        buff[3] = fixed1
        buff[4] = fixed2
        buff[5] = command
        
        buff.append(contentsOf: dat)
        
        let (check0, check1) = self.check(buff, len: buff.count-2)
        
        self.ck0 = check0
        self.ck1 = check1
        
        
    }
    
    init?(buffer : [UInt8]){
        
        super.init()
        
        if !self.parseBuffer(buffer) {
            return nil
        }
        
    }
    
    init?(data : Data){
        
        super.init()
        let count = data.count
        var buffer = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buffer, length:count * MemoryLayout<UInt8>.size)
        if !self.parseBuffer(buffer) {
            return nil
        }
        
    }
    
    // Inicialitza amb un Hex String
    
    init?(string : String){
        
        super.init()
        
        let chars = string.characters
        let n = chars.count
        
        let ni = n / 2
        
        var buffer = [UInt8](repeating: 0, count: ni)
        var index = string.startIndex
        var i2 = string.startIndex
        
        
        for  i in 0..<ni{
            index = i2
            i2 = string.index(index, offsetBy: 2)
            
            let s = string.substring(with: index..<i2)
            
            let us = UInt8(s, radix:16)
            if let u = us {
                buffer[i] = u
            }
            
            
        }
        
        if !self.parseBuffer(buffer) {
            return nil
        }
        
    }
    
    
    // parseBuffer omple les dades a partir del buffer. Fa check dels ck i header.
    // Retorna true si tot es correcte, false si es erroni
    
    func parseBuffer(_ buffer : [UInt8]) -> Bool{
        
        if buffer.count < 8 {   //  Minimum buffer sze
            return false
        }
        
        if buffer[0] != 0x55{
            return false
        }
        
        if buffer[1] != 0xaa{
            return false
        }
        
        self.len = buffer[2]
        
        if buffer[2] > 246{
            
        }
        
        // Check total length of buffer. May be bigger but not smaller than suggested by len
        
        if buffer.count < Int(self.len + 6) { // There are fixed 6 bytes not taken into account in len
            return false
        }
        
        (self.ck0, self.ck1) = check(buffer, len: Int(self.len) + 2)
        
        if self.ck0 != buffer[Int(self.len)+4] || self.ck1 != buffer[Int(self.len)+5]{
            return false
        }
        
        // OK all seems OK, move data from buffer to fields
        
        self.fixed1 = buffer[3]
        self.fixed2 = buffer[4]
        self.command = buffer[5]
        
        if self.len > 2{
            self.data = Array(buffer[6..<(6+Int(self.len)-2)])
        }
        
        return true
    }
    
    
    // Builds a UInt8 array with the data to be sent
    
    func toArray() -> [UInt8]{
        
        var buff = [UInt8](repeating: 0, count: 6)
        
        buff[0] = h0
        buff[1] = h1
        buff[2] = len
        buff[3] = fixed1
        buff[4] = fixed2
        buff[5] = command
        
        buff.append(contentsOf: data)
        
        buff.append(ck0)
        buff.append(ck1)
        
        return buff
    }
    
    func toNSData() -> Data?{
        
        let buff = toArray();
        let data = Data(bytes: UnsafePointer<UInt8>(buff), count: buff.count)
        
        return data
    }
    
    
    // Computes checksum from byte [2] for len bytes.
    
    func check(_ bArr : [UInt8], len : Int) -> (UInt8, UInt8) {			//Comença a i2 = 2 per c bytes
        var i : UInt16 = 0;
        
        for i2 in 2 ..< len + 2 {
            i =  (i + UInt16(bArr[i2]))
        }
        let v : UInt16 =   (i ^ 0xFFFF) & self.CUSTOMER_ACTION_MASK
        
        return( UInt8(v & UInt16(255)),  UInt8(v>>8))
        
    }
    
    func toString() -> String{
        
        var s = String(format: "BLEMessage : c = %02x p = ", self.command)
        
        for b in self.data{
            s.append(String(format:" %02x", b))
        }
        
        return s
        
    }
    
    
    // parse the message and returns a dictionary (hash table)
    // -> Interpreta el missatge i retorna un Diccionari amb el numero de variable i el valor
    
    func interpret() -> [Int :Int]{
        
        var dict = [Int : Int]()
        
        if (fixed1 == 0x11 && fixed2 == 1) || true {
            
            
            let l = Int(self.len-2)
            var k = Int(self.command)
            
            var i = 0
            
            while  i < l{
                
                let value = Int(data[i+1]) * 256 + Int(data[i])
                
                dict[k] = value
                k += 1
                i=i+2
                
            }
        }
        
        return dict
        
    }
    
    
}


class BLENinebot{
    
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
    
    
    static var conversion = Array<WheelValue?>(repeating: nil, count: 256)
    static var scales = Array<Double>(repeating: 1.0, count: 256)
    static var signed = [Bool](repeating: false, count: 256)
    
    init(){
        
        
        BLENinebot.initConversion()
        
    }
    
    static func initConversion(){
        
        conversion[BLENinebot.kAltitude] = WheelValue.Altitude
        conversion[BLENinebot.kPower] = WheelValue.Power
        conversion[BLENinebot.kEnergy] = WheelValue.Energy
        conversion[BLENinebot.kLatitude] = WheelValue.Latitude
        conversion[BLENinebot.kLongitude] = WheelValue.Longitude
        conversion[BLENinebot.kAltitudeGPS] = WheelValue.AltitudeGPS
        conversion[BLENinebot.kvPowerRemaining] = WheelValue.Battery
        conversion[BLENinebot.kvSpeed] = WheelValue.Speed
        conversion[BLENinebot.kSingleRuntime] = WheelValue.Duration
        conversion[BLENinebot.kTemperature] = WheelValue.Temperature
        conversion[BLENinebot.kvDriveVoltage] = WheelValue.Voltage
        conversion[BLENinebot.kvCurrent] = WheelValue.Current
        conversion[BLENinebot.kPitchAngle] = WheelValue.Pitch
        conversion[BLENinebot.kRollAngle] = WheelValue.Roll
        conversion[BLENinebot.kAbsoluteSpeedLimit] = WheelValue.MaxSpeed
        conversion[BLENinebot.kSpeedLimit] = WheelValue.LimitSpeed
        conversion[BLENinebot.kBattery] = WheelValue.Battery
        conversion[BLENinebot.kCurrentSpeed] = WheelValue.Speed
        conversion[BLENinebot.kvSingleMileage] = WheelValue.Distance
        conversion[BLENinebot.kvTemperature] = WheelValue.Temperature
        conversion[BLENinebot.kVoltage] = WheelValue.Voltage
        conversion[BLENinebot.kCurrent] = WheelValue.Current
        conversion[BLENinebot.kvPitchAngle] = WheelValue.Pitch
        conversion[BLENinebot.kvMaxSpeed] = WheelValue.MaxSpeed
        conversion[BLENinebot.kvRideMode] = WheelValue.RidingLevel
        conversion[BLENinebot.kEnableSpeedLimit] = WheelValue.limitSpeedEnabled
        conversion[BLENinebot.kLockWheel] = WheelValue.lockEnabled
        
        
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
    
    func analitza(_ mensaje : String) -> [(WheelValue, Double)]?{
        
        
        let msg = mensaje.replacingOccurrences(of: " ", with: "")
        
        var outarr : [(WheelValue, Double)]? = []
        
        if let m = BLENinebotMessage(string:msg){
            let d = m.interpret()
            
            for (k, v) in d {
                if k != 0{
                    
                    if outarr == nil{
                        outarr = []
                    }
                    
                    var sv = v
                    
                    // Treat signed values
                    
                    if BLENinebot.signed[k]{
                        if v >= 32768 {
                            sv = v - 65536
                        }
                    }
                    
                    
                    //TODO: Verify that conversion is OK. First treat two Ninebot variables
                    // For the moment not found any value
                    
                    if k == BLENinebot.kError{
                        print("Error")
                    }else if k == BLENinebot.kWarn{
                        print("Warning")
                    }
                    // Convert to SI by an scale and assign to generic variable
                    
                    
                    
                    let dv = Double(sv) * BLENinebot.scales[k]
                    
                    if let wv = BLENinebot.conversion[k]{
                        
                        outarr!.append((wv, dv))
                        
                    }
                    
                }
                
                // Checkheaders is used to know if we have already received static information
                // That is asked at the beginning, as the model, serial number...
                
            }
            // Check special case for total distance
            
            if let v0 = d[BLENinebot.kvTotalMileage0], let v1 = d[BLENinebot.kvTotalMileage1]{
                
                let total = Double(v1) * 65536.0 + Double(v0)
                outarr!.append(WheelValue.AcumDistance,  total)
            }
            

        }
        
        return outarr
        
    }
    
}


// That's OK, it reads the PIN code. Seems oit needs to send you the code
let a = 5

var msg  = BLENinebotMessage(string:"55AA0A110117303030303030071194FE")

var buff = msg?.toArray()
var data = msg?.interpret()

// You changed the code but the real problem is CheckSum is not OK so NB drops the buffer

msg  = BLENinebotMessage(string:"55AA08110117353535353535071176FE")
buff = msg?.toArray()
data = msg?.interpret()

// Now answers. They are OK with the check.

msg  = BLENinebotMessage(string:"55AA3211011730303030303007110000000048B8181A000000000000610061006200000C0000C05D0000629817000000000000000000DCF9")
buff = msg?.toArray()
data = msg?.interpret()


// You Now it interprets length is 17. Check doesen't work

msg  = BLENinebotMessage(string:"55AA3211011730303030303007110000000048B8181A000000000000610061006200FE0B0000C05D0000629817000000000000000000DFF8")
buff = msg?.toArray()
data = msg?.interpret()


msg = BLENinebotMessage(string: "55AA91111A71100000000486AFF")



let nb = BLENinebot()

let arr = nb.analitza("55 AA 08 11 01 17 35 35 35 35 35 35 90 FE")


let messages = ["55 AA 0A 11 01 17 30 30 30 30 30 30 07 11 94 FE",
"55 AA 0A 11 01 17 31 30 30 30 30 30 07 11 94 FE",
"55 AA 03 11 01 22 02 C6 FF",
"55 AA 03 11 01 28 02 C0 FF",
"55 AA 04 11 01 22 56 00 71 FF",
"55 AA 03 11 01 29 04 BD FF",
"55 AA 08 11 01 17 35 35 35 35 35 35 07 11 76 FE",
"55 AA 11 01 17 35 35 35 35 35 35 07 11 76 FE",
"55 AA 03 11 01 1A 02 CE FF",
"55 AA 04 11 01 1A 07 11 B7 FF",
"55 AA 09 11 01 1A 07 11 00 00 00 00 48 6A FF",
"55 AA 03 11 01 17 06 CD FF",
"55 AA 08 11 01 17 35 35 35 35 35 35 90 FE",
"55 AA 08 11 01 17 35 35 35 35 35 35 90 FE",
"55 AA 37 11 01 17 30 30 30 30 30 30 07 11 00 00 00 00 48 B8 18 1A 00 00 00 00 00 00 62 00 62 00 63 00 30 C0 00 00 C0 5D 00 00 62 98 17 00 00 00 00 00 00 00 00 00 00 00 00 00 A4 F9",
"55 AA 08 11 01 17 35 35 35 35 35 35 90 FE",
"55 AA 03 11 01 17 08 CB FF"]


for m in messages {
    
    let ms = BLENinebotMessage(string: m.replacingOccurrences(of: " ", with: ""))
    
    if let msg = ms {
        print(m, "is ok")
    } else {
        print(m, "is incorrect")
    }
}


msg = BLENinebotMessage(commandToWrite: 0x17, dat: [0x35, 0x35, 0x35, 0x35, 0x35, 0x35])
msg?.toArray()







