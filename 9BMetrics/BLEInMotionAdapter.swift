//
//  BLEInMotionAdapter
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

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
    
    
    func parseFastInfoMessage(_ model : BLEInMotionAdapter.Model) -> [(WheelTrack.WheelValue, Date, Double)] {
        
        // Angle
        
        let d = Date()
        if let bytes = ex_data{
            let angle = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 0)) / 65536.0
            
            let speed = fabs((Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 12 )) + Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 16 ))) / (3812.0 * 2.0) )       // 3812.0 depen del tipus de vehicle
            
            let voltage = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 24)) / 100.0
            let current = Double(BLEInMotionAdapter.SignedIntFromBytes(bytes, starting: 20)) / 100.0
            let power = voltage * current
 
            var distance = Double(BLEInMotionAdapter.IntFromBytes(bytes, starting: 44))

            if BLEInMotionAdapter.IsCarTypeBelongToInputType(carType: model.rawValue, type: "1") ||
                BLEInMotionAdapter.IsCarTypeBelongToInputType(carType: model.rawValue, type: "5"){
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44))
            }else if model == .R0 {
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44))
                
            }else if model == .L6 {
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44)) * 100.0
                
            }else {
                distance = Double(BLEInMotionAdapter.LongFromBytes(bytes, starting: 44)) / 5.711016379455429E4
            }
            
            let batt = BLEInMotionAdapter.batteryFromVoltage(voltage, model: model)
            return [(WheelTrack.WheelValue.Pitch, d, angle),
                    (WheelTrack.WheelValue.Speed, d, speed),
                    (WheelTrack.WheelValue.Voltage, d, voltage),
                    (WheelTrack.WheelValue.Battery, d, batt),
                    (WheelTrack.WheelValue.Current, d, current),
                    (WheelTrack.WheelValue.Power, d, power),
                    (WheelTrack.WheelValue.AcumDistance, d, distance)
                
                
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
    var timerStep = 0.4        // Get data every step
    var unpacker = BLEInMotionUnpacker()    // Create as unpacker
    var connection : BLEMimConnection?
    var name : String = "InMotion"
    var version : String = "0.0.0"
    var serialNumber : String = "SN1"
    var headerData  = false
    var queryQueue = OperationQueue()
    var model = Model.UNKNOWN
    var lastDateSent = Date()
    var firstDistance : Double? // gets first distance. It is used to conunt differences and actual distance
    
    
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
    
    
    
    
    //MARK: Sending Requests
    
    func pushRequest(){
        
        while queryQueue.operationCount < 4{
 
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
        
        let data : CANMessage
        
        if headersOk {
            AppDelegate.debugLog("Sending fast query")
            data = CANMessage.getFastData()
        }else {
            AppDelegate.debugLog("Sending slow query")
            data = CANMessage.getSlowData()
        }
        
        if let data = data.toNSData(), let conn = self.connection{
            conn.writeValue("FFE9", data: data)
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
        unpacker.reset()
        pushRequest()
    }
    
    func stopRecording(){
        
     }
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        self.connection = connection
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FFE4")
        startRecording()
        
        
    }
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        stopRecording()
    }
    
    func giveTime(_ connection: BLEMimConnection) {
        pushRequest()
    }
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        var outValues : [(WheelTrack.WheelValue, Date, Double)] = []
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        let date = Date()
        for c in buf {
            if unpacker.addChar(c){
                
                let (result, adata, _) = BLEInMotionAdapter.verify(unpacker.buffer)
                
                if result{ // data OK
                    if let data = adata {
                        
                        
                        switch (data.id){
                            
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
                            
                            (serialNumber, model, version) = data.parseSlowInfoMessage()
                             AppDelegate.debugLog("SN %@ Model %@ version %@", serialNumber, model.rawValue, version)
                            headersOk = true
                            BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
                            
                        default:
                            break;
                            
                        }
                        
                        outValues.append((WheelTrack.WheelValue.Duration, date, 0.0))

                        
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
    
    func setDefaultName(_ name : String){
        self.name = name
    }
}


