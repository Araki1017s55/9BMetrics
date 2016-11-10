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
        let check = computeCheck(canBuffer)
        
        var out : [UInt8] = [0xAA, 0xAA]
        
        out.append(contentsOf: escape(canBuffer))
        out.append(check)
        out.append(0x55)
        out.append(0x55)
        
        return out
        
        
    }
    
    static func standardMessage() -> CANMessage {
        let msg = CANMessage()
        
        msg.f9867c = 8
        msg.f9865a = 0x0F550113
        msg.f9868d = 5
        msg.message = [24,0,1,0,0,0,0,0]
        
        return msg
        
    }

}

var canMessage : CANMessage = CANMessage()

// Superfunction verify reads a buffer, checks check and returns a CANMessage

func verify(_ buffer : [UInt8]) -> (Bool, CANMessage?, UInt8){
    
    if buffer[0] != 0xAA || buffer[1] != 0xAA || buffer[buffer.count-1] != 0x55 || buffer[buffer.count-2] != 0x55 {
        return (false, nil, 0)  // Header and tail not correct
    }
    
    var dataBuffer = Array(buffer[2...buffer.count-4])
    
    dataBuffer = unescape(dataBuffer)
    let check = computeCheck(dataBuffer)
    
    let bufferCheck = buffer[buffer.count-3]
    
    let aMessage = CANMessage(dataBuffer)
    
    return (check == bufferCheck, aMessage, check)
}

// Funcio per a rebre caracters i generar un missatge

class Unpacker {
    
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
}

let (result, aMessage, check) = verify(buffer)

print(check)

if let message = aMessage {
    
    // Get som data from dades
    
    if let dat = message.dades {
        print(dat)
        
              // MyCarControlActivity Variables
        
        let v0 = IntFromBytes(dat, starting: 0)
        let v1 = IntFromBytes(dat, starting: 4)
        
        let speed = Double(v0 + v1) / (3812.0 * 2.0)
        
        let f6103j = IntFromBytes(dat, starting: 8)     // Must ckeck bits
        let f6104k = IntFromBytes(dat, starting: 8)     // Must check bits
        
        let batt = IntFromBytes(dat, starting: 24)
        
        
        
    }
    
    let canbuffer = message.writeBuffer()
    
    if canbuffer == buffer {
        print ("OK")
        
        
    }else {
        print("ERROR")
    }
    
}

let unpacker = Unpacker()

for c in buffer {
    if unpacker.addChar(c){
        let (res, am, ck) = verify(unpacker.buffer)
        print(ck)
    }else{
        print (".")
    }
}

// Try to generate standard message

let msg = CANMessage.standardMessage()

msg.toData()
toHexString(msg.writeBuffer())

