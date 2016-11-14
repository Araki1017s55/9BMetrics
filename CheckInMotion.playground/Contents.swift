//: Playground - noun: a place where people can play

/*
    Estructura dels missatges InMotion
 
    0xAA
    0xAA
    <Dades>
    <ck>
    0x55
    0x55
 
    Mida ha de ser inferior a 1024. S'envien en blocks de 20
    Quan dintre les dades hi ha un 0xAA, 0x55 o 0xA5 es fa un escape amb 0xA5. Es dir 0x55 s'escriu com 0xA5 0x55
    per no confondre amb el començament i final de  missatge.
 
    El check es calcula com la suma % 256 de las dades (sense els 0xAA i 0x55 i sense els 0xA5 dels escapes.
 
 */

import UIKit

var buffer : [UInt8] = [0xAA,0xAA,0x13,0x01,0xA5,0x55,0x0F,0x65,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xFE,
                        0x02,0x01,0x00,0x10,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x67,0x20,0x00,0x00,0x00,
                        0x00,0x00,0x00,0x19,0x19,0x1C,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xCD,
                        0xA1,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x1A,0x11,0x0F,0x1D,0x09,0xE0,0x07,0x21,
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x41,0x02,0x00,0x00,0x00,
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x18,0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                        0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0x19,0x2F,0x55,0x55]


func toHexString(_ buffer :[UInt8]) -> String{
    
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
func escape(_ buffer : [UInt8]) -> [UInt8]{
    
    var out : [UInt8] = []
    
    for c in buffer {
        if c == 0xAA || c == 0x55 || c == 0xA5 {
            out.append(0xA5)
        }
        out.append(c)
    }
    
    return out
    
}

func unescape(_ buffer : [UInt8]) -> [UInt8]{
    
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
func computeCheck(_ buffer : [UInt8]) -> UInt8{
    
    var check : Int = 0
    for c in buffer{
        check = (check + Int(c)) % 256
        
    }
    
    return UInt8(check)
}

func IntFromBytes(_ bytes : [UInt8], starting: Int) -> Int{
    
    if bytes.count >= starting+4{
        
        return Int(bytes[starting]) + Int(bytes[starting + 1]) * 256 + Int(bytes[starting + 2]) * 256 * 256 + Int(bytes[starting + 3]) * 256 * 256 * 256
    }else{
        return 0
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
        
        id = IDValue(rawValue: (((UInt(bArr[3]) * 256) + UInt(bArr[2])) * 256 + UInt(bArr[1])) * 256 + UInt(bArr[0]))!
        data = Array(bArr[4..<12])
        len = bArr[12]
        ch = bArr[13]
        format = bArr[14] == 0 ? .StandardFormat : .ExtendedFormat
        type = bArr[15] == 0 ? .DataFrame : .RemoteFrame
        
        if len == 0xFE {
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
        msg.data = [33, 0, 0, 2, 0, 0, 0, 0]
        
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
        msg.id = .RemoteControl
        msg.ch = 5
        msg.type = .DataFrame
        
        msg.data = [0xB2, 0, 0, 0, mode, 0, 0, 0]
        
        return msg
        
    }
    
    
    func parseFastInfoMessage(_ model : BLEInMotionAdapter.Model) -> [(Int, Date, Double)] {
        
        // Angle
        
        let d = Date()
        if let bytes = ex_data{
            let angle = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 0)) / 65536.0
            
            let speed = fabs((Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 12 )) + Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 16 ))) / (3812.0 * 2.0) )       // 3812.0 depen del tipus de vehicle
            
            let voltage = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 24)) / 100.0  // Falta conversio a battery level
            
            let batt = BLEInMotionAdapter.batteryFromVoltage(voltage, model: model)
            return [(1, d, angle),
                    (2, d, speed),
                    (3, d, voltage),
                    (4, d, batt)
            ]
            
        } else {
            return []
        }
        
        
    }
    
    // Return SerialNumber, Model, Version
    
    func parseSlowInfoMessage() -> (String, BLEInMotionAdapter.Model, String){
        if let bytes = ex_data{
            
            let serialNumber = String(String(bytes:bytes[0..<8], encoding : .utf8 )!.characters.reversed()) // Seems it is reversed!!!
            let model = BLEInMotionAdapter.byteToModel(bytes)  // CarType is just model.rawValue
            _ = model == .R1S ? "2" : "1"
            let v = BLEInMotionAdapter.IntFromBytes(bytes, starting: 24)
            let v0 = v / 0xFFFFFF
            let v1 = (v - v0 * 0xFFFFFF) / 0xFFFF
            let v2 = v - v0 * 0xFFFFFF - v1 * 0xFFFF
            let version = String(format:"%d.%d.%d", v0, v1, v2)
            
            return (serialNumber, model, version)
        }
        return ("", BLEInMotionAdapter.Model.UNKNOWN, "")
        
    }
}


class BLEInMotionAdapter {
    
    
    
    
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
    
    var headersOk = false
    var sendTimer : Timer?    // Timer per enviar les ex_data periodicament
    var timerStep = 0.5        // Get data every step
//    var unpacker = BLEInMotionUnpacker()    // Create as unpacker
   // var connection : BLEMimConnection?
    var name : String = "InMotion"
    var version : String = "0.0.0"
    var serialNumber : String = "SN1"
    var headerData  = false
    var queryQueue = OperationQueue()
    var model = Model.UNKNOWN
    var lastDateSent = Date()
    
    
    
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
                
            default:
                return .V5
            }
            
        case 6:
            return .L6
            
            
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
    
    static func SignedIntFromBytes(_ bytes : [UInt8], starting: Int) -> Int{
        
        if bytes.count >= starting+4{
            
            let v = UInt(bytes[starting]) + UInt(bytes[starting + 1]) * 256 + UInt(bytes[starting + 2]) * 256 * 256 + UInt(bytes[starting + 3]) * 256 * 256 * 256
            
            var value : Int = 0
            
            if v >= 2147483648 {        // No tinc clar que funcioni
                let v1 = v - 4294967295 - 1
                value = Int(v1)
            }else {
                value = Int(v)
            }
            return value
        }else{
            return 0
        }
        
        
    }
    static func isCarTypeBiggerThanInputType(carType : String, type : String) -> Bool{
        
        
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
        
        if isCarTypeBiggerThanInputType(carType: model.rawValue, type: "1"){
            
            if volts >= 83.50 {
                batt = 1.0
            } else if volts <= 68.5{
                batt = 0
            } else {
                batt = (volts - 68.5) / 15.0
            }
        } else if isCarTypeBiggerThanInputType(carType: model.rawValue, type: "5"){
            
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
        } else {
            
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
}

let (result, aMessage, check) = BLEInMotionAdapter.verify(buffer)

print(check)

if let message = aMessage {
    
    // Get som data from dades
        let answer = message.parseFastInfoMessage(.V3)
    
    for c in answer{
        print(c)
    }
}

