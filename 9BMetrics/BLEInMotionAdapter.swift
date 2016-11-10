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
    
    var f9865a : Int = 0
    var message : [UInt8] = Array(repeating: 0, count: 8)
    var f9867c : UInt8 = 0
    var f9868d : UInt8 = 0
    var f9869e : Int = 1
    var f9870f : Int = 1
    var dades : [UInt8]?
    var buffer : [UInt8] = Array(repeating: 0, count: 16)
    
    init(){
        
    }
    
    init(_ bArr : [UInt8]){
        
        f9865a = (((Int(bArr[3]) * 256) + Int(bArr[2])) * 256 + Int(bArr[1])) * 256 + Int(bArr[0])
        message = Array(bArr[4..<12])
        f9867c = bArr[12]
        f9868d = bArr[13]
        f9869e = bArr[14] == 0 ? 1 : 2
        f9870f = bArr[15] == 0 ? 1 : 2
        
        if f9867c == 0xFE {
            let ldata = (((Int(message[3]) * 256) + Int(message[2])) * 256 + Int(message[1])) * 256 + Int(message[0])
            
            if ldata == bArr.count - 16 {
                dades = Array(bArr[16..<16+ldata])
            }
        }
    }
    
    func toData() -> [UInt8]{
        
        var buff : [UInt8] = []
        
        let b3 = UInt8(f9865a / (256 * 256 * 256))
        let b2 = UInt8((f9865a - Int(b3) * 256 * 256 * 256) / (256 * 256))
        
        let b1 = UInt8((f9865a - Int(b3) * 256 * 256 * 256 - Int(b2) * 256 * 256) / 256)
        let b0 = UInt8(f9865a % 256)
        
        buff.append(b0)
        buff.append(b1)
        buff.append(b2)
        buff.append(b3)
        
        buff.append(contentsOf: message)
        buff.append(f9867c)
        buff.append(f9868d)
        
        buff.append(UInt8(f9869e == 1 ? 0 : 1))
        buff.append(UInt8(f9870f == 1 ? 0 : 1))
        
        if let dat = dades{
            
            if f9867c == 0xFE {
                buff.append(contentsOf: dat)
            }
        }
        
        
        
        return buff
    }
    
    func writeBuffer() -> [UInt8]{
        
        let canBuffer = toData()
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

    
    static func standardMessage() -> CANMessage {
        let msg = CANMessage()
        
        msg.f9867c = 8
        msg.f9865a = 0x0F550113
        msg.f9868d = 5
        msg.message = [24,0,1,0,0,0,0,0]
        
        return msg
        
    }
    
    static func getBatteryLevelsMessage() -> CANMessage {
        let msg = CANMessage()
        
        msg.f9867c = 8
        msg.f9865a = 0x0F550114
        msg.f9868d = 5
        msg.f9870f = 2
        
        msg.message = [0, 0, 0, 15, 0, 0, 0, 0]
        
        return msg
        
    }
    
    static func getSerialNumberMessage() -> CANMessage {
        let msg = CANMessage()
        
        msg.f9867c = 8
        msg.f9865a = 0x0F550114
        msg.f9868d = 5
        msg.f9870f = 2
        
        msg.message = [33, 0, 0, 2, 0, 0, 0, 0]
        
        return msg
        
    }


    
}

class BLEInMotionAdapter : NSObject, BLEWheelAdapterProtocol {
    
    var headersOk = false
    var sendTimer : Timer?    // Timer per enviar les dades periodicament
    var timerStep = 0.5        // Get data every step
    var unpacker = BLEInMotionUnpacker()    // Create as unpacker
    var connection : BLEMimConnection?
    var name : String = "InMotion"
    
    override init(){
        super.init()
        
    }
    
    //MARK: Auxiliary Functions
    
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
            
            if v >= 2147483648 {
                value = Int(Int64(v) - Int64(4294967296))
            }else {
                value = Int(v)
            }
            return value
        }else{
            return 0
        }
        
        
    }

    static func verify(_ buffer : [UInt8]) -> (Bool, CANMessage?, UInt8){
        
        if buffer[0] != 0xAA || buffer[1] != 0xAA || buffer[buffer.count-1] != 0x55 || buffer[buffer.count-2] != 0x55 {
            return (false, nil, 0)  // Header and tail not correct
        }
        
        var dataBuffer = Array(buffer[2...buffer.count-4])
        
        dataBuffer = BLEInMotionAdapter.unescape(dataBuffer)
        let check = BLEInMotionAdapter.computeCheck(dataBuffer)
        
        let bufferCheck = buffer[buffer.count-3]
        
        let aMessage = CANMessage(dataBuffer)
        
        return (check == bufferCheck, aMessage, check)
    }

    
    
    
    //MARK: Sending Requests
    
    func sendData(_ connection : BLEMimConnection){

        let message = CANMessage.standardMessage()
        if let data = message.toNSData(){
            connection.writeValue("FFE9", data: data)
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
        
        if #available(iOS 10.0, *) {
            sendTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { (tim : Timer) in
                if let conn = self.connection {
                    self.sendData(conn)
                }
            })
        } else {
            // Fallback on earlier versions
        }
    }
    
    func stopRecording(){
        if let tim  = sendTimer {
            tim.invalidate()
            sendTimer = nil
        }
    }
 
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        self.connection = connection
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FFE4")
        startRecording()
        BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)
        
        
    }
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
            stopRecording()
    }
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        var outValues : [(WheelTrack.WheelValue, Date, Double)] = []
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        let date = Date()
        for c in buf {
            if unpacker.addChar(c){
                
                let (result, aMessage, _) = BLEInMotionAdapter.verify(unpacker.buffer)
                
                if result{ // Message OK
                    if let message = aMessage {
                        
                        // AppDelegate.debugLog("%@", BLEInMotionAdapter.toHexString(message.toData()))
                         if let dat = message.dades {
                            
                            
                            let v0 = BLEInMotionAdapter.SignedIntFromBytes(dat, starting: 0)
                            let v1 = BLEInMotionAdapter.SignedIntFromBytes(dat, starting: 4)
                            
                            let speed = fabs(Double(v0 + v1 )/3812.0 / 2.0)     // 3812 es un numero màgic. No tinc clar de on ve
                            outValues.append((WheelTrack.WheelValue.Speed, date, speed))
                            //AppDelegate.debugLog("Speed : %ld - %ld", v0, v1)
                            outValues.append((WheelTrack.WheelValue.Duration, date, 0.0))  // Necessary yo have duration values
                            
                        }
                    }
                }
            }
        }
        
        return outValues   // Will process when we get everything ok
    
    }
    
    
    func getName() -> String{
        return name
    }
    
    func getVersion() -> String{
        
        return "v0"
    }
    
    func getSN() -> String{
        
        return "SN000001"
    }
    
    func setDefaultName(_ name : String){
        self.name = name
    }
}


