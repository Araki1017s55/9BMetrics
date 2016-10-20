//
//  BLENinebot.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 2/2/16.
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
// BLENinebot represents the state of the wheel
//
//  It really is aan array simulating original description
//
//  It is an Int array
//
//  Also provides a log of information as a log array that may be saved.
//
//  Methods are provided to interpret labels and get most information in correct units
//
//  Usually there is just one object just for the current wheel
//
//

import UIKit
import MapKit


class  BLENinebot : NSObject{
    
    
    
    struct LogEntry {
        var time : Date
        var variable : Int
        var value : Int
    }
    
    struct DoubleLogEntry {
        var time : Date
        var variable : Int
        var value : Double

    }
    
    struct NinebotVariable {
        var codi : Int = -1
        var timeStamp : Date = Date()
        var value : Int = -1
        var log : [LogEntry] = [LogEntry]()
        
    }
    
    struct IndexEntry {
        var subIndex : [IndexEntry] = [IndexEntry]()
    }
    
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
    
    static var  labels = Array<String>(repeating: "?", count: 256)
    static var conversion = Array<WheelTrack.WheelValue?>(repeating: nil, count: 256)
    
    
    
    
    
    
    
    
    
    
    
    
    static var displayableVariables : [Int] = [BLENinebot.kCurrentSpeed, BLENinebot.kTemperature,
                                               BLENinebot.kVoltage, BLENinebot.kCurrent, BLENinebot.kBattery, BLENinebot.kPitchAngle, BLENinebot.kRollAngle,
                                               BLENinebot.kvSingleMileage, BLENinebot.kAltitude, BLENinebot.kPower, BLENinebot.kEnergy]
    
    fileprivate var data = [NinebotVariable](repeating: NinebotVariable(), count: 256)
    var signed = [Bool](repeating: false, count: 256)
    
    var headersOk = false
    var firstDate : Date?
    
    var distOffset = 0  // Just to support stop start without affecting total distance. We supose we start at same place we stopped
    
    var otherFormatter : DateFormatter = DateFormatter()
    
    
    override init(){
        
        if BLENinebot.labels[37] == "?"{
            BLENinebot.initNames()
        }
        super.init()
        
        for i in 0..<256 {
            data[i].codi = i
        }
        
        signed[BLENinebot.kPitchAngle] = true
        signed[BLENinebot.kRollAngle] = true
        signed[BLENinebot.kPitchAngleVelocity] = true
        signed[BLENinebot.kRollAngleVelocity] = true
        signed[BLENinebot.kCurrent] = true
        signed[BLENinebot.kvPitchAngle] = true
        
        self.otherFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        self.otherFormatter.timeZone = TimeZone(abbreviation: "UTC")
        self.otherFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
        
        
        
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

    }
    
    static func initNames(){
        BLENinebot.labels[0]  = "Alt Var(m)"
        BLENinebot.labels[1]  = "Power(W)"
        BLENinebot.labels[2]  = "Energy(wh)"
        BLENinebot.labels[3]  = "Latitude"
        BLENinebot.labels[4]  = "Longitude"
        BLENinebot.labels[5]  = "Altitude GPS"
        BLENinebot.labels[6]  = "Speed GPS"
        BLENinebot.labels[16]  = "SN0"
        BLENinebot.labels[17]  = "SN1"
        BLENinebot.labels[18]  = "SN2"
        BLENinebot.labels[19]  = "SN3"
        BLENinebot.labels[20]  = "SN4"
        BLENinebot.labels[21]  = "SN5"
        BLENinebot.labels[22]  = "SN6"
        BLENinebot.labels[23]  = "BTPin0"
        BLENinebot.labels[24]  = "BTPin1"
        BLENinebot.labels[25]  = "BTPin2"
        BLENinebot.labels[26]  = "Version"
        BLENinebot.labels[34]  = "Batt (%)"
        BLENinebot.labels[37]  = "Remaining Mileage"
        BLENinebot.labels[38]  = "Speed (Km/h)"
        BLENinebot.labels[41]  = "Total Mileage 0"
        BLENinebot.labels[42]  = "Total Mileage 1"
        BLENinebot.labels[50]  = "Total Runtime 0"
        BLENinebot.labels[51]  = "Total Runtime 1"
        BLENinebot.labels[58]  = "Single Runtime"
        BLENinebot.labels[62]  = "T (ºC)"
        BLENinebot.labels[71]  = "Voltage (V)"
        BLENinebot.labels[80]  = "Current (A)"
        BLENinebot.labels[97]  = "Pitch (º)"
        BLENinebot.labels[98]  = "Roll (º)"
        BLENinebot.labels[99]  = "Pitch Angle Angular Velocity"
        BLENinebot.labels[100]  = "Roll Angle Angular Velocity"
        BLENinebot.labels[105]  = "Active Data Encoded"
        BLENinebot.labels[115]  = "Tilt Back Speed?"
        BLENinebot.labels[116]  = "Speed Limit"
        
        BLENinebot.labels[176] = "Code Error"
        BLENinebot.labels[177] = "Code Warning"
        BLENinebot.labels[178] = "Flags"             // Lock, Limit Speed, Beep, Activation
        BLENinebot.labels[179] = "Work Mode"
        BLENinebot.labels[180] = "Batt (%)"
        BLENinebot.labels[181] = "Speed"
        BLENinebot.labels[182] = "Average Speed"
        BLENinebot.labels[183] = "Total Distance0"
        BLENinebot.labels[184] = "Total Distance1"
        BLENinebot.labels[185] = "Dist (Km)"
        BLENinebot.labels[186] = "Single Mileage?"
        BLENinebot.labels[187] = "T ºC"
        BLENinebot.labels[188] = "Voltage (V)"
        BLENinebot.labels[189] = "Current (A)"
        BLENinebot.labels[190] = "Pitch(º)"
        BLENinebot.labels[191] = "Max Speed"
        BLENinebot.labels[210] = "Ride Mode"
        BLENinebot.labels[211] = "One Fun Bool"
        
    }
    
    let xmlHeader : String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<gpx xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.cluetrust.com/XML/GPXDATA/1/0 http://www.cluetrust.com/Schemas/gpxdata10.xsd http://www.gorina.es/XML/TRACESDATA/1/0/tracesdata.xsd\" xmlns:gpxdata=\"http://www.cluetrust.com/XML/GPXDATA/1/0\" xmlns:tracesdata=\"http://www.gorina.es/XML/TRACESDATA/1/0\" version=\"1.1\" creator=\"9BMetrics - http://www.gorina.es/9BMetrics\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
    
    let xmlFooter = "</trkseg>\n</trk>\n</gpx>\n"
    
    
    var trackHeader : String {
        return "<trk>\n<name>Ninebot One</name>\n\n<trkseg>\n"
    }
    
    
    func clearAll(){
        
        for i in 0..<256{
            data[i].value = -1
            data[i].timeStamp = Date()
            if data[i].log.count > 0{
                data[i].log.removeAll()
            }
        }
        
        headersOk = false
        firstDate = nil
        distOffset = 0
    }
    func hasData()->Bool{
        
        return data[BLENinebot.kCurrent].log.count > 0
    }
    func checkHeaders() -> Bool{
        
        if headersOk {
            return true
        }
        
        var filled = true
        
        for i in 16..<27 {
            if data[i].value == -1{
                filled = false
            }
        }
        
        if data[BLENinebot.kSpeedLimit].value == -1{
            filled = false
        }
        
        if data[BLENinebot.kAbsoluteSpeedLimit].value == -1{
            filled = false
        }
        
        if data[BLENinebot.kvRideMode].value == -1{
            filled = false
        }
        
        headersOk = filled
        
        return filled
    }
    
    func addValue(_ variable : Int, value : Int){
        
        let t = Date()
        
        self.addValueWithDate(t, variable: variable, value: value)
        
    }
    
    func addValueWithTimeInterval(_ time: TimeInterval, variable : Int, value : Int){
        
        self.addValueWithTimeInterval(time, variable: variable, value: value, forced: false)
    }
    
    func addValueWithTimeInterval(_ time: TimeInterval, variable : Int, value : Int, forced : Bool){
        
        let t = Date(timeIntervalSince1970: time)
        
        self.addValueWithDate(t, variable: variable, value: value, forced: forced)
    }
    
    
    func addValueWithDate(_ dat: Date, variable : Int, value : Int){
        
        self.addValueWithDate(dat, variable : variable, value : value, forced : false)
    }
    
    func addValueWithDate(_ dat: Date, variable : Int, value : Int, forced : Bool){
        
        if variable >= 0 && variable < 256 {
            
            if firstDate == nil {
                firstDate = Date()
            }
            
            if dat.compare(firstDate!) == ComparisonResult.orderedAscending{
                firstDate = dat
            }
            
            var sv = value
            if signed[variable]{
                if value >= 32768 {
                    sv = value - 65536
                }
            }
            
            
            if variable == BLENinebot.kvSingleMileage{
                let delta = sv + self.distOffset - self.data[BLENinebot.kvSingleMileage].value
                
                if delta < 0 {
                    self.distOffset = self.data[BLENinebot.kvSingleMileage].value - sv
                    sv = self.data[BLENinebot.kvSingleMileage].value
                } else {
                    sv = sv + self.distOffset
                }
                
            }
            let v = LogEntry(time:dat, variable: variable, value: sv)
            
            if data[variable].value != sv || data[variable].log.count <= 1 || forced{
                
                data[variable].log.append(v)
                self.postVariableChanged(v)
                
            }else if data[variable].log.count > 2{
                
                let c = data[variable].log.count
                let e = data[variable].log[c-2]
                
                if e.value != sv {   // Append new point
                    data[variable].log.append(v)
                }
                else {  // Update time of new point
                    data[variable].log[c-1] = v
                    
                }
                
            }
            
            // Now update values of variables
            
            data[variable].value = sv
            data[variable].timeStamp = dat
            
            //Now post new entru
            
            
        }
    }
    
    
    // MARK : Converting to and from files
    
    func postVariableChanged(_ entry : LogEntry){
        
        let name = BLENinebot.nameOfVariableChangedNotification(entry.variable)
        
        let userInfo = ["value" : entry.value, "variable" : entry.variable, "time" : entry.time] as [String : Any]
        
        let not = Notification(name: Notification.Name(rawValue: name), object: self, userInfo: userInfo)
        
        NotificationCenter.default.post(not)
        
        
    }
    
    static func nameOfVariableChangedNotification(_ variable : Int) -> String{
        return String(format: "ninebotVariable%dChanged", variable)
    }
    
    func createCSVFileFrom(_ from : TimeInterval, to: TimeInterval) -> URL?{
        // Format first date into a filepath
        
        let ldateFormatter = DateFormatter()
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'Sel_'yyyyMMdd'_'HHmmss'.csv'"
        let newName = ldateFormatter.string(from: Date())
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        var path : String = ""
        
        if let dele = appDelegate {
            let docs = dele.applicationDocumentsDirectory()
            
            if let d = docs {
                path = d.path
            }
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ) + newName
        
        
        let mgr = FileManager.default
        
        mgr.createFile(atPath: tempFile, contents: nil, attributes: nil)
        let file = URL(fileURLWithPath: tempFile)
        
        
        
        do{
            let hdl = try FileHandle(forWritingTo: file)
            // Get time of first item
            
            if firstDate == nil {
                firstDate = Date()
            }
            
            
            let title = String(format: "Time\tCurrent\tVoltage\tPower\tEnergy\tSpeed\tAlt\tDist\tPitch\tRoll\tBatt\tTºC\n")
            hdl.write(title.data(using: String.Encoding.utf8)!)
            
            // Get first ip of current
            
            for i in 0 ..< self.data[BLENinebot.kCurrent].log.count {
                
                let e = self.data[BLENinebot.kCurrent].log[i]
                
                let t = e.time.timeIntervalSince(self.firstDate!)
                
                if from <= t && t <= to {
                    
                    let vCurrent = self.current(i)
                    let vVoltage = self.voltage(time: t)
                    let vPower = self.power(time: t)
                    let vEnergy = self.energy(time :t)
                    let vSpeed = self.speed(time: t)
                    let vAlt = self.altitude(time: t)
                    let vDistance = self.singleMileage(time: t)
                    let vPitch = self.pitch(time: t)
                    let vRoll = self.roll(time: t)
                    let vBattery = self.batteryLevel(time: t)
                    let vTemp = self.temperature(time: t)
                    
                    
                    let s = String(format: "%0.3f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\n", t, vCurrent, vVoltage, vPower, vEnergy, vSpeed, vAlt, vDistance, vPitch, vRoll, vBattery, vTemp)
                    if let vn = s.data(using: String.Encoding.utf8){
                        hdl.write(vn)
                    }
                }
            }
            
            
            hdl.closeFile()
            
            return file
            
        }
        catch{
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"Error when trying to get handle for %@".localized(), file as CVarArg)
            }
            
            AppDelegate.debugLog("Error al obtenir File Handle")
        }
        
        return nil
        
    }
    
    // Modified to reduce size :
    //
    //  1.- First line includes "Version" and FirstDate
    //  2.- Each data sample includes time from firstDate and NOT white filles by left.
    //  3.- Deleted variable number from every line
    //
    
    func createTextFile() -> URL?{
        
        
        if self.data[BLENinebot.kEnergy].log.count == 0{
            self.buildEnergy()
        }
        // Format first date into a filepath
        
        let ldateFormatter = DateFormatter()
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'9B_'yyyyMMdd'_'HHmmss'.txt'"
        let newName = ldateFormatter.string(from: Date())
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        var path : String = ""
        
        if let dele = appDelegate {
            let docs = dele.applicationDocumentsDirectory()
            
            if let d = docs {
                path = d.path
            }
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ) + newName
        
        
        let mgr = FileManager.default
        
        mgr.createFile(atPath: tempFile, contents: nil, attributes: nil)
        let file = URL(fileURLWithPath: tempFile)
        
        
        
        do{
            let hdl = try FileHandle(forWritingTo: file)
            // Get time of first item
            
            if firstDate == nil {
                firstDate = Date()
            }
            
            let version = String(format: "Version\t2\tStart\t%0.3f\n", firstDate!.timeIntervalSince1970)
            hdl.write(version.data(using: String.Encoding.utf8)!)
            
            let title = String(format: "Time\tValor\n")
            hdl.write(title.data(using: String.Encoding.utf8)!)
            
            for v in self.data {
                
                if v.log.count > 0{
                    
                    let varName = String(format: "V\t%d\t%@\n",v.codi, BLENinebot.labels[v.codi])
                    
                    AppDelegate.debugLog("Gravant log per %@", varName)
                    
                    if let vn = varName.data(using: String.Encoding.utf8){
                        hdl.write(vn)
                    }
                    
                    for item in v.log {
                        
                        let t = item.time.timeIntervalSince(self.firstDate!)
                        
                        let s = String(format: "%0.3f\t%d\n", t, item.value)
                        if let vn = s.data(using: String.Encoding.utf8){
                            hdl.write(vn)
                        }
                    }
                }
            }
            
            hdl.closeFile()
            checkImage(file)
            return file
            
        }
        catch{
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"Error when trying to get handle for %@".localized(), file as CVarArg)
            }
            
            AppDelegate.debugLog("Error al obtenir File Handle")
        }
        
        
        return nil
    }
    
    func variableLogtoString(_ v : NinebotVariable) -> String?{
        
        if v.log.count == 0{    // Just nothing to store
            return nil
        }
        
        
        let varName = String(format: "%d,%@\n",v.codi, BLENinebot.labels[v.codi])
        
        let version = String(format: "Version,3,Start,%0.3f,Variable,%@\n", firstDate!.timeIntervalSince1970, varName)
  
        var buff = version
    
        
        AppDelegate.debugLog("Gravant file log per %@", varName)
        
        for item in v.log {
            let t = item.time.timeIntervalSince(self.firstDate!)
            buff += String(format: "%0.3f,%d\n", t, item.value)
        }
       return buff
        
    }
    
    func stringToVariableLog(_ s : String) -> NinebotVariable{
        
        var nv = NinebotVariable()
        
        let lines = s.components(separatedBy: CharacterSet.newlines)
        
        var lineNumber = 0
        var version = 1
        var date0 : Date?
        let variable : Int = -1
        
        for line in lines {
            let fields = line.components(separatedBy: ",")
            
            if lineNumber == 0 {
                
                if fields[0] == "Version"{
                    if let v = Int(fields[1]){
                        
                        if v == 3{
                            version = v
                            
                            // field 3 has first date
                            
                            guard let dt = Double(fields[3].replacingOccurrences(of: " ", with: "")) else {return nv}
                            date0 = Date(timeIntervalSince1970: dt)
                            guard let variable = Int(fields[5].replacingOccurrences(of: " ", with: "")) else {return nv}
                            nv.codi = variable
                            self.firstDate = date0
                            
                        } else {
                            AppDelegate.debugLog("Error amb version %d", v)
                            lineNumber += 1
                            return nv
                        }
                    }
                    
                } else {
                    AppDelegate.debugLog("Incorrect Format")
                    lineNumber += 1
                    return nv
                }
                lineNumber += 1
                continue
            }
            if version == 3 && fields.count == 2 {
                
                guard let dt = Double(fields[0].replacingOccurrences(of: " ", with: "")) else {return nv}
                
                if let d = date0{
                    let t = Date(timeInterval: dt, since: d)
                    let value = Int(fields[1])
                    
                    if  let vl = value {
                        
                        let le = LogEntry(time: t, variable: variable, value: vl)
                        nv.log.append(le)
                        nv.timeStamp = t
                        nv.value = vl
                        
                     }
                }
            }
            
            lineNumber += 1
            
        }
        return nv
    }
    
    
    func createPackage(_ name : String) -> URL?{
        
        guard let docDir = (UIApplication.shared.delegate as! AppDelegate).applicationDocumentsDirectory() else {return nil}
        
        let pkgURL = docDir.appendingPathComponent(name).appendingPathExtension("9bm")

        // Try to use file wrappers (ufff)
        
        let contents = FileWrapper(directoryWithFileWrappers: [:])
        for v in self.data {
            if v.log.count > 0{
                
                let vn = v.codi
                let fileName = String(format: "%03d.csv", vn)
                
                if let s = variableLogtoString(v){
                    if let dat = s.data(using: String.Encoding.utf8){
                        let fWrapper = FileWrapper(regularFileWithContents: dat)
                        fWrapper.preferredFilename = fileName
                        contents.addFileWrapper(fWrapper)
                    }
                }
            }
        }
        do{
            try contents.write(to: pkgURL, options: .withNameUpdating, originalContentsURL: pkgURL)
        }catch let err as NSError{
            
            
            AppDelegate.debugLog("Error al gravar arxius %@", err.description)
            return nil
        }
        
        return pkgURL
    }
    
    func loadVariableFromPackage(_ packageName : String, variableName: String) -> NinebotVariable?{
        guard let docDir = (UIApplication.shared.delegate as! AppDelegate).applicationDocumentsDirectory() else {return nil}
        
        let pkgURL = docDir.appendingPathComponent(packageName).appendingPathExtension("9bm")
        
        let fileURL = pkgURL.appendingPathComponent(variableName)
        
        do {
             let str = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
            return stringToVariableLog(str)
            
        }catch{
            
        }
        return nil
    }
    
    func loadPackage(_ url : URL) {
        
    
        
        do{
            let pack = try FileWrapper(url: url, options: [])
        
            if pack.isDirectory{
                
                for (name, fw) in pack.fileWrappers!{
                    if fw.isRegularFile && name == "summary.csv"{
                        
                                // Load summary
                        
                    } else if fw.isRegularFile && name == "map.gpx"{
                        
                        
                        
                    }else if fw.isRegularFile {
                        
                        if let str = String(data: fw.regularFileContents!, encoding: String.Encoding.utf8){
                            let nv = stringToVariableLog(str)
                            data[nv.codi] = nv
                         }
                    }
                }
            }
        }catch{
            
        }
    }
    
    func createZipFile(_ name : String) -> URL?{
        
        let tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory(),isDirectory: true)
        let fmgr = FileManager()
        let pkgUrl = tmpDirURL.appendingPathComponent(name)
        
        var files : [URL] = [URL]()
        
        if firstDate == nil {
            firstDate = Date()
        }
        
        do{
            if fmgr.fileExists(atPath: pkgUrl.path) {
                try fmgr.removeItem(at: pkgUrl)
            }
            try fmgr.createDirectory(at: pkgUrl, withIntermediateDirectories: false, attributes: nil)
            
            // Add file with gpx extension
            
            for v in self.data {
                if v.log.count > 0{
                    
                    let vn = v.codi
                    let fileName = String(format: "%03d", vn)
                    let fileUrl = pkgUrl.appendingPathComponent(fileName).appendingPathExtension("csv")
                    let path = fileUrl.path
                        
                        fmgr.createFile(atPath: path, contents: nil, attributes: nil)
                        let hdl = try FileHandle(forWritingTo: fileUrl)
                        
                        
                        let varName = String(format: "%d,%@\n",v.codi, BLENinebot.labels[v.codi])
                        
                        let version = String(format: "Version,3,Start,%0.3f,Variable,%@\n", firstDate!.timeIntervalSince1970, varName)
                        
                        hdl.write(version.data(using: String.Encoding.utf8)!)
                        
                        
                        AppDelegate.debugLog("Gravant file log per %@", varName)
                        
                        for item in v.log {
                            
                            let t = item.time.timeIntervalSince(self.firstDate!)
                            
                            let s = String(format: "%0.3f,%d\n", t, item.value)
                            if let vn = s.data(using: String.Encoding.utf8){
                                hdl.write(vn)
                            }
                        }
                        
                        hdl.closeFile()
                        
                        files.append(fileUrl)
                    
                    
                    
                }
            }
            
            // Create a gpx file  in the same directory
            
            if self.hasGPSData(){
                let gpxURL = pkgUrl.appendingPathComponent(name).appendingPathExtension("gpx")
                
                if self.createGPXFile(gpxURL)
                {
                    files.append(gpxURL)
                }
            }
            let zipURL = pkgUrl.appendingPathExtension("zip")
            
            do {
                
                
                
                try Zip.zipFiles(files, zipFilePath: zipURL, password: nil, progress: { (progress) -> () in
                    AppDelegate.debugLog("Zip %f", progress)
                })
                
                // OK finished so remove directory
                
                try fmgr.removeItem(at: pkgUrl)
            }catch{
                if let dele = UIApplication.shared.delegate as? AppDelegate{
                    dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),
                                                 format:"Error when trying to create zip file %@".localized(), zipURL as CVarArg)
                }
                AppDelegate.debugLog("Error al crear zip file")
            }
            
            return zipURL
            
        }catch {
            
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"Error when processing files".localized())
            }
            
            AppDelegate.debugLog("Error al crear zip file")
            
            return nil
        }
        
    }
    
    
    
    internal func createGPXFile(_ url : URL) -> (Bool)
    {
        //let cord : NSFileCoordinator = NSFileCoordinator(filePresenter: self.doc)
        //var error : NSError?
        
        //        cord.coordinateWritingItemAtURL(url,
        //           options: NSFileCoordinatorWritingOptions.ForReplacing,
        //          error: &error)
        //          { ( newURL :NSURL!) -> Void in
        
        // Check if it exits
        
        let mgr =  FileManager()
        
        
        
        let exists = mgr.fileExists(atPath: url.path)
        
        if !exists{
            mgr.createFile(atPath: url.path, contents: "Hello".data(using: String.Encoding.utf8), attributes:nil)
        }
        
        
        
        if let hdl = FileHandle(forWritingAtPath: url.path){
            hdl.truncateFile(atOffset: 0)
            hdl.write(self.xmlHeader.data(using: String.Encoding.utf8)!)
            
            
            hdl.write(self.trackHeader.data(using: String.Encoding.utf8)!)
            
            let n = min(data[BLENinebot.kLatitude].log.count, data[BLENinebot.kLongitude].log.count)
            for i in 0..<n {
                
                let time = data[BLENinebot.kLatitude].log[i].time
                let lat = Double(data[BLENinebot.kLatitude].log[i].value) / 100000.0
                let lon = Double(data[BLENinebot.kLongitude].log[i].value) / 100000.0
                
                var ele : Double = 0.0
                if data[BLENinebot.kAltitudeGPS].log.count > i {
                    ele = Double(data[BLENinebot.kAltitudeGPS].log[i].value)
                }// Altitude in m
                
                var speed = 0.0
                
                if data[BLENinebot.kSpeedGPS].log.count > i {
                    speed = Double(data[BLENinebot.kSpeedGPS].log[i].value) / 1000.0    // Speed in m/s
                    
                }// Altitude in m
                
                let timestr =  self.otherFormatter.string(from: time)
                
                
                
                let timeString : String = timestr.replacingOccurrences(of: " ",  with: "").replacingOccurrences(of: "\n",with: "").replacingOccurrences(of: "\r",with: "")
                
                
                let s = String(format:"<trkpt lat=\"%7.5f\" lon=\"%7.5f\">\n<ele>%3.0f</ele>\n<speed>%0.2f</speed>\n<time>\(timeString)</time>\n</trkpt>\n", lat, lon, ele, speed)
                
                hdl.write(s.data(using: String.Encoding.utf8)!)
                
            }
            
            hdl.write(self.xmlFooter.data(using: String.Encoding.utf8)!)
            hdl.closeFile()
            return true
        }
        else
        {
            return false
            //error = err
        }
        
        //   } Fora manager
        
    }
    
    func locationArray() -> [CLLocationCoordinate2D] {
        
        var locs = [CLLocationCoordinate2D]()
        
        if !self.hasGPSData(){      // Nothing to return :(
            return locs
        }
        
        // Loop over 3 and 4
        
        let latArray = self.data[BLENinebot.kLatitude].log
        let lonArray = self.data[BLENinebot.kLongitude].log
        
        let n = min(latArray.count, lonArray.count)
        
        for i in 0..<n{
            let lcd = CLLocationCoordinate2DMake(Double(latArray[i].value)/100000.0, Double(lonArray[i].value)/100000.0)
            locs.append(lcd)
        }
        
        return locs
    }
    
    
    
    func loadTextFile(_ url:URL){
        
        self.clearAll()
        
        do{
            
            let data = try String(contentsOf: url, encoding: String.Encoding.utf8)
            let lines = data.components(separatedBy: CharacterSet.newlines)
            
            var lineNumber = 0
            var version = 1
            var date0 : Date?
            var variable : Int = -1
            
            for line in lines {
                let fields = line.components(separatedBy: "\t")
                
                if lineNumber == 0 {
                    
                    if fields[0] == "Version"{
                        if let v = Int(fields[1]){
                            
                            if v >= 1 && v <= 2{
                                version = v
                                
                                // field 3 has first date
                                
                                guard let dt = Double(fields[3].replacingOccurrences(of: " ", with: "")) else {return}
                                date0 = Date(timeIntervalSince1970: dt)
                                self.firstDate = date0
                                
                            } else {
                                AppDelegate.debugLog("Error amb version %d", v)
                                lineNumber += 1
                                return
                            }
                        }
                        
                    } else if fields[0] == "Time"{
                        version = 1
                    } else {
                        AppDelegate.debugLog("Incorrect Format")
                        lineNumber += 1
                        return
                    }
                    lineNumber += 1
                    continue
                } else if lineNumber == 1 && version == 2{
                    lineNumber += 1
                    continue    // Just jump line with titles
                }
                
                if version == 1 && fields.count == 3{   // Old filea
                    
                    let time = Double(fields[0].replacingOccurrences(of: " ", with: ""))
                    let variable = Int(fields[1])
                    let value = Int(fields[2])
                    
                    if let t = time, let i = variable, let v = value {
                        self.addValueWithTimeInterval(t, variable: i, value: v, forced: true)
                    }
                }else  if version == 2 && fields.count == 3 && fields[0] == "V"{
                    
                    let sv = fields[1]
                    let iv = Int(sv)
                    
                    if let ix = iv {
                        variable = ix  // Set variable
                    }else{
                        return  // Error en format
                    }
                    
                }else if version == 2 && fields.count == 2 {
                    
                    guard let dt = Double(fields[0].replacingOccurrences(of: " ", with: "")) else {return}
                    
                    if let d = date0{
                        let t = Date(timeInterval: dt, since: d)
                        let value = Int(fields[1])
                        
                        if  let v = value {
                            self.addValueWithDate(t, variable: variable, value: v, forced: true)
                        }
                    }
                }
                
                lineNumber += 1
                
            }
            
            self.buildEnergy()
            
            // Hack to calculate current if we have energy and Current was not written
            // due to a bug.
            
//            if self.data[BLENinebot.kCurrent].log.count == 0 &&
//                self.data[BLENinebot.kEnergy].log.count > 0 {
//                
//                var oldEntry : LogEntry?
//                
//                for e in self.data[BLENinebot.kEnergy].log {
//                    
//                    if let oe = oldEntry  {
//                        
//                        let dt = e.time.timeIntervalSinceDate(oe.time)
//                        let de = e.value - oe.value
//                        
//                        var pw = 0.0
//                        
//                        if dt != 0 {
//                            pw = Double(de) * 36.0 / dt
//                        }
//                        
//                        let t = (e.time.timeIntervalSinceDate(self.firstDate!) + oe.time.timeIntervalSinceDate(self.firstDate!))/2.0
//                        let current = pw / self.voltage(time:t)
//                        self.data[BLENinebot.kCurrent].log.append(LogEntry(time: NSDate.init(timeInterval: dt/2.0, sinceDate: oe.time), variable: BLENinebot.kCurrent, value: Int(round(current * 100.0))))
//                    }
//                    
//                    oldEntry = e
//                }
//            }
            
            checkImage(url)
            
        }catch {
            
        }
        
        // OK now build package.
        
        let name = url.deletingPathExtension().lastPathComponent 
            let newName = name.replacingOccurrences(of: "9B_", with: "")
            if let url = createPackage(newName){
                AppDelegate.debugLog("Package %@ created", url as CVarArg)
            }else{
                AppDelegate.debugLog("Error al crear Package")
            }
        
        
    }
    func computeTrackSize() -> (l0 : CLLocation?, l1 : CLLocation? ){
        
        if self.data[BLENinebot.kLatitude].log.count <= 0{
            return (nil, nil)
        }
        
        var latmin = self.data[BLENinebot.kLatitude].log[0].value
        var latmax = self.data[BLENinebot.kLatitude].log[0].value
        var lonmin = self.data[BLENinebot.kLongitude].log[0].value
        var lonmax = self.data[BLENinebot.kLongitude].log[0].value
        
        for i in 1..<self.data[BLENinebot.kLatitude].log.count{
            
            let lat = self.data[BLENinebot.kLatitude].log[i].value
            let lon = self.data[BLENinebot.kLongitude].log[i].value
            
            if lat < latmin {
                latmin = lat
            }
            if lat > latmax {
                latmax = lat
            }
            if lon < lonmin {
                lonmin = lon
            }
            if lon > lonmax {
                lonmax = lon
            }
        }
        
        return (CLLocation(latitude: Double(latmin)/100000.0, longitude: Double(lonmin)/100000.0), CLLocation(latitude: Double(latmax)/100000.0, longitude: Double(lonmax)/100000.0))
        
    }
    
    func checkImage(_ url : URL){
        
        
        var thumb : UIImage?
        
        if self.hasGPSData(){
            thumb = self.imageWithWidth(256, height: 256)
        } else {
            thumb = UIImage(named: "9b")
        }
        
        
        let dict = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey: thumb!] as NSDictionary
        
        do {
            try (url as NSURL).setResourceValue( dict,
                                      forKey:URLResourceKey.thumbnailDictionaryKey)
        }
        catch _{
            AppDelegate.debugLog("No puc gravar la imatge :)")
        }
        
        
        
    }
    

    internal func imageWithWidth(_ wid:Double,  height:Double) -> UIImage? {
        return imageWithWidth(wid,  height:height, color:UIColor.red, backColor:UIColor.white, lineWidth: 5.0)
    }
    
    internal func imageWithWidth(_ wid:Double,  height:Double, color:UIColor, backColor:UIColor, lineWidth: Double) -> UIImage? {
        
        TMKImage.beginImageContextWithSize(CGSize(width: CGFloat(wid) , height: CGFloat(height)))
        
        var rect = CGRect(x: 0, y: 0, width: CGFloat(wid), height: CGFloat(height))   // Total rectangle
        
        var bz = UIBezierPath(rect: rect)
        
        backColor.set()
        bz.fill()
        bz.stroke()
        
        rect = rect.insetBy(dx: 3.0, dy: 3.0);
        
        bz = UIBezierPath(rect:rect)
        bz.lineWidth = 2.0
        bz.stroke()
        
        let (loc0, loc1) = self.computeTrackSize()
        
        if let locmin = loc0, let locmax = loc1 {
            
            let p0 = MKMapPointForCoordinate(locmin.coordinate)
            
            let p1 = MKMapPointForCoordinate(locmax.coordinate)
            
            // Get Midpoint
            
            
            let scalex : Double = fabs(wid * 0.9 / (p1.x - p0.x))  // 90 % de l'area
            let scaley : Double = fabs(height * 0.9 / (p1.y - p0.y))  // 90 % de l'area
            
            let scale : Double = scalex < scaley ? scalex : scaley
            
            let minx = p0.x < p1.x ? p0.x : p1.x
            let miny = p0.y < p1.y ? p0.y : p1.y
            
            // Compute midpoint
            
            let pm = MKMapPointMake((p0.x+p1.x)/2.0, (p0.y+p1.y)/2.0)
            let pmc = MKMapPointMake((pm.x-minx)*scale, (pm.y-miny)*scale)
            let offset = MKMapPointMake((wid/2.0)-pmc.x, (height/2.0)-pmc.y)
            
            bz  = UIBezierPath()
            
            var primer = true
            
            let n = self.data[BLENinebot.kLatitude].log.count
            
            
            for i in 0..<n {
                
                
                
                let lat = Double(self.data[BLENinebot.kLatitude].log[i].value) / 100000.0
                let lon = Double(self.data[BLENinebot.kLongitude].log[i].value) / 100000.0
                
                let p = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude:lat, longitude: lon ))
                
                let x : CGFloat = CGFloat((p.x-minx) * scale + offset.x)
                let y : CGFloat = CGFloat((p.y-miny) * scale + offset.y)
                if primer
                {
                    bz.move(to: CGPoint(x: x,y: y))
                    primer = false
                }
                else{
                    bz.addLine(to: CGPoint(x: x,y: y))
                }
                
            }
            
            bz.lineWidth = CGFloat(lineWidth)
            bz.lineJoinStyle = CGLineJoin.round
            color.setStroke()
            bz.stroke()
            let img = UIGraphicsGetImageFromCurrentImageContext()
            TMKImage.endImageContext()
            
            
            return img
        }
        else{
            return nil
        }
        
    }
    
    //MARK: Analysis
    
    // Computes summary. It is saved in the summary.cvs file in the package
    
    func computeSummary(){
        
    }
    
    
    func computeAscentDescent() -> (ascent : Double, descent : Double){
        
        let datos = self.data[BLENinebot.kAltitude];
        
        if datos.log.count <= 1{
            return (0.0, 0.0)
        }
        
        var ascent = 0.0
        var descent = 0.0
        
        var oldEntry = datos.log[0]
        
        for i in 1..<datos.log.count {
            
            let e = datos.log[i]
            
            if e.value > oldEntry.value {
                ascent = ascent + Double(e.value - oldEntry.value) / 100.0
            }
            else{
                descent = descent - Double(e.value - oldEntry.value) / 100.0
            }
            
            oldEntry = e
            
        }
        
        return (ascent, descent)
    }
    
    func analCinematics() -> (Double, Double, Double, Double, Double, Double){
        
        if self.data[BLENinebot.kvSingleMileage].log.count <= 1{
            return (0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        }
        
        // Distancia
        
        let dist = self.singleMileage();    // Distància en Km
        let (ascent, descent) = computeAscentDescent()      // Ascent, Descent
        let distance = self.data[BLENinebot.kvSingleMileage]
        let time = distance.log.last!.time.timeIntervalSince(distance.log.first!.time)
        let (_, maxSpeed, avgSpeed, _) = speed(from: 0.0, to: time)
        
        return (dist, ascent, descent, time, avgSpeed, maxSpeed)
     }
    
    func analEnergy() -> (Double, Double, Double, Double, Double, Double, Double, Double, Double, Double){
        
        if self.data[BLENinebot.kBattery].log.count == 0{
            return (0.0, 0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0, 0.0)
        }
        // Battery : First - Last - Min
        
        let bat0 = Double(self.data[BLENinebot.kBattery].log[0].value)
        let bat1 = Double(self.data[BLENinebot.kBattery].log.last!.value)
        let batt = self.data[BLENinebot.kBattery]
        let time = batt.log.last!.time.timeIntervalSince(batt.log.first!.time)
        let (batMin, batMax, _, _) = self.batteryLevel(from: 0.0, to: time)
        
        // Energy  : Total
        
        let energy = self.energy()
        let batEnergy = (bat1 - bat0) * 340.0  / 100.0 // Calculo
        
        // Current : Avg, max
        
        let (_, currMax, currAvg, _) = self.current(from: 0.0, to: time)
        // Power   : Avg, max
        
        let (_, pwMax, pwAvg, _) = self.powerStats(from: 0.0, to: time)
        
        
        return (bat0, bat1, batMin, batMax, energy, batEnergy, currMax, currAvg, pwMax, pwAvg)
        
    }
    
    
    // MARK: Query Functions
    
    func countLogForVariable(_ v : Int) -> Int{
        
        if v < 0 || v >= 256{
            return -1
        }
        
        return data[v].log.count

    }
    
    func currentValueForVariable(_ v : Int) -> Int{
        
        if v < 0 || v >= 256{
            return -1
        }
        
        return data[v].value
    }
    
    func valueForVariable(_ v : Int, atPoint point : Int) -> Int{
        
        if v < 0 || v >= 256{
            return -1
        }
        
        if point >= data[v].log.count{
            return -1
        }
       
        return data[v].log[point].value
    }

    func timeForVariable(_ v : Int, atPoint point : Int) -> Date?{
        
        if v < 0 || v >= 256{
            return nil
        }
        
        if point >= data[v].log.count{
            return nil
        }
        
        let t = data[v].log[point].time
       
        return t
    }

    
    func hasGPSData() -> Bool{
        return data[BLENinebot.kLatitude].log.count > 0
    }
    
    func altitudeGPS(_ time: TimeInterval) -> Double{
        
        if let v = value(BLENinebot.kAltitudeGPS , forTime: time){
            return v.value
        }
        else{
            return 0.0
        }
    }
    
    func serialNo() -> String{
        
        if !self.checkHeaders(){
            return "Waiting"
        }
        
        var no = ""
        
        for i in 16 ..< 23{
            let v = self.data[i].value
            
            
            let v1 = v % 256
            let v2 = v / 256
            
            let ch1 = Character(UnicodeScalar(v1)!)
            let ch2 = Character(UnicodeScalar( v2)!)
            
            no.append(ch1)
            no.append(ch2)
        }
        
        return no
    }
    
    func version() -> (Int, Int, Int){
        
        let clean = self.data[BLENinebot.kVersion].value & 4095
        
        let v0 = clean / 256
        let v1 = (clean - (v0 * 256) ) / 16
        let v2 = clean % 16
        
        return (v0, v1, v2)
        
    }
    
    // Return total mileage in Km
    
    func totalMileage() -> Double {
        
        let d : Double = Double (data[BLENinebot.kTotalMileage1].value * 65536 + data[BLENinebot.kTotalMileage0].value) / 1000.0
        
        return d
        
    }
    
    // Total runtime in seconds
    
    func totalRuntime() -> TimeInterval {
        
        let t : TimeInterval = TimeInterval(data[BLENinebot.kTotalRuntime1].value * 65536 + data[BLENinebot.kTotalRuntime0].value)
        
        return t
    }
    
    func singleRuntime() -> TimeInterval {
        
        let t : TimeInterval = TimeInterval(data[BLENinebot.kSingleRuntime].value)
        
        return t
    }
    
    static func HMSfromSeconds(_ secs : TimeInterval) -> (Int, Int, Int) {
        
        let hours =  floor(secs / 3600.0)
        let minutes = floor((secs - (hours * 3600.0)) / 60.0)
        let seconds = round(secs - (hours * 3600.0) - (minutes * 60.0))
        
        return (Int(hours), Int(minutes), Int(seconds))
        
    }
    
    func singleRuntimeHMS() -> (Int, Int, Int) {
        
        let total  = Double(data[BLENinebot.kSingleRuntime].value)
        
        return BLENinebot.HMSfromSeconds(total)
        
    }
    
    
    func totalRuntimeHMS() -> (Int, Int, Int) {
        
        let total = Double(data[BLENinebot.kTotalRuntime1].value * 65536 + data[BLENinebot.kTotalRuntime0].value)
        
        return BLENinebot.HMSfromSeconds(total)
        
    }
    
    // Body Temperature in ºC
    
    func temperature() -> Double {
        let t : Double = Double(data[BLENinebot.kTemperature].value) / 10.0
        
        return t
    }
    
    func temperature(_ i : Int) -> Double {
        let t : Double = Double(data[BLENinebot.kTemperature].log[i].value) / 10.0
        
        return t
    }
    
    func temperature(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kTemperature, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 10.0
        }
        else{
            return 0.0
        }
    }
    
    func temperature(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kTemperature, from: t0, to: t1)
        
        return (min/10.0, max/10.0, avg/10.0, acum/10.0)
    }
    
    
    
    // Voltage
    
    func voltage() -> Double {
        let t : Double = Double(data[BLENinebot.kVoltage].value) / 100.0
        return t
    }
    func voltage(_ i : Int) -> Double {
        
        let t : Double = Double(data[BLENinebot.kVoltage].log[i].value) / 100.0
        return t
    }
    
    func voltage(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kVoltage, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    func voltage(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kVoltage, from: t0, to: t1)
        
        return (min/100.0, max/100.0, avg/100.0, acum/100.0)
    }
    
    // Current
    func current() -> Double {
        let v = data[BLENinebot.kCurrent].value
        let t = Double(v) / 100.0
        return t
    }
    
    func current(_ i : Int) -> Double {
        let v = data[BLENinebot.kCurrent].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    
    func current(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kCurrent, forTime: t)
        
        if let e = entry{
            let v = e.value
            
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    func current(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kCurrent, from: t0, to: t1)
        
        return (min/100.0, max/100.0, avg/100.0, acum/100.0)
    }
    
    func buildEnergy(){
        
        if self.data[BLENinebot.kCurrent].log.isEmpty{
            return
        }
        
        
        var acum = 0.0
        var t0 = self.data[BLENinebot.kCurrent].log[0].time
        var v0 = self.power(0)
        
        self.data[BLENinebot.kEnergy].log.removeAll()
        self.data[BLENinebot.kEnergy].log.append(LogEntry(time: t0, variable: BLENinebot.kEnergy, value: 0))
        
        
        for i in 1..<self.data[BLENinebot.kCurrent].log.count{
            
            let t1 = self.data[BLENinebot.kCurrent].log[i].time
            let v1 = self.power(i)
            
            
            acum = acum + (v1 + v0) / 2.0 * t1.timeIntervalSince(t0)
            t0 = t1
            v0 = v1
            self.data[BLENinebot.kEnergy].log.append(LogEntry(time: t0, variable: BLENinebot.kEnergy, value: Int(round(acum / 36.0))))
        }
        
        self.data[BLENinebot.kEnergy].timeStamp = t0
        self.data[BLENinebot.kEnergy].value = Int(round(acum / 36.0))
    }
    
    func power() -> Double{ // Units are Watts
        return voltage() * current()
    }
    
    func power(_ i : Int) -> Double {
        
        let c =  data[BLENinebot.kCurrent].log[i]
        
        // Ok now we need the value
        
        let voltage = self.value(BLENinebot.kVoltage, forTime: c.time.timeIntervalSince(self.firstDate!))
        
        if let v = voltage {
            
            return Double(v.value) * Double(c.value) / 10000.0
        }else {
            return 0.0
        }
        
    }
    
    func power(time  t : TimeInterval) -> Double{
        
        return self.current(time: t) * self.voltage(time: t)
        
    }
    
    // pitch Angle
    
    func pitch() -> Double {
        let v = data[BLENinebot.kPitchAngle].value
        let t = Double(v) / 100.0
        return t
    }
    
    func pitch(_ i : Int) -> Double {
        let v = data[BLENinebot.kPitchAngle].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    func pitch(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kPitchAngle, forTime: t)
        
        if let e = entry{
            let v = e.value
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    func pitch(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        let (min, max, avg, acum) = self.stats(BLENinebot.kPitchAngle, from: t0, to: t1)
        
        return (min/100.0, max/100.0, avg/100.0, acum/100.0)
    }
    

    
    // roll Angle
    
    func roll() -> Double {
        let v = data[BLENinebot.kRollAngle].value
        let t = Double(v) / 100.0
        return t
    }
    
    func roll(_ i : Int) -> Double {
        let v = data[BLENinebot.kRollAngle].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    func roll(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kRollAngle, forTime: t)
        
        if let e = entry{
            let v = e.value
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    func roll(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kRollAngle, from: t0, to: t1)
        
        return (min/100.0, max/100.0, avg/100.0, acum/100.0)
    }
    
    func energy() -> Double {
        
        let e = data[BLENinebot.kEnergy]
        if e.log.count > 0{
            let t = Double(e.log.last!.value) / 100.0
            return t
        }else {
            return 0.0
        }
    }
    
    func energy(_ i : Int) -> Double {
        let v = data[BLENinebot.kEnergy].log[i].value
        let t = Double(v) / 100.0
        return t
    }
    
    func energy(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kEnergy, forTime: t)
        
        if let e = entry{
            let v = e.value
            return Double(v) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    func energy(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kEnergy, from: t0, to: t1)
        
        return (min/100.0, max/100.0, avg/100.0, acum/100.0)
    }
    
    func energyDetails(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double){
        
        if self.data[BLENinebot.kEnergy].log.count < 2{
            return ( 0.0, 0.0)
        }
        
        var positive = 0.0
        var negative = 0.0
        
        var first = true
        
        var oldEntry = self.data[BLENinebot.kEnergy].log[0]
        for lv in self.data[BLENinebot.kEnergy].log{
            if !first {
                if oldEntry.value < lv.value{
                    positive += Double(lv.value - oldEntry.value) / 100.0
                } else {
                    negative += Double(oldEntry.value - lv.value) / 100.0
                }
            }
            oldEntry = lv
            first = false

        }
        
        return (positive, negative)
    }
    
    // pitch angle speed
    
    
    
    // roll angle speed
    
    
    
    // Remaining km
    
    func remainingMileage() -> Double{
        
        let v = data[BLENinebot.kRemainingDistance].value
        
        let t = Double(v) / 100.0
        
        return t
        
        
    }
    
    
    // Battery Level
    
    func batteryLevel() -> Double{
        
        let v = data[BLENinebot.kBattery].value
        return Double(v)
        
    }
    
    func batteryLevel(_ i : Int) -> Double {
        let s : Double = Double(data[BLENinebot.kBattery].log[i].value)
        
        return s
    }
    
    func batteryLevel(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kBattery, forTime: t)
        
        if let e = entry{
            return Double(e.value)
        }
        else{
            return 0.0
        }
    }
    

    
    func batteryLevel(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double){
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kBattery, from: t0, to: t1)
        
        return (min, max, avg, acum)
    }
    
    
    // Limit Speeed
    
    func limitSpeed() -> Double {
        let s : Double = Double(data[BLENinebot.kSpeedLimit].value) / 1000.0
        
        return s
    }
    
    // Max Speed
    
    func maxSpeed() -> Double {
        let s : Double = Double(data[BLENinebot.kAbsoluteSpeedLimit].value) / 1000.0
        
        return s
    }
    
    // Riding Level
    
    func ridingLevel() -> Int {
        let s = data[BLENinebot.kvRideMode].value
        
        return s
    }
    
    
    // Speed
    
    func speed() -> Double {
        let s : Double = Double(data[BLENinebot.kCurrentSpeed].value) / 1000.0
        
        return s
    }
    
    func speed(_ i : Int) -> Double {
        
        if i < 2  {
            return Double(data[BLENinebot.kCurrentSpeed].log[i].value) / 1000.0
        }else{
            let v0 = Double(data[BLENinebot.kCurrentSpeed].log[i - 2].value) / 1000.0
            let v1 = Double(data[BLENinebot.kCurrentSpeed].log[i - 1].value) / 1000.0
            let v2 = Double(data[BLENinebot.kCurrentSpeed].log[i].value) / 1000.0
            
            return (v0 + 2 * v1 + v2 )/4.0
        }
        
    }
    
    
    func speed(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kCurrentSpeed, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 1000.0
        }
        else{
            return 0.0
        }
    }
    
    // This functions returns min/avg/max values of speed between the interval
    
    func speed(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double){
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kCurrentSpeed, from: t0, to: t1)
        
        return (min/1000.0, max/1000.0, avg/1000.0, acum/1000.0)
    }
    
    
    // Speed limit
    
    
    // Single runtime
    
    
    // Single distance. Sembla pitjor que la total. En fi
    
    func singleMileage() -> Double{
        
        let s : Double = Double(data[BLENinebot.kvSingleMileage].value) / 100.0
        
        return s
    }
    
    func singleMileage(_ i : Int) -> Double{
        
        let s : Double = Double(data[BLENinebot.kvSingleMileage].log[i].value) / 100.0
        
        return s
    }
    
    func singleMileage(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kvSingleMileage, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    
    func altitude() -> Double{
        
        let s : Double = Double(data[BLENinebot.kAltitude].value) / 100.0
        
        return s
    }
    
    func altitude(_ i : Int) -> Double{
        
        if i < data[BLENinebot.kAltitude].log.count{
            
            return Double(data[BLENinebot.kAltitude].log[i].value) / 100.0
        }
        else{
            return 0.0
        }
        
    }
    
    func altitude(time t: TimeInterval) -> Double{
        
        let entry = self.value(BLENinebot.kAltitude, forTime: t)
        
        if let e = entry{
            return Double(e.value) / 100.0
        }
        else{
            return 0.0
        }
    }
    
    
    func altitude(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double)
    {
        
        let (min, max, avg, acum) = self.stats(BLENinebot.kAltitude, from: t0, to: t1)
        
        return (min/100.0, max/100.0, avg/100.0, acum/100.0)
    }
    // t is time from firstDate
    
    func value(_ variable : Int,  forTime t:TimeInterval) -> DoubleLogEntry?{
        
        let v = variable
        let x = t
        
        
        if self.data[v].log.count <= 0{       // No Data
            return nil
        }
        
        var p0 = 0
        var p1 = self.data[v].log.count - 1
        let xd = Double(x)
        
        while p1 - p0 > 1{
            
            let p = (p1 + p0 ) / 2
            
            let xValue = self.data[v].log[p].time.timeIntervalSince(self.firstDate!)
            
            if xd < xValue {
                p1 = p
            }
            else if xd > xValue {
                p0 = p
            }
            else{
                p0 = p
                p1 = p
            }
        }
        
        // If p0 == p1 just return value
        
        if p0 == p1 {
            let e = self.data[v].log[p0]
            return DoubleLogEntry(time: Date(timeInterval: x, since: self.firstDate!), variable: e.variable, value: Double(e.value))
            
        }
        else {      // Intentem interpolar
            
            let v0 = self.data[v].log[p0]
            let v1 = self.data[v].log[p1]
            
            if v0.time.compare( v1.time) == ComparisonResult.orderedSame{   // One more check not to have div/0
                return DoubleLogEntry(time: Date(timeInterval: x, since: self.firstDate!), variable: v0.variable, value: Double(v0.value))
            }
            
            let deltax = v1.time.timeIntervalSince(v0.time)
            
            let deltay = Double(v1.value) - Double(v0.value)
            
            let v = (x - v0.time.timeIntervalSince(self.firstDate!)) / deltax * deltay + Double(v0.value)
            
            return DoubleLogEntry(time: Date(timeInterval: x, since: self.firstDate!), variable: variable, value: v)
        }
    }
    
    
    // Returns min, max, avg and acum (integral trapezoidal)
    
    func stats(_ variable : Int,  from t:TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double){
        
        
        let v = variable
        let x = t
        
        
        if self.data[v].log.count <= 0{       // No Data
            return (0.0, 0.0, 0.0, 0.0)
        }
        
        var p0 = 0
        var p1 = self.data[v].log.count - 1
        let xd = Double(x)
        
        var minv = 0.0
        var maxv = 0.0
        var integralv = 0.0
        var tempsv = 0.0
        
        var oldx = 0.0
        var oldy = 0.0
        var x1 = 0.0
        var y1 = 0.0
        
        var i = 0
        
        while p1 - p0 > 1{
            
            let p = (p1 + p0 ) / 2
            
            let xValue = self.data[v].log[p].time.timeIntervalSince(self.firstDate!)
            
            if xd < xValue {
                p1 = p
            }
            else if xd > xValue {
                p0 = p
            }
            else{
                p0 = p
                p1 = p
            }
        }
        
        if self.data[v].log[p0].time.timeIntervalSince(self.firstDate!) > x{
            p1 = p0
        }
        
        
        
        
        // If p0 == p1 easy
        
        if p0 == p1 {
            
            let e = self.data[v].log[p0]
            oldx = x
            oldy = Double(e.value)
            i = p1
        }
        else {      // Intentem interpolar
            
            let v0 = self.data[v].log[p0]
            let v1 = self.data[v].log[p1]
            
            if v0.time.compare( v1.time) == ComparisonResult.orderedSame{   // One more check not to have div/0
                oldx = x
                oldy = Double(v0.value)
                i = p1
            }
            else{
                
                let deltax = v1.time.timeIntervalSince(v0.time)
                let deltay = Double(v1.value) - Double(v0.value)
                let v = (x - v0.time.timeIntervalSince(self.firstDate!)) / deltax * deltay + Double(v0.value)
                
                oldx = x
                oldy = v
                i = p1
            }
            
        }
        
        minv = oldy
        maxv = oldy
        
        // i sempre apunta al proper punt. Aleshores fem
        
        x1 = self.data[v].log[i].time.timeIntervalSince(self.firstDate!)
        y1 = Double(self.data[v].log[i].value)
        
        
        
        while x1 < t1{
            
            if y1 < minv {
                minv = y1
            }
            
            if y1 > maxv {
                maxv = y1
            }
            
            integralv += (y1 + oldy) / 2.0 * (x1 - oldx)
            tempsv += x1 - oldx
            
            oldx = x1
            oldy = y1
            
            i += 1
            
            if i >= self.data[v].log.count{
                break
            }
            
            x1 = self.data[v].log[i].time.timeIntervalSince(self.firstDate!)
            y1 = Double(self.data[v].log[i].value)
            
        }
        
        // OK ens queda un trocet des de oldx a x. A fer mes endavant
        
        return (minv, maxv, integralv/tempsv, integralv)
        
        
        
    }
    
    // Power Stats
    
    func powerStats(from t:TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double){
        
        
        let v = BLENinebot.kCurrent
        let x = t
        
        
        if self.data[v].log.count <= 0{       // No Data
            return (0.0, 0.0, 0.0, 0.0)
        }
        
        var p0 = 0
        var p1 = self.data[v].log.count - 1
        let xd = Double(x)
        
        var minv = 0.0
        var maxv = 0.0
        var integralv = 0.0
        var tempsv = 0.0
        
        var oldx = 0.0
        var oldy = 0.0
        var x1 = 0.0
        var y1 = 0.0
        
        var i = 0
        
        
        while p1 - p0 > 1{
            
            let p = (p1 + p0 ) / 2
            
            let xValue = self.data[v].log[p].time.timeIntervalSince(self.firstDate!)
            
            if xd < xValue {
                p1 = p
            }
            else if xd > xValue {
                p0 = p
            }
            else{
                p0 = p
                p1 = p
            }
        }
        
        // If p0 == p1 easy
        
        if p0 == p1 {
            
            
            oldx = x
            oldy = self.current(p0) * voltage(time : x)     // Wats
            i = p1
        }
        else {      // Intentem interpolar
            
            let v0 = self.data[v].log[p0]
            let v1 = self.data[v].log[p1]
            
            if v0.time.compare( v1.time) == ComparisonResult.orderedSame{   // One more check not to have div/0
                oldx = x
                oldy = Double(v0.value) / 100.0 * self.voltage(time: x)
                i = p1
            }
            else{
                
                let deltax = v1.time.timeIntervalSince(v0.time)
                let deltay = (Double(v1.value) / 100.0  * self.voltage(time: v1.time.timeIntervalSince(self.firstDate!))) - (Double(v0.value) / 100.0  * self.voltage(time: v0.time.timeIntervalSince(self.firstDate!)))
                let v = (x - v0.time.timeIntervalSince(self.firstDate!)) / deltax * deltay + Double(v0.value)
                
                oldx = x
                oldy = v
                i = p1
            }
            
        }
        
        minv = oldy
        maxv = oldy
        
        // i sempre apunta al proper punt. Aleshores fem
        
        x1 = self.data[v].log[i].time.timeIntervalSince(self.firstDate!)
        y1 = Double(self.data[v].log[i].value) / 100.0 * self.voltage(time: x1)
        
        while x1 < t1{
            
            if y1 < minv {
                minv = y1
            }
            
            if y1 > maxv {
                maxv = y1
            }
            
            integralv += (y1 + oldy) / 2.0 * (x1 - oldx)
            tempsv += x1 - oldx
            oldx = x1
            oldy = y1
            
            
            i += 1
            
            if i >= self.data[v].log.count{
                break
            }
            
            x1 = self.data[v].log[i].time.timeIntervalSince(self.firstDate!)
            y1 = Double(self.data[v].log[i].value)  / 100.0 * self.voltage(time: x1)
            
        }
        
        // OK ens queda un trocet des de oldx a x. A fer mes endavant
        
        return (minv, maxv, integralv/tempsv, integralv)
        
        
        
    }
    
    
    func getLogValue(_ variable : Int, time : TimeInterval) -> Double{
        switch(variable){
            
        case 0:
            return self.speed(time: time)
            
        case 1:
            return self.temperature(time: time)
            
        case 2:
            return self.voltage(time: time)
            
        case 3:
            return self.current(time: time)
            
        case 4:
            return self.batteryLevel(time: time)
            
        case 5:
            return self.pitch(time: time)
            
        case 6:
            return self.roll(time: time)
            
        case 7:
            return self.singleMileage(time: time)
            
        case 8:
            return self.altitude(time: time)
            
        case 9:
            return self.power(time: time)
            
        case 10:
            return self.energy(time: time)
            
        default:
            return 0.0
            
        }
    }
    
    func getLogStats(_ variable : Int, from t0 : TimeInterval, to t1 : TimeInterval) -> (Double, Double, Double, Double){
        switch(variable){
            
        case 0:
            return self.speed(from: t0, to: t1)
            
        case 1:
            return self.temperature(from: t0, to: t1)
            
        case 2:
            return self.voltage(from: t0, to: t1)
            
        case 3:
            return self.current(from: t0, to: t1)
            
        case 4:
            return self.batteryLevel(from: t0, to: t1)
            
        case 5:
            return self.pitch(from: t0, to: t1)
            
        case 6:
            return self.roll(from: t0, to: t1)
            
        case 7:
            let s0 = self.singleMileage(time: t0)
            let s1 = self.singleMileage(time: t1)
            let t = t1 - t0
            return (s0, s1, ((s0 + s1) / 2.0) , ((s1 - s0) * t))
            
        case 8:
            return self.altitude(from: t0, to: t1)
            
        case 9:
            return self.powerStats(from: t0, to: t1)
            
            
        case 10:
            return self.energy(from: t0, to: t1)
            
        default:
            return (0.0, 0.0, 0.0, 0.0)
            
        }
    }
    
    
    func getLogValue(_ variable : Int, index : Int) -> Double{
        
        switch(variable){
            
        case 0:
            return self.speed(index)
            
        case 1:
            return self.temperature(index)
            
        case 2:
            return self.voltage(index)
            
        case 3:
            return self.current(index)
            
        case 4:
            return self.batteryLevel(index)
            
        case 5:
            return self.pitch(index)
            
        case 6:
            return self.roll(index)
            
        case 7:
            return self.singleMileage(index)
            
        case 8:
            return self.altitude(index)
            
        case 9:
            return self.power(index)
            
        case 10:
            return self.energy(index)
            
        default:
            return 0.0
            
        }
    }
    
    //TODO: Create .zip file
    //
    // Create a directory and fill it with :
    //
    //  One file for variable
    //  One gpx file if needed
    //  Zip all files -> name.zip
    //  Delete directory
    
    // Ride mode
    
    // One Fun Bool ?
    
    
    
}
