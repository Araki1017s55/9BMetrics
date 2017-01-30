//
//  BLEInMotionAdapter
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

class BLEInMotionUnpacker {
    
    enum UnpackerState : Int {
        case unknown = 0
        case collecting
        case done
    }
    
    var buffer : [UInt8] = []
    var oldc : UInt8 = 0
    var state : UnpackerState = .unknown
    
    init(){
        
    }
    
    
    func addChar(_ c :UInt8) -> Bool{
        
        switch state {
            
        case .collecting :
            
            buffer.append(c)
            if c == 0x55 && oldc == 0x55 {
                state = .done
                oldc = c
                return true
            }
            oldc = c
            
        default:
            if c == 0xAA && oldc == 0xAA {
                buffer = [0xAA, 0xAA]
                state = .collecting
            }
            oldc = c
            
        }
        return false
    }
    
    func reset(){
        buffer = []
        oldc = 0
        state = .unknown
        
    }
}

class CANMessage{
    
    enum CanFormat : Int {
        case StandardFormat = 0
        case ExtendedFormat
    }
    
    enum CanFrame : Int {
        case DataFrame = 0
        case RemoteFrame
    }
    
    enum IDValue : UInt {
        case NoOp = 0
        case GetFastInfo = 0x0F550113
        case GetSlowInfo = 0x0F550114
        case RemoteControl = 0x0F550116
        case CheckPassword = 0x0F550307
        case Password = 0x0F550306
        case LEDControl = 0x0F55010D
        case DontKnow = 0x0F780101
    }
    
    static let canMsgLen = 16
    
    
    var id : IDValue = .NoOp
    var data : [UInt8] = Array(repeating: 0, count: 8)
    var len : UInt8 = 0
    var ch : UInt8 = 0
    var format = CanFormat.StandardFormat
    var type = CanFrame.DataFrame
    var ex_data : [UInt8]?
    var buffer : [UInt8] = Array(repeating: 0, count: 16)
    
    init(){
        
    }
    
    init(_ bArr : [UInt8]){
        
        let rw = (((UInt(bArr[3]) * 256) + UInt(bArr[2])) * 256 + UInt(bArr[1])) * 256 + UInt(bArr[0])
        
        id = .NoOp
        if let mid = IDValue(rawValue: rw) {
            id = mid
        } else {
            AppDelegate.debugLog("Missatge No compres <%ld", rw)
        }
        
        data = Array(bArr[4..<12])
        len = bArr[12]
        ch = bArr[13]
        format = bArr[14] == 0 ? .StandardFormat : .ExtendedFormat
        type = bArr[15] == 0 ? .DataFrame : .RemoteFrame
        
        if len == 0xFE {    // COMMENT: Aqui podria haver-hi un error
            let ldata = Int(BLEInMotionAdapter.IntFromBytes(data, starting: 0))  //(((Int(data[3]) * 256) + Int(data[2])) * 256 + Int(data[1])) * 256 + Int(data[0])
            
            if ldata == bArr.count - 16 {
                ex_data = Array(bArr[16..<16+ldata])
            }
        }
    }
    
    func getBytes() -> [UInt8]{
        
        var buff : [UInt8] = []
        
        let b3 = UInt8(id.rawValue / (256 * 256 * 256))
        let b2 = UInt8((id.rawValue - UInt(b3) * 256 * 256 * 256) / (256 * 256))
        
        let b1 = UInt8((id.rawValue - UInt(b3) * 256 * 256 * 256 - UInt(b2) * 256 * 256) / 256)
        let b0 = UInt8(id.rawValue % 256)
        
        buff.append(b0)
        buff.append(b1)
        buff.append(b2)
        buff.append(b3)
        
        buff.append(contentsOf: data)
        buff.append(len)
        buff.append(ch)
        
        buff.append(UInt8(format == .StandardFormat ? 0 : 1))
        buff.append(UInt8(type == .DataFrame ? 0 : 1))
        
        if let dat = ex_data{
            
            if len == 0xFE {
                buff.append(contentsOf: dat)
            }
        }
        return buff
    }
    
    func clearData() {
        data = Array(repeating: 0, count: data.count)
    }
    
    func writeBuffer() -> [UInt8]{
        
        let canBuffer = getBytes()
        let check = BLEInMotionAdapter.computeCheck(canBuffer)
        
        var out : [UInt8] = [0xAA, 0xAA]
        
        out.append(contentsOf: BLEInMotionAdapter.escape(canBuffer))
        out.append(check)
        out.append(0x55)
        out.append(0x55)
        
        return out
        
        
    }
    
    func toNSData() -> Data?{
        
        let buff = writeBuffer()
        let data = Data(bytes: UnsafePointer<UInt8>(buff), count: buff.count)
        
        return data
    }
    
    
    static func standarddata() -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .GetFastInfo   // Get Fast Infi
        msg.ch = 5
        msg.data = [24,0,1,0,0,0,0,0]
        
        return msg
        
    }
    
    static func getFastData() -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .GetFastInfo   // Get Fast Infi
        msg.ch = 5
        msg.data = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        
        return msg
        
    }
    
    static func getSlowData() -> CANMessage{
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .GetSlowInfo   // Get Fast Infi
        msg.ch = 5
        msg.type = .RemoteFrame
        //msg.data = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        msg.data = [33, 0, 0, 2, 0, 0, 0, 0]
        
        return msg
        
    }
    
    //    static func setMode(_ mode : UInt8) -> CANMessage{
    //
    //        let msg = CANMessage()
    //
    //        msg.len = 8
    //        msg.id = .GetSlowInfo   // Get Fast Infi
    //        msg.ch = 5
    //        msg.type = .DataFrame
    //        msg.data = [0xB2, 0, 0, 0, mode, 0, 0, 0]
    //
    //        return msg
    //
    //    }
    
    
    
    static func getCheckPassword(_ pwd : [UInt8]) -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .CheckPassword
        msg.ch = 5
        msg.type = .DataFrame
        
        msg.data = [pwd[0], pwd[1], pwd[2], pwd[3], pwd[4], pwd[5], 0, 0]
        
        return msg
        
    }
    
    static func getResetPassword() -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .Password
        msg.ch = 5
        msg.type = .DataFrame
        
        msg.data = [48, 48, 48, 48, 48, 48, 0, 0]
        
        return msg
        
    }
    
    
    static func getBatteryLevelsdata() -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .GetSlowInfo    // Get Slow Info
        msg.ch = 5
        msg.type = .RemoteFrame
        
        msg.data = [0, 0, 0, 15, 0, 0, 0, 0]
        
        return msg
        
    }
    
    static func getVersion() -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .GetSlowInfo     // Get Slow Info
        msg.ch = 5
        msg.type = .RemoteFrame
        
        msg.data = [32, 0, 0, 0, 0, 0, 0, 0]
        
        return msg
    }
    
    
    static func getSerialNumberdata() -> CANMessage {
        let msg = CANMessage()
        
        msg.len = 8
        msg.id = .GetSlowInfo
        msg.ch = 5
        msg.type = .RemoteFrame
        
        msg.data = [33, 0, 0, 2, 0, 0, 0, 0]
        
        return msg
        
    }
    
    static func setMode(_ mode : UInt8) -> CANMessage{
        
        let msg = CANMessage()
        
        msg.len = 8
        msg.ch = 5
        msg.id = .NoOp
        msg.type = .DataFrame
        msg.data = [0xB2, 0, 0, 0, mode, 0, 0, 0]
        
        return msg
        
    }
    
    static func setLights(_ on : Bool) -> CANMessage{
        
        
        let msg = CANMessage()
        
        msg.len = 8
        msg.ch = 5
        msg.id = .LEDControl
        msg.type = .DataFrame
        msg.data = [ 0, 0, 0, on ? 1 : 0,   0, 0, 0, 0]
        
        return msg
        
    }
    
    
    func parseFastInfoMessage(_ model : BLEInMotionAdapter.Model) -> [(WheelTrack.WheelValue, Date, Double)] {
        
        // Angle
        
        let d = Date()
        if let bytes = ex_data{
            var angle = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 0)) / 65536.0
            
            if angle >= 32768.0 {           // Correct Sign
                angle = angle - 65536.0
            }
            
            var scale = 3600.0
            if let scl = BLEInMotionAdapter.lengthScale[model]{
                scale = scl
            }
            
            let speed = fabs((Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 12 )) + Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 16 ))) / (scale * 2.0) )       // 3812.0 depen del tipus de vehicle
            
            let voltage = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 24)) / 100.0
            let current = Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 20)) / 100.0
            let power = voltage * current
            
            var distance = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 44))
            
            if BLEInMotionAdapter.IsCarTypeBelongToInputType(carType: model.rawValue, type: "1") ||
                BLEInMotionAdapter.IsCarTypeBelongToInputType(carType: model.rawValue, type: "5") ||
                BLEInMotionAdapter.IsCarTypeBelongToInputType(carType: model.rawValue, type: "8"){
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44))
                    
            }else if model == .R0 {
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44))
                    
                
            }else if model == .L6 {
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44)) * 100.0
                
            }else {
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44)) / 5.711016379455429E4
            }
            
            let workMode = BLEInMotionAdapter.IntToWorkMode(Int(BLEInMotionAdapter.IntFromBytes(bytes, starting: 60)))
            var lock = 0.0
            switch workMode {
                
            case .lock:
                lock = 1.0
                
            default:
                break
            }
            
            let batt = BLEInMotionAdapter.batteryFromVoltage(voltage, model: model)
            return [(WheelTrack.WheelValue.Pitch, d, angle),
                    (WheelTrack.WheelValue.Speed, d, speed),
                    (WheelTrack.WheelValue.Voltage, d, voltage),
                    (WheelTrack.WheelValue.Battery, d, batt),
                    (WheelTrack.WheelValue.Current, d, current),
                    (WheelTrack.WheelValue.Power, d, power),
                    (WheelTrack.WheelValue.AcumDistance, d, distance),
                    (WheelTrack.WheelValue.lockEnabled, d, lock)
                
                
            ]
            
        } else {
            return []
        }
        
        
    }
    
    // Return SerialNumber, Model, Version
    // data [0] = 131
    // ex_data = 134, 1, 82, 134, 84, 130, 160, 16, 0...0 [24] 241, 3, 1, 1, 0..0 [32]133, 3, 0, 1 0..0 [40] 38, 3, 1, 1..0
    
    func parseSlowInfoMessage() -> (String, BLEInMotionAdapter.Model, String, Double){
        if let bytes = ex_data{
            
            var serialNumber = ""
            
            for j in 0...7 {
                let c = bytes[7 - j]
                serialNumber += String(format:"%02X", c)
            }
            let model = BLEInMotionAdapter.byteToModel(bytes)
            let v = BLEInMotionAdapter.IntFromBytes(bytes, starting: 24) // V8 = 241, 3, 1, 1
            let v0 = v / 0xFFFFFF
            let v1 = (v - v0 * 0xFFFFFF) / 0xFFFF
            let v2 = v - v0 * 0xFFFFFF - v1 * 0xFFFF
            let version = String(format:"%d.%d.%d", v0, v1, v2)
            
            //let vmax = fabs((Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 60 )) + Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 16 ))) / (3812.0 * 2.0) )
            
            // El V8 lo da en km/h directamente
            
            var scale = 3600.0
            
            if let scl = BLEInMotionAdapter.lengthScale[model]{
                scale = scl
            }
            
            // Suposo que aqui tenim un problema. Ja veurem però crec que el V8 la dona en km/h
            
            let vmax = fabs((Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 60 ))) ) / scale
            
            return (serialNumber, model, version, vmax)
        }
        return ("", BLEInMotionAdapter.Model.UNKNOWN, "", 0.0)
        
    }
}

class BLEInMotionAdapter : NSObject, BLEWheelAdapterProtocol {
    
    
    
    
    enum Mode : Int {
        case rookie = 0
        case general
        case smoothly
        case unBoot
        case bldc
        case foc
    }
    
    
    enum Model : String {
        
        case R1N = "0"
        case R1S = "1"
        case R1AP = "3"
        case R1CF = "2"
        case R1EX = "4"
        case R1Sample = "5"
        case R1T = "6"
        case R10 = "7"
        case V3 = "10"
        case R2N = "21"
        case R2S = "22"
        case R2Sample = "23"
        case R2 = "20"
        case R2EX = "24"
        case L6 = "60"
        case V3C = "11"
        case V3S = "13"
        case V3PRO = "12"
        case R0 = "30"
        case V5 = "50"
        case V5PLUS = "51"
        case V5F = "52"
        case V8 = "80"
        case UNKNOWN = "x"
        
    }
    
    
    enum WorkMode : Int {
        case idle = 0
        case drive
        case zero
        case largeAngle
        case checkc
        case lock
        case error
        case carry
        case remoteControl
        case shutdown
        case pomStop
        case unknown
        case unlock
    }
    
    enum ConnectionState {
        case disconnected
        case identified
        case connected
    }
    
    static let lengthScale : [Model:Double] = [
        
        .R1N : 3812.0,
        .R1S : 1000.0,
        .R1AP : 3812.0,
        .R1CF : 3812.0,
        .R1EX : 3812.0,
        .R1Sample : 1000.0,
        .R1T : 3812.0,
        .R10 : 3812.0,
        .V3 : 3812.0,
        .R2N : 3812.0,
        .R2S : 3812.0,
        .R2Sample : 3812.0,
        .R2 : 3812.0,
        .R2EX  : 3812.0,
        .L6 : 3812.0,
        .V3C  : 3812.0,
        .V3S : 3812.0,
        .V3PRO : 3812.0,
        .R0  : 1000.0,
        .V5 : 3812.0,
        .V5PLUS : 3812.0,
        .V5F : 3812.0,
        .V8  : 3600.0,
        .UNKNOWN  : 3812.0
        
    ]
    
    var state = ConnectionState.disconnected
    var sendTimer : Timer?    // Timer per enviar les ex_data periodicament. De moment te un altre sistema
    var timerStep = 0.3       // Get data every step
    var unpacker = BLEInMotionUnpacker()    // Create as unpacker
    var connection : BLEMimConnection?
    var name : String = "InMotion"
    var version : String = "0.0.0"
    var serialNumber : String = "SN1"
    var wheel : Wheel?
    var headerData  = false
    var queryQueue = OperationQueue()
    var model = Model.UNKNOWN
    var lastDateSent = Date()
    var firstDistance : Double? // gets first distance. It is used to conunt differences and actual distance
    var nTimes = 0
    let maxNTimes = 10
    
    override init(){
        super.init()
        
        queryQueue.maxConcurrentOperationCount = 1
        
    }
    
    //MARK: Auxiliary Functions
    
    static func IntToMode(_ mode : Int) -> Mode{
        if mode & 16 != 0{
            return .rookie
        } else if mode & 32 != 0{
            return .general
        }else if ( mode & 64 == 0) || (mode & 128 == 0){
            return .unBoot
        }else{
            return .smoothly
        }
    }
    
    
    static func IntToModeWithL6(_ mode : Int) -> Mode {
        if mode & 15 != 0{
            return .bldc
        }else {
            return .foc
        }
    }
    
    static func intToWorkModeWithL6(_ mode : Int) -> WorkMode {
        if mode & 240 != 0{
            return .lock
        }else {
            return .unlock
        }
    }
    
    
    static func IntToWorkMode(_ mode : Int) -> WorkMode {
        
        let v = mode & 0xF
        
        switch (v) {
            
        case 0 :
            return .idle
            
        case 1:
            return .drive
            
        case 2:
            return .zero
            
        case 3:
            return .largeAngle
            
        case 4:
            return .checkc
            
        case 5:
            return .lock
            
        case 6:
            return .error
            
        case 7:
            return .carry
            
        case 8:
            return .remoteControl
            
        case 9:
            return .shutdown
            
        case 16:
            return .pomStop
            
        default:
            return .unknown
        }
        
    }
    
    static func byteToModel(_ data : [UInt8]) -> Model {
        
        if data.count < 108{
            return .UNKNOWN
        }
        
        switch (data[107]){
            
        case 0:     // Model R1
            switch(data[104]){
                
            case 0:
                return .R1N
                
            case 1:
                return .R1S
                
            case 2:
                return .R1CF
                
            case 3:
                return .R1AP
                
            case 4:
                return .R1EX
                
            case 5:
                return  .R1Sample
                
            case 6:
                return .R1T
                
            case 7:
                return .R10
                
            default:
                return .UNKNOWN
                
            }
            
        case 1:         // Model V3
            switch(data[104]){
                
            case 1:
                return .V3C
                
            case 2:
                return .V3PRO
                
            case 3:
                return .V3S
                
            default:
                return .V3
                
                
                
            }
            
        case 2:         // Model R2
            switch(data[104]){
                
            case 1:
                return .R2
                
            case 4:
                return .R2EX
                
            default:
                return .R2
                
            }
            
        case 3:     // Model R0
            return .R0
            
        case 5:     // Model V5
            switch(data[104]){
            case 1:
                return .V5PLUS
                
            case 2:
                return .V5F
                
            default:
                return .V5
            }
            
        case 6:
            return .L6
            
        case 8:     // Model V5
            return .V8
            
            
        default:
            return .UNKNOWN
            
        }
    }
    
    static func toHexString(_ buffer :[UInt8]) -> String{
        
        var str = "["
        
        var comma = false
        
        for c in buffer{
            
            if comma {
                str += ", "
            }
            
            str += String(format: "%02X", c)
            comma = true
        }
        
        str += "]"
        
        return str
    }
    static func escape(_ buffer : [UInt8]) -> [UInt8]{
        
        var out : [UInt8] = []
        
        for c in buffer {
            if c == 0xAA || c == 0x55 || c == 0xA5 {
                out.append(0xA5)
            }
            out.append(c)
        }
        
        return out
        
    }
    
    static func unescape(_ buffer : [UInt8]) -> [UInt8]{
        
        var out : [UInt8] = []
        var oldc : UInt8 = 0
        
        for c in buffer {
            if c != 0xA5 || oldc == 0xA5 {
                out.append(c)
            }
            oldc = c
        }
        return out
    }
    static func computeCheck(_ buffer : [UInt8]) -> UInt8{
        
        var check : Int = 0
        for c in buffer{
            check = (check + Int(c)) % 256
            
        }
        
        return UInt8(check)
    }
    
    static func IntFromBytes(_ bytes : [UInt8], starting: Int) -> UInt{
        
        if bytes.count >= starting+4{
            
            return UInt(bytes[starting]) + UInt(bytes[starting + 1]) * 256 + UInt(bytes[starting + 2]) * 256 * 256 + UInt(bytes[starting + 3]) * 256 * 256 * 256
        }else{
            return 0
        }
        
        
    }
    
    static func LongFromBytes(_ bytes : [UInt8], starting: Int) -> UInt64{
        
        if bytes.count >= starting+8{
            
            return UInt64(bytes[starting]) +
                UInt64(bytes[starting + 1]) * 256 +
                UInt64(bytes[starting + 2]) * 256 * 256 +
                UInt64(bytes[starting + 3]) * 256 * 256 * 256 +
                UInt64(bytes[starting + 5]) * 256 * 256 * 256 * 256 +
                UInt64(bytes[starting + 6]) * 256 * 256 * 256 * 256 * 256 +
                UInt64(bytes[starting + 7]) * 256 * 256 * 256 * 256 * 256 * 256
            
        }else{
            return 0
        }
    }
    
    
    static func SignedIntFromBytes(_ bytes : [UInt8], starting: Int) -> Int{
        
        if bytes.count >= starting+4{
            
            let v = Int64(bytes[starting]) + Int64(bytes[starting + 1]) * 256 + Int64(bytes[starting + 2]) * 256 * 256 + Int64(bytes[starting + 3]) * 256 * 256 * 256
            
            var value : Int = 0
            
            let imax : Int64 = 2147483648
            let uimax : Int64 = 4294967296
            
            if v >= imax {        // No tinc clar que funcioni
                let v1 = v - uimax
                value = Int(v1)
            }else {
                value = Int(v)
            }
            return value
        }else{
            return 0
        }
    }
    
    static func IsCarTypeBelongToInputType(carType : String, type : String) -> Bool{
        
        
        let range = carType.startIndex..<carType.index(after: carType.startIndex)
        if type == "0"{
            
            if carType.characters.count == 1{
                return true
            }
            return false
        }else if (carType[range] == type && carType.lengthOfBytes(using: .utf8) == 2){
            return true
        }else{
            return false
        }
        
        
    }
    
    static func batteryFromVoltage(_ volts : Double, model : Model) -> Double{
        
        var batt = 1.0
        
        if IsCarTypeBelongToInputType(carType: model.rawValue, type: "1"){
            
            if volts >= 83.50 {
                batt = 1.0
            } else if volts <= 68.5{
                batt = 0
            } else {
                batt = (volts - 68.5) / 15.0
            }
        } else if IsCarTypeBelongToInputType(carType: model.rawValue, type: "5"){
            
            if volts >= 83.50 {
                batt = 1.0
            }else if volts > 80.0{
                batt = ((volts - 80.0) / 3.5) * 0.2 + 0.8
            }else if volts > 77.0{
                batt = ((volts - 77.0) / 3.0) * 0.2 + 0.6
            }else if volts > 74.0{
                batt = ((volts - 74.0) / 3.0) * 0.2 + 0.4
            }else if volts > 71.0{
                batt = ((volts - 71.0) / 3.0) * 0.2 + 0.2
            }else if volts > 55.0{
                batt = ((volts - 55.0) / 16.0) * 0.2
            }else {
                batt = 0.0
            }
        } else if IsCarTypeBelongToInputType(carType: model.rawValue, type: "8"){
            
            if volts >= 83.50 {
                batt = 1.0
            }else if volts > 80.0{
                batt = ((volts - 80.0) / 3.5) * 0.2 + 0.8
            }else if volts > 77.0{
                batt = ((volts - 77.0) / 3.0) * 0.2 + 0.6
            }else if volts > 74.0{
                batt = ((volts - 74.0) / 3.0) * 0.2 + 0.4
            }else if volts > 71.0{
                batt = ((volts - 71.0) / 3.0) * 0.2 + 0.2
            }else if volts > 55.0{
                batt = ((volts - 55.0) / 16.0) * 0.2
            }else {
                batt = 0.0
            }
        } else if model == .R0 {
            if volts >= 82.00 {
                batt = 1.0
            }else if volts > 80.0{
                batt = ((volts - 80.0) / 2.0) * 0.25 + 0.75
            }else if volts > 77.0{
                batt = ((volts - 77.0) / 3.0) * 0.25 + 0.5
            }else if volts > 72.5{
                batt = ((volts - 72.50) / 5.2) * 0.25 + 0.25
            }else if volts > 70.5{
                batt = ((volts - 70.5) / 2.0) * 0.25
            }else {
                batt = 0.0
            }
        } else if model == .UNKNOWN{
            if volts >= 83.50 {
                batt = 1.0
            }else if volts > 80.0{
                batt = ((volts - 80.0) / 3.5) * 0.2 + 0.8
            }else if volts > 77.0{
                batt = ((volts - 77.0) / 3.0) * 0.2 + 0.6
            }else if volts > 74.0{
                batt = ((volts - 74.0) / 3.0) * 0.2 + 0.4
            }else if volts > 71.0{
                batt = ((volts - 71.0) / 3.0) * 0.2 + 0.2
            }else if volts > 55.0{
                batt = ((volts - 55.0) / 16.0) * 0.2
            }else {
                batt = 0.0
            }
        }else {
            
            if volts >= 82.00 {
                batt = 1.0
            }else if volts > 77.8{
                batt = ((volts - 77.8) / 4.2) * 0.2 + 0.8
            }else if volts > 74.8{
                batt = ((volts - 74.8) / 3.0) * 0.2 + 0.6
            }else if volts > 71.8{
                batt = ((volts - 71.8) / 3.0) * 0.2 + 0.4
            }else if volts > 70.3{
                batt = ((volts - 70.3) / 1.5) * 0.2 + 0.2
            }else if volts > 68.0{
                batt = ((volts - 68.0) / 2.3) * 0.2
            }else {
                batt = 0.0
            }
            
        }
        
        return batt * 100.0
        
    }
    
    static func verify(_ buffer : [UInt8]) -> (Bool, CANMessage?, UInt8){
        
        if buffer[0] != 0xAA || buffer[1] != 0xAA || buffer[buffer.count-1] != 0x55 || buffer[buffer.count-2] != 0x55 {
            return (false, nil, 0)  // Header and tail not correct
        }
        
        var dataBuffer = Array(buffer[2...buffer.count-4])
        
        dataBuffer = BLEInMotionAdapter.unescape(dataBuffer)
        let check = BLEInMotionAdapter.computeCheck(dataBuffer)
        
        let bufferCheck = buffer[buffer.count-3]
        
        let adata = CANMessage(dataBuffer)
        
        return (check == bufferCheck, adata, check)
    }
    
    
    
    
    //MARK: Sending Requests
    
    func pushRequest(){
        
        while queryQueue.operationCount < 1{
            
            queryQueue.addOperation {
                let date = Date()
                if date.timeIntervalSince(self.lastDateSent) > self.timerStep {
                    self.sendData()
                    self.lastDateSent = Date()
                    self.pushRequest()
                }
            }
        }
    }
    
    func sendData(){
        
        if let conn = self.connection, conn.state == .connected{
            let data : CANMessage
            
            switch state {
                
            case .disconnected:
                
                // AppDelegate.debugLog("Sending identification query")
                
                
                var pwd : [UInt8] = [48, 48, 48, 48, 48, 48]
                let store = UserDefaults.standard
                if let pw = store.string(forKey: kPassword){
                    
                    if pw == ""{
                        if let wh = wheel {
                            pwd = Array<UInt8>(wh.password.utf8)
                        }
                    } else {
                        pwd = Array<UInt8>(pw.utf8)
                    }
                    
                }
                
                
                data = CANMessage.getCheckPassword(pwd)
                
            case .identified:
                // AppDelegate.debugLog("Sending slow query")
                data = CANMessage.getSlowData()
                nTimes = 0
                
            case .connected:
                // AppDelegate.debugLog("Sending fast query")
                data = CANMessage.getFastData()
                nTimes += 1
            }
            
            if let dat = data.toNSData(){
                conn.writeValue("FFE9", data: dat)
            }
        }
    }
    
    func sendMessage(_ data : CANMessage){
        
        if let dat = data.toNSData(), let conn = self.connection, conn.state == .connected{
            conn.writeValue("FFE9", data: dat)
        }
    }
    
    
    //MARK: BLEWheelAdapterProtocol Extension
    
    
    func wheelName() -> String {
        return "InMotion"
    }
    
    func isComptatible(services : [String : BLEService]) -> Bool{
        if let srv = services["FFE0"], let srv1 = services["FFE5"]{
            if let _ = srv.characteristics["FFE4"], let _ = srv1.characteristics["FFE9"] {
                return true
            }
        }
        
        return false
    }
    
    
    func startRecording(){
        state = .disconnected
        
        
    }
    
    func stopRecording(){
        
        state = .disconnected
        
    }
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        self.connection = connection
        
        // try to recover info from the database
        
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
            wheel!.brand = "Inmotion"
            wheel!.password = pwd
            database.setWheel(wheel: wheel!)
        }
        
        connection.subscribeToChar("FFE4")
        
        unpacker.reset()
        pushRequest()
        
    }
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        queryQueue.cancelAllOperations()
        state = .disconnected
    }
    
    func giveTime(_ connection: BLEMimConnection) {
        
        if connection.state == .connected {
            pushRequest()
        }
    }
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        var outValues : [(WheelTrack.WheelValue, Date, Double)] = []
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        let buf1 = buf
        let date = Date()
        for c in buf1 {
            if unpacker.addChar(c){
                
                let (result, adata, _) = BLEInMotionAdapter.verify(unpacker.buffer)
                
                if result{ // data OK
                    if let data = adata {
                        
                        
                        switch (data.id){
                            
                        case .CheckPassword:
                            
                            if data.data[0] == 1 {
                                state = .identified
                            }
                            
                        case .GetFastInfo:
                            
                            let vals = data.parseFastInfoMessage(model)
                            outValues.append(contentsOf: vals)
                            
                            // OK now get distance value
                            
                            var distance : Double = 0.0
                            
                            for (vv, date, value) in outValues {
                                
                                if vv == WheelTrack.WheelValue.AcumDistance {
                                    
                                    
                                    if let fd = firstDistance {
                                        distance = value - fd
                                        
                                    }else {
                                        firstDistance = value
                                        distance = 0.0
                                    }
                                    
                                    outValues.append((WheelTrack.WheelValue.Distance, date, distance))
                                }
                                
                            }
                            
                        case .GetSlowInfo:
                            var vmax = 0.0
                            (serialNumber, model, version, vmax) = data.parseSlowInfoMessage()
                            AppDelegate.debugLog("SN %@ Model %@ version %@", serialNumber, model.rawValue, version)
                            
                            if let wh = self.wheel {    // Update wheel data
                                
                                let db = WheelDatabase.sharedInstance
                                wh.model = model.rawValue
                                wh.serialNo = serialNumber
                                wh.version = version
                                db.setWheel(wheel: wh)
                                
                            }
                            
                            BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
                            
                            outValues.append((WheelTrack.WheelValue.MaxSpeed, date, vmax))
                            
                            state = .connected
                            
                            
                        default:
                            break;
                            
                        }
                        
                        outValues.append((WheelTrack.WheelValue.Duration, date, 0.0))
                        
                        //AppDelegate.debugLog("%f", Date().timeIntervalSince1970)
                        
                        
                    }
                }
            }
        }
        
        pushRequest()
        return outValues   // Will process when we get everything ok
        
    }
    
    
    func getName() -> String{
        return name
    }
    
    func getVersion() -> String{
        
        return version
    }
    
    func getSN() -> String{
        
        return serialNumber
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
        
    }
    
    func setLights(_ level: Int) {   // 0->Off 1->On....
        
        let msg = CANMessage.setLights(level == 1)
        self.sendMessage(msg)
    }
    
    func setLimitSpeed(_ speed : Double){
    }
    
    func enableLimitSpeed(_ enable : Bool)   {   // Enable or disable speedLimit
    }
    
    func lockWheel(_ lock : Bool){ // Lock or Unlock wheel
        
        let msg = CANMessage.setLights(lock)
        self.sendMessage(msg)
        
        
        queryQueue.addOperation {
            
            let b : UInt8 = lock ? 3 : 4
            let msg = CANMessage.setMode(b)
            self.sendMessage(msg)
        }
    }
}


