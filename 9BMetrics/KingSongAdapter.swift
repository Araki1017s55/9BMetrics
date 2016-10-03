//
//  BLENinebotOneAdapter.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 4/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import Foundation
import CoreBluetooth

class KingSongAdapter : NSObject {
    
    var headersOk = false
    var sendTimer : Timer?    // GotaTimer per enviar les dades periodicament
    var timerStep = 0.1        // Get data every step
    var contadorOp = 0          // Normal data updated every second
    var contadorOpFast = 0      // Special data updated every 1/10th of second
    var listaOp :[(UInt8, UInt8)] = [(50,2), (58,1),  (62, 1), (182, 5)]
    // var listaOpFast :[(UInt8, UInt8)] = [(38,1), (80,1), (97,4), (34,4), (71,6)]
    
    var listaOpFast :[(UInt8, UInt8)] = [(97,2), (188,2), (180,2)]
    
    var buffer : [UInt8] = []
    
    var queryQueue : OperationQueue?
    
    static var conversion = Array<WheelTrack.WheelValue?>(repeating: nil, count: 256)
    static var scales = Array<Double>(repeating: 1.0, count: 256)
    static var signed = [Bool](repeating: false, count: 256)
    
    var values : [Int] = Array(repeating: -1, count: 256)
    
    var name = ""
    var serial = ""
    
    
    // Called when lost connection. perhaps should do something. If not forget it
    
    
    // Data Received. Analyze, extract, convert and prosibly return a dictionary of characteristics and values
    
    
    // Called by connection when we got device characteristics
    
    override init(){
        super.init()
        
    }
    
    
    //MARK: Receiving Data. Append data to buffer
    
    func appendToBuffer(_ data : Data){
        
        let count = data.count
        var buf = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buf, length:count * MemoryLayout<UInt8>.size)
        buffer.removeAll()
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
    
    // KingSong sends buffers containing all the information in one buffer
    
    func procesaBuffer(_ connection: BLEMimConnection) -> [(WheelTrack.WheelValue, Date, Double)]?
    {
        // Wait till header. We wait till we find a 0x55
        
        
        var outarr : [(WheelTrack.WheelValue, Date, Double)] = []
        
        while buffer.count > 0 && buffer[0] != 0xAA {
            buffer.removeFirst()
        }
        
        // Following character must be 0xaa, if not is noise
        
        
        if buffer.count < 10{    // Wait for more data
            return outarr
        }
        
        if buffer[1] != 0x55 {  // Fals header. continue cleaning
            
            return outarr
        }
        
        let date = Date()
        let block = Array(buffer)
        // We have 20 bytes and 10 bytes buffers
        
        switch(buffer.count){
            
        case 10:
            
            
            let totalDistance = Double( (Int(buffer[9]) * 256 + Int(buffer[8]))*65536 + (Int(buffer[7]) * 256 + Int(buffer[6])))
            outarr.append((WheelTrack.WheelValue.AcumDistance, date, totalDistance))
            
            buffer.removeAll()
            break
            
        case 20:
            switch(buffer[16]){
                
            case 169:
                let speed = Double(Int(buffer[5]) * 256 + Int(buffer[4])) / 360.0  // Ajusta precissio i km/h a m/s
                //let speed = Double(Int(block[5]) * 256 + Int(block[4]))
                outarr.append((WheelTrack.WheelValue.Speed, date, speed))
                
                let temperature = Double(Int(buffer[13]) * 256 + Int(buffer[12])) / 100.0 // Very strange conversion in Kevin program
                outarr.append((WheelTrack.WheelValue.Temperature, date, temperature))
                
                let totalDistance = Double( (Int(buffer[9]) * 256 + Int(buffer[8]))*65536 + (Int(buffer[7]) * 256 + Int(buffer[6])))
                outarr.append((WheelTrack.WheelValue.AcumDistance, date, totalDistance))
                
                let voltage = Double(Int(buffer[3]) * 256 + Int(buffer[2])) / 100.0
                outarr.append((WheelTrack.WheelValue.Voltage, date, voltage))
                
                let current = Double(Int(buffer[11]) * 256 + Int(buffer[10])) / 100.0
                outarr.append((WheelTrack.WheelValue.Current, date, current))
                
                var battery = 0.0
                // Compute battery from voltage
                
                if (voltage < 50.0) {
                    battery = 0.0;
                } else if (voltage >= 66.0) {
                    battery = 100.0;
                } else {
                    battery = (voltage - 50.0) / 16.0 * 100.0;
                }
                
                
                /* Gotaway
                
                if voltage <= 52.90 {
                    battery = 0.0
                }else if (voltage >= 65.80){
                    battery = 100.0
                }else {
                    battery = ((voltage - 52.90) / 13.0) * 100.0
                }
 */
                
                outarr.append((WheelTrack.WheelValue.Battery, date, battery))
                buffer.removeAll()
                
                
                break
                
            case 185:
                let distance = Double( (Int(buffer[3]) * 256 + Int(buffer[2]))*65536 + (Int(buffer[5]) * 256 + Int(buffer[4])))
                outarr.append((WheelTrack.WheelValue.Distance, date, distance))
                
                let time = Double(Int(buffer[7]) * 256 + Int(buffer[6]))
                outarr.append((WheelTrack.WheelValue.Duration, date, time))
                
            case 187:
                var lname = ""
                
                var i = 2
                
                while i < 14 && block[i] != 0{
                    lname.append(Character(UnicodeScalar(block[i])))

                    i += 1
                }
                
                self.name = lname
 
                askSerial(connection)

            case 179:
                
                var lserial = ""
                var i = 2
                
                while i < 14 {
                    lserial.append(Character(UnicodeScalar(block[i])))
                    i += 1
                }
                
                i = 17
                while i < 20 {
                    lserial.append(Character(UnicodeScalar(block[i])))
                    i += 1
                }
                self.serial = lserial
                BLESimulatedClient.sendNotification(BLESimulatedClient.kHeaderDataReadyNotification, data:nil)

            default:
                break
                
            }
            
            
        default:
            break
            
            
        }
        return outarr
    }
    
    
    
    
}

//MARK: BLEWheelAdapterProtocol Extension

extension KingSongAdapter : BLEWheelAdapterProtocol{
    
    
    func wheelName() -> String {
        return "Kingsong"
    }
    
    
    // Hem de possar quelcom per diferenciar-lo del Ninebot!!!
    
    func isComptatible(services : [String : BLEService]) -> Bool{
        
        if let srv = services["FFE0"], let srv2 = services["FFF0"] , let srv3 = services["180A"]{
            if let chr = srv.characteristics["FFE1"]  {
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
    
    func askName(_ connection: BLEMimConnection, peripheral : CBPeripheral){
        // Write buffer
        
        var command : [UInt8] = Array(repeating: 0, count: 20)
        
        command[0] = 170
        command[1] = 85
        command[16] = 155
        command[17] = 20
        command[18] = 90
        command[19] = 90
        
        let data = Data(bytes: UnsafePointer<UInt8>(command), count: command.count)
        
        connection.writeValue("FFE1", data : data)
        
    }
    
    func askSerial(_ connection: BLEMimConnection){
        // Write buffer
        
        var command : [UInt8] = Array(repeating: 0, count: 20)
        
        command[0] = 170
        command[1] = 85
        command[16] = 99
        command[17] = 20
        command[18] = 90
        command[19] = 90
        
        let data = Data(bytes: UnsafePointer<UInt8>(command), count: command.count)
        
        connection.writeValue("FFE1", data : data)
        
    }
    
    func deviceConnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        // OK, subscribe to characteristif FFE1
        
        connection.subscribeToChar("FFE1")
        
        askName(connection, peripheral: peripheral)
        
    }
    
    
    func deviceDisconnected(_ connection: BLEMimConnection, peripheral : CBPeripheral ){
        
        
    }
    
    func charUpdated(_ connection: BLEMimConnection,  char : CBCharacteristic, data: Data) -> [(WheelTrack.WheelValue, Date, Double)]?{
        
        self.appendToBuffer(data)
        return self.procesaBuffer(connection)
    }
    
    
    func getName() -> String{
        return self.name
    }
    
    func getVersion() -> String{
        
        return "1.0!"
    }
    
    func getSN() -> String{
        return self.serial
    }
}


