//
//  WheelTrack.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 28/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
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
//  WheelTrack represents the state of the current or historic track of the wheel
//

import UIKit
import MapKit


class WheelTrack: NSObject {
    
    
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
        
    }
    
    enum Unit : String{
        case String
        case Integer
        case Meters
        case Seconds
        case Meters_per_Second
        case Amperes
        case Volts
        case Wats
        case Joules
        case Celsius_Degrees
        case Percent
        case Degrees
    }
    
    
    
    struct LogEntry {
        var timestamp : NSTimeInterval
        var value : Double
    }
    
    struct WheelVariable {
        var codi : WheelValue      // Meaning
        var timeStamp : NSTimeInterval     // Last Update since firstDate
        var currentValue : Double         // Value
        var minValue : Double      // Minimum value
        var maxValue : Double      // Maximum Value
        var avgValue : Double      // Avg Value = integralValue/timeStamp
        var intValue : Double      // Integral (value * dt)
        var loaded : Bool = false  // Log loaded from file
        var log : [LogEntry] // Log Array
    }
    
    private var units : [WheelValue : Unit] = [
        .StartDate : .Seconds,
        .Name : .String,
        .SerialNo : .String,
        .Version : .String,
        .LimitSpeed : .Meters_per_Second,
        .MaxSpeed : .Meters_per_Second,
        .RidingLevel : .Integer,
        .AcumDistance : .Meters,
        .AcumRuntime : .Seconds,
        .Altitude : .Meters,
        .Latitude : .Degrees,
        .Longitude : .Degrees,
        .AltitudeGPS : .Meters,
        .Distance : .Meters,
        .Duration : .Seconds,
        .Speed : .Meters_per_Second,
        .Pitch : .Degrees,
        .Roll : .Degrees,
        .Voltage : .Volts,
        .Current : .Amperes,
        .Power : .Wats,
        .Energy : .Joules,
        .Battery : .Percent,
        .Temperature : .Celsius_Degrees]
    
    
    var url : NSURL?
    private var name : String?
    private var serialNo : String?
    private var version : String?
    
    private var trackImg : UIImage?
    
    
    private var data = [WheelValue : WheelVariable]()
    
    var firstDate : NSDate?
    
    private var distOffset = 0.0  // Just to support stop start without affecting total distance. We supose we start at same place we stopped
    
    private var ascent : Double?
    private var descent : Double?
    private var energyUsed : Double?
    private var energyRecovered : Double?
    private var batCapacity : Double = 340.0 * 3600.0
    
    //MARK: Conversion variables
    
    static var conversion = Array<WheelTrack.WheelValue?>(count : 256, repeatedValue: nil)
    static var scales = Array<Double>(count : 256, repeatedValue: 1.0)
    
    
    //MARK: .gpx export variables
    
    private let xmlHeader : String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<gpx xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.cluetrust.com/XML/GPXDATA/1/0 http://www.cluetrust.com/Schemas/gpxdata10.xsd http://www.gorina.es/XML/TRACESDATA/1/0/tracesdata.xsd\" xmlns:gpxdata=\"http://www.cluetrust.com/XML/GPXDATA/1/0\" xmlns:tracesdata=\"http://www.gorina.es/XML/TRACESDATA/1/0\" version=\"1.1\" creator=\"9BMetrics - http://www.gorina.es/9BMetrics\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
    
    private let xmlFooter = "</trkseg>\n</trk>\n</gpx>\n"
    
    
    private var trackHeader : String {
        return "<trk>\n<name>$</name>\n\n<trkseg>\n"
    }
    //MARK: Auxiliary functions
    
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
        
        scales[BLENinebot.kLatitude] = 0.00001
        scales[BLENinebot.kLongitude] = 0.00001
        scales[BLENinebot.kAltitude] = 0.01
        scales[BLENinebot.kPower] = 1.0
        scales[BLENinebot.kEnergy] = 0.01 * 3600.0
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
        
        
    }
    
    
    var otherFormatter : NSDateFormatter = NSDateFormatter()
    
    override init(){
        super.init()
        
        WheelTrack.initConversion()
        
        otherFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        otherFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        otherFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
    }
    
    
    func clearAll(){
        
        url = nil
        data.removeAll()
        name = nil
        serialNo = nil
        version = nil
        firstDate = nil
        distOffset = 0.0
        ascent = nil
        descent = nil
        energyUsed = nil
        energyRecovered = nil
        trackImg = nil
    }
    
    func HMSfromSeconds(secs : NSTimeInterval) -> (Int, Int, Int) {
        
        let hours =  floor(secs / 3600.0)
        let minutes = floor((secs - (hours * 3600.0)) / 60.0)
        let seconds = round(secs - (hours * 3600.0) - (minutes * 60.0))
        
        return (Int(hours), Int(minutes), Int(seconds))
        
    }
    
    
    private func postVariableChanged(variable : WheelVariable){
        
        let info : [NSObject : AnyObject] = ["variable" : variable.codi.rawValue]
        let not = NSNotification(name: kWheelVariableChangedNotification, object: self, userInfo: info)
        
        NSNotificationCenter.defaultCenter().postNotification(not)
    }
    
    
    //MARK: Adding data
    
    
    // addValueWithDate is the main addValue function for numeric values
    //
    // All other functions call this one. If there is a change in some value
    // sends a Notification so everybody may update its user interface
    // forced forgets optimization if many values
    // silent doesn't posts notification if values change (for loading files, etc.)
    //
    func addValueWithDate(dat: NSDate, variable : WheelValue, value : Double, forced : Bool, silent: Bool){
        
        // First value of all sets firstDate!!!
        
        if firstDate == nil {
            firstDate = dat
        }
        
        
        let t = dat.timeIntervalSinceDate(firstDate!)
        
        if data[variable] == nil {
            
            let varData = WheelVariable(codi: variable, timeStamp: t, currentValue: value, minValue: value, maxValue: value, avgValue: value, intValue: 0.0, loaded: true , log: [])
            data[variable] = varData
        }
        
        
        let v = LogEntry(timestamp: dat.timeIntervalSinceDate(firstDate!), value: value)
        
        let postChange = data[variable]!.currentValue != value && !silent
        
        if data[variable]!.currentValue != value || data[variable]!.log.count <= 1 || forced {
            data[variable]!.log.append(v)
            
        }else {
            
            let c = data[variable]!.log.count
            let e = data[variable]!.log[c-2]
            
            if e.value != value{
                data[variable]!.log.append(v)
            }else {
                data[variable]!.log[c-1] = v
            }
            
        }
        
        // OK, now update all acums. That is interesting
        
        data[variable]!.currentValue = value
        data[variable]!.minValue = min( data[variable]!.minValue, value)
        data[variable]!.maxValue = max( data[variable]!.maxValue, value)
        data[variable]!.intValue =  data[variable]!.intValue + (value * (t -  data[variable]!.timeStamp))
        data[variable]!.avgValue =  data[variable]!.intValue / t
        data[variable]!.timeStamp = t
        data[variable]!.loaded = true
        
        if postChange{
            postVariableChanged( data[variable]!)
        }
    }
    
    
    // Auxiliary addValue functions
    
    func addValue(variable:WheelValue, value:Double){
        addValueWithDate(NSDate(), variable : variable, value : value, forced : false, silent: false)
    }
    
    func addValueWithDate(dat: NSDate, variable : WheelValue, value : Double){
        addValueWithDate(dat, variable : variable, value : value, forced : false, silent: false)
    }
    
    
    func addValueWithTimeInterval(time: NSTimeInterval, variable : WheelValue, value : Double){
        
        addValueWithTimeInterval(time, variable : variable, value : value, forced : false, silent: false)
    }
    
    func addValueWithTimeInterval(time: NSTimeInterval, variable : WheelValue, value : Double, forced : Bool, silent: Bool){
        
        if firstDate == nil {
            firstDate = NSDate().dateByAddingTimeInterval(-time)
        }
        
        let date = firstDate!.dateByAddingTimeInterval(time)
        
        self.addValueWithDate(date, variable: variable, value: value, forced: forced, silent: silent)
    }
    
    func addLogValue(time: NSTimeInterval, variable : WheelValue, value : Double){
        if data[variable] == nil {
            return
        }
        
        data[variable]!.log.append(LogEntry(timestamp: time, value: value))
        
    }
    
    // Setting general information
    
    func setName(name : String){
        self.name = name
    }
    func setSerialNo(serialNo : String){
        self.serialNo = serialNo
    }
    func setVersion(version : String){
        self.version = version
    }
    
    
    // MARK: Query Functions
    
    
    func hasDataInVariable(v : WheelValue) -> Bool{
        guard let vv = data[v] where vv.log.count > 0 else {return false}
        return true
    }
    
    func hasData()->Bool{       // Returns true if we have logged at least current data
        return hasDataInVariable(.Current)
    }
    
    func hasGPSData() -> Bool{
        
        let n1 = countLogForVariable(.Latitude)
        let n2 = countLogForVariable(.Longitude)
        
        return n1 > 0 && n2 > 0
    }
    
    func countLogForVariable(v : WheelValue) -> Int{
        
        if let vv = data[v] {
            if !vv.loaded{
                loadVariableFromPackage(v)
            }
            
            return data[v]!.log.count
        }else {
            return 0
        }
    }
    
    func currentValueForVariable(v : WheelValue) -> Double?{
        
        if let vv = data[v] {
            return vv.currentValue
        }else {
            return nil
        }
    }
    
    func entryAtPointForVariable(v : WheelValue, atPoint point : Int) -> LogEntry?{
        
        if let vv = data[v] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
            
            if  vv.log.count > point{
                return vv.log[point]
            }else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func valueAtPointForVariable(v : WheelValue, atPoint point : Int) -> Double?{
        if let e = entryAtPointForVariable(v, atPoint : point){
            return e.value
        }else {
            return nil
        }
    }
    
    func timeAtPointForVariable(v : WheelValue, atPoint point : Int) -> NSTimeInterval?{
        if let e = entryAtPointForVariable(v, atPoint : point){
            return e.timestamp
        }else {
            return nil
        }
    }
    
    func dateAtPointForVariable(v : WheelValue, atPoint point : Int) -> NSDate?{
        if let e = entryAtPointForVariable(v, atPoint : point), date = firstDate{
            return date.dateByAddingTimeInterval(e.timestamp)
        }else {
            return nil
        }
    }
    
    
    
    func value(variable : WheelValue,  forTime t:NSTimeInterval) -> LogEntry?{
        
        if let vv = data[variable] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
        }
        
        guard let v = data[variable] where v.log.count > 0 else {return nil}
        
        let x = t
        
        var p0 = 0
        var p1 = v.log.count - 1
        let xd = Double(x)
        
        while p1 - p0 > 1{
            
            let p = (p1 + p0 ) / 2
            
            let xValue = v.log[p].timestamp
            
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
            let e = v.log[p0]
            return LogEntry(timestamp: x, value: e.value)
            
        }
        else {      // Intentem interpolar
            
            let v0 = v.log[p0]
            let v1 = v.log[p1]
            
            if v0.timestamp == v1.timestamp{   // Careful because if equal we may not interpolate. Famous div by 0
                return LogEntry(timestamp: v0.timestamp, value: (v0.value + v1.value)/2.0)
                
            }
            
            let deltax = v1.timestamp - v0.timestamp
            let deltay = v1.value - v0.value
            
            let v = (x - v0.timestamp) / deltax * deltay + v0.value
            
            return LogEntry(timestamp: x, value: v)
        }
    }
    
    
    
    // Returns min, max, avg and acum (integral trapezoidal)
    
    func getFirstLast(variable: WheelValue) -> (Double, Double){
        if let vv = data[variable] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
            
            if data[variable]!.log.count > 0{
                return (data[variable]!.log.first!.value, data[variable]!.log.last!.value)
            }
            
        }
        
        return (0.0, 0.0)
    }
    
    func getCurrentStats(variable : WheelValue) -> (Double, Double, Double, Double){
        if let vv = data[variable] {
            return (vv.minValue, vv.maxValue, vv.avgValue, vv.intValue)
        } else {
            return (0.0, 0.0, 0.0, 0.0)
        }
    }
    
    func stats(variable : WheelValue,  from t:NSTimeInterval, to t1: NSTimeInterval) -> (Double, Double, Double, Double){
        
        if let vv = data[variable] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
        }
        
        guard let v = data[variable] where v.log.count > 0 else {return (0.0, 0.0, 0.0, 0.0)}
        let x = t
        
        
        var p0 = 0
        var p1 = v.log.count - 1
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
            
            let xValue = v.log[p].timestamp
            
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
        
        if v.log[p0].timestamp > x{
            p1 = p0
        }
        
        
        
        
        // If p0 == p1 easy
        
        if p0 == p1 {
            
            let e = v.log[p0]
            oldx = x
            oldy = e.value
            i = p1
        }
        else {      // Intentem interpolar
            
            let v0 = v.log[p0]
            let v1 = v.log[p1]
            
            if v0.timestamp == v1.timestamp{   // One more check not to have div/0
                oldx = x
                oldy = v0.value
                i = p1
            }
            else{
                
                let deltax = v1.timestamp - v0.timestamp
                let deltay = v1.value - v0.value
                let v = (x - v0.timestamp) / deltax * deltay + v0.value
                
                oldx = x
                oldy = v
                i = p1
            }
            
        }
        
        minv = oldy
        maxv = oldy
        
        // i sempre apunta al proper punt. Aleshores fem
        
        x1 = v.log[i].timestamp
        y1 = v.log[i].value
        
        
        
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
            
            if i >= v.log.count{
                break
            }
            
            x1 = v.log[i].timestamp
            y1 = v.log[i].value
            
        }
        
        // OK ens queda un trocet des de oldx a x. A fer mes endavant
        
        return (minv, maxv, integralv/tempsv, integralv)
    }
    
    
    func buildPower(){
        
        
        if hasDataInVariable(.Power){ // Don't touch data if posible
            return
        }
        
        guard let current = data[.Current] where current.log.count > 0 else {return} // Nothing to do :(
        
        for e in current.log{
            
            if let v = value(.Voltage, forTime: e.timestamp){
                
                addValueWithTimeInterval(e.timestamp, variable: .Power, value: e.value * v.value, forced: false, silent: true)
            }
            
        }
        
    }
    func buildEnergy(){
        
        if hasDataInVariable(.Energy){      // Don't touch
            return
        }
        buildPower()
        
        guard let current = self.data[.Current] where current.log.count > 0 else {return}   // No Way
        guard let power = data[.Power] where power.log.count > 0 else {return}
        
        var acum = 0.0
        var t0 = current.log[0].timestamp
        var v0 = getValueForVariable(.Power, atPoint: 0)
        
        addValueWithTimeInterval(t0, variable: .Energy, value: 0.0, forced: true, silent: true)
        
        for i in 1..<current.log.count{
            
            let t1 = current.log[i].timestamp
            let v1 = power.log[i].value
            
            
            acum = acum + (v1 + v0) / 2.0 * (t1 - t0)
            t0 = t1
            v0 = v1
            
            addValueWithTimeInterval(t0, variable: .Energy, value: acum, forced: true, silent: true)
        }
        
    }
    
    func getLastTimeValueForVariable(variable: WheelValue) -> NSTimeInterval{
        if let v = data[variable]{
            return v.timeStamp
        }else{
            return 0.0
        }
    }
    
    func getTimeIntervalForVariable(variable: WheelValue, toDate: NSDate) -> NSTimeInterval{
        if let v = data[variable]{
            
            if let fd = firstDate{
                return toDate.timeIntervalSinceDate(fd) - v.timeStamp
            }else{
                return 0.0
            }
        } else {
            return 0.0
        }
    }
    
    func getCurrentValueForVariable(variable: WheelValue) -> Double{
        
        switch variable{
        case .Power:
            buildPower()
        case .Energy:
            buildEnergy()
        default:
            break
        }
        
        if let v = data[variable]{
            return v.currentValue
        }else{
            return 0.0
        }
    }
    
    func getValueForVariable(variable:WheelValue, atPoint: Int) -> Double{
        
        switch variable{
        case .Power:
            buildPower()
        case .Energy:
            buildEnergy()
        default:
            break
        }
        
        if let v = valueAtPointForVariable(variable, atPoint: atPoint){
            return v
        }else {
            return 0.0
        }
    }
    
    func getValueForVariable(variable:WheelValue, time: NSTimeInterval) -> Double {
        
        switch variable{
        case .Power:
            buildPower()
        case .Energy:
            buildEnergy()
        default:
            break
        }
        
        if let v = value(variable, forTime: time){
            return v.value
        }else{
            return 0.0
        }
    }
    
    
    //MARK Specific functions
    
    func getName() -> String?{
        return self.name
    }
    
    func getSerialNo() -> String{
        if let v = self.serialNo{
            return v
        }else{
            return ""
        }
    }
    
    func getVersion() -> String{
        if let v = self.version{
            return v
        }else{
            return ""
        }
    }
    
    func getAscent() -> Double {
        if ascent == nil{
            
            let (a, d) = computeAscentDescent()
            ascent = a
            descent = d
            
        }
        
        if let v = ascent {
            return v
        }else{
            return 0.0
        }
    }
    
    func getDescent() -> Double {
        if descent == nil{
            let (a, d) = computeAscentDescent()
            ascent = a
            descent = d
        }
        
        if let v = descent {
            return v
        }else{
            return 0.0
        }
    }
    
    func getBatteryEnergy() -> Double{
        let (b0, b1) = getFirstLast(.Battery)
        
        return batCapacity * (b1 - b0)
        
    }
    
    func getEnergyUsed() -> Double{
        if energyUsed == nil{
            let (eu, er) = energyDetails(from: 0.0, to: 1E80)
            energyUsed = eu
            energyRecovered = er
        }
        
        if let v = energyUsed {
            return v
        }else{
            return 0.0
        }
    }
    
    func getEnergyRecovered() -> Double{
        if energyRecovered == nil{
            let (eu, er) = energyDetails(from: 0.0, to: 1E80)
            energyUsed = eu
            energyRecovered = er
        }
        
        if let v = energyRecovered {
            return v
        }else{
            return 0.0
        }
    }
    func getImage() -> UIImage?{
        if let img = self.trackImg{
            return img
        }else {
            
            trackImg = imageWithWidth(350.0,  height:350.0, color:UIColor.yellowColor(), backColor:UIColor.clearColor(), lineWidth: 2.0)
            
            return trackImg
            
        }
    }
    func energyDetails(from t0: NSTimeInterval, to t1: NSTimeInterval) -> (Double, Double){
        
        if let vv = data[.Energy] {
            if !vv.loaded {
                loadVariableFromPackage(.Energy)
            }
        }
        
        
        buildEnergy()
        
        if !hasDataInVariable(.Energy) {
            return (0.0, 0.0)
        }
        guard let energy = self.data[.Energy] else {return (0.0, 0.0)}
        
        var positive = 0.0
        var negative = 0.0
        
        var first = true
        
        
        var oldEntry = energy.log[0]
        for lv in energy.log{
            if !first {
                if oldEntry.value < lv.value{
                    positive += Double(lv.value - oldEntry.value)
                } else {
                    negative += Double(oldEntry.value - lv.value)
                }
            }
            oldEntry = lv
            first = false
            
        }
        
        return (positive, negative)
    }
    
    
    func computeAscentDescent() -> (ascent : Double, descent : Double){
        
        if let vv = data[.Altitude] {
            if !vv.loaded {
                loadVariableFromPackage(.Altitude)
            }
        }
        
        
        guard let datos = self.data[.Altitude] else {return (0.0, 0.0)}
        
        if datos.log.count <= 1{
            return (0.0, 0.0)
        }
        
        var ascent = 0.0
        var descent = 0.0
        
        var oldEntry = datos.log[0]
        
        for i in 1..<datos.log.count {
            
            let e = datos.log[i]
            
            if e.value > oldEntry.value {
                ascent = ascent + (e.value - oldEntry.value)
            }
            else{
                descent = descent - (e.value - oldEntry.value)
            }
            
            oldEntry = e
            
        }
        
        return (ascent, descent)
    }
    
    // resample resamples a subset of the variable generating a new log with 
    // samples distanced a fixed amount.
    
    func resample(variable:WheelValue, from:NSTimeInterval, to:NSTimeInterval, step:Double) -> [LogEntry]?{
        
        if let vv = data[variable] {
            if !vv.loaded {
                loadVariableFromPackage(variable)
            }
        } else {
            return nil
        }
        
        if data[variable]!.log.count <= 1{
            return nil
        }
        
        var sampledLog : [LogEntry] = []
        
        var t0 : NSTimeInterval = 0
        var t1 : NSTimeInterval = step
        
        var lp : LogEntry = LogEntry(timestamp: 0.0 , value : data[variable]!.log[0].value)
        var acum : Double = 0.0
        
        
        for e in data[variable]!.log {
            
            while e.timestamp >= t1 && e.timestamp != lp.timestamp{
                
                
                let np = LogEntry(timestamp: t1, value: (e.value - lp.value) / (e.timestamp - lp.timestamp) * (t1 - lp.timestamp) + lp.value)
                
                acum = acum + (np.value  + lp.value) / 2.0 * (np.timestamp - lp.timestamp)
                
                
                let newEntry = LogEntry(timestamp: (t0 + t1) / 2.0, value: acum / step)
                sampledLog.append(newEntry)
                
                acum = 0.0
                lp = np
                t0 = t1
                t1 = t0 + step
                
            }
            
            acum = acum + (e.value  + lp.value) / 2.0 * (e.timestamp - lp.timestamp)
            lp = e
        }
        
        return sampledLog
     }
    //MARK: Access to some files 
    
    func getGPXURL() -> NSURL?{
        
        if let myUrl = self.url {
            let gpxURL = myUrl.URLByAppendingPathComponent("track.gpx")
            
            return gpxURL
        }
        else{
            return nil
        }
    }
    
    //MARK: Log Functions
    //TODO: Must go to GraphicsController
    
    
    
    
    //MARK: File Management
    
    // Exports a subset of data to a csv, excel compatible file
    
    func createCSVFileFrom(from : NSTimeInterval, to: NSTimeInterval) -> NSURL?{
        // Format first date into a filepath
        
        let newName : String
        let ldateFormatter = NSDateFormatter()
        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'Sel_'yyyyMMdd'_'HHmmss'.csv'"
        if let date = firstDate{
            newName = ldateFormatter.stringFromDate(date)
        }else{
            newName = ldateFormatter.stringFromDate(NSDate())
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        var path : String = ""
        
        if let dele = appDelegate {
            let docs = dele.applicationDocumentsDirectory()
            
            if let d = docs {
                path = d.path!
            }
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ).stringByAppendingString(newName )
        
        
        let mgr = NSFileManager.defaultManager()
        
        mgr.createFileAtPath(tempFile, contents: nil, attributes: nil)
        let file = NSURL.fileURLWithPath(tempFile)
        
        
        
        do{
            let hdl = try NSFileHandle(forWritingToURL: file)
            // Get time of first item
            
            if firstDate == nil {
                firstDate = NSDate()
            }
            
            
            let title = String(format: "Time\tCurrent\tVoltage\tPower\tEnergy\tSpeed\tAlt\tDist\tPitch\tRoll\tBatt\tTºC\n")
            hdl.writeData(title.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            // Get first ip of current
            
            for i in 0 ..< countLogForVariable(.Current) {
                
                if let e = entryAtPointForVariable(.Current, atPoint: i) {
                    
                    let t = e.timestamp
                    
                    if from <= t && t <= to {
                        
                        let vCurrent = getValueForVariable(.Current, atPoint: i)
                        let vVoltage = getValueForVariable(.Voltage, time: t)
                        let vPower = getValueForVariable(.Power, time: t)
                        let vEnergy = getValueForVariable(.Energy, time: t)
                        let vSpeed = getValueForVariable(.Speed, time: t)
                        let vAlt = getValueForVariable(.Altitude, time: t)
                        let vDistance = getValueForVariable(.Distance, time: t)
                        let vPitch = getValueForVariable(.Pitch, time: t)
                        let vRoll = getValueForVariable(.Roll, time: t)
                        let vBattery = getValueForVariable(.Battery, time: t)
                        let vTemp = getValueForVariable(.Temperature, time: t)
                        
                        
                        let s = String(format: "%0.3f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\t%0.2f\n", t, vCurrent, vVoltage, vPower, vEnergy, vSpeed, vAlt, vDistance, vPitch, vRoll, vBattery, vTemp)
                        if let vn = s.dataUsingEncoding(NSUTF8StringEncoding){
                            hdl.writeData(vn)
                        }
                    }
                }
            }
            
            
            hdl.closeFile()
            
            return file
            
        }
        catch{
            if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error",format:"Error when trying to get handle for %@", file)
            }
            
            AppDelegate.debugLog("Error al obtenir File Handle")
        }
        
        return nil
        
    }
    
    // Version 4 uses variable names standardized for all wheels and uses SI units
    
    func createSummaryFile() -> String?{
        
        guard let date = firstDate else {return nil}    // Timestamps have no sens without firstDate
        
        var str = String(format: "Date,%f\n", date.timeIntervalSince1970)
        str.appendContentsOf(String(format: "Energy_Used,%f\n", getEnergyUsed()))
        str.appendContentsOf(String(format: "Energy_Recovered,%f\n", getEnergyRecovered()))
        str.appendContentsOf(String(format: "Ascent,%f\n", getAscent()))
        str.appendContentsOf(String(format: "Descent,%f\n", getDescent()))
        
        for (_, v) in data{
            // Linies tenen el nom de la variable + currentValue, min, max, avg, int values
            
            str.appendContentsOf(String(format: "%@,%.3f,%.2f,%.2f,%.2f,%.2f,%.2f\n", v.codi.rawValue, v.timeStamp,  v.currentValue, v.minValue, v.maxValue, v.avgValue, v.intValue))
        }
        
        return str
        
    }
    
    func loadSummary(str : String) {
        
        let lines = str.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        for line in lines {
            let fields = line.componentsSeparatedByString(",")
            let codeStr = fields[0]
            
            switch codeStr {
                
            case "Date":
                guard let dt = Double(fields[1].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                firstDate = NSDate(timeIntervalSince1970: dt)
                
            case "Energy_Used":
                guard let val = Double(fields[1].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                energyUsed = val
                
            case "Energy_Recovered":
                guard let val = Double(fields[1].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                energyRecovered = val
                
            case "Ascent":
                guard let val = Double(fields[1].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                ascent = val
                
            case "Descent":
                guard let val = Double(fields[1].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                descent = val
                
            default:
                
                if let codi = WheelValue(rawValue: codeStr){
                    
                    guard let dt = Double(fields[1].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                    guard let curv = Double(fields[2].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                    guard let minv = Double(fields[3].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                    guard let maxv = Double(fields[4].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                    guard let avgv = Double(fields[5].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                    guard let intv = Double(fields[6].stringByReplacingOccurrencesOfString(" ", withString: "")) else {continue }
                    
                    if data[codi] == nil{
                        data[codi] = WheelVariable(codi: codi, timeStamp: dt, currentValue: curv , minValue: minv , maxValue: maxv , avgValue: avgv , intValue: intv, loaded: false, log: [])
                        
                    } else {
                        
                        data[codi]!.timeStamp = dt
                        data[codi]!.currentValue = curv
                        data[codi]!.minValue = minv
                        data[codi]!.maxValue = maxv
                        data[codi]!.avgValue = avgv
                        data[codi]!.intValue = intv
                        
                    }
                    
                }
            }
        }
    }
    
    func variableLogtoString(variable : WheelValue) -> String?{
        
        guard let v = data[variable] where v.log.count > 0 else {return nil}
        
        let varName = v.codi.rawValue
        
        let version = String(format: "Version,4,Start,%0.3f,Variable,%@\n", firstDate!.timeIntervalSince1970, varName)
        
        var buff = version
        
        
        AppDelegate.debugLog("Gravant file log per %@", varName)
        
        for item in v.log {
            let t = item.timestamp
            buff += String(format: "%0.3f,%f\n", t, item.value)
        }
        return buff
        
    }
    
    func addValuesFromString(s : String) {
        
        
        let lines = s.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        var lineNumber = 0
        var version = 1
        var date0 : NSDate?
        var variable : WheelValue?
        
        
        for line in lines {
            let fields = line.componentsSeparatedByString(",")
            
            if lineNumber == 0 {
                
                if fields[0] == "Version"{
                    if let v = Int(fields[1]){
                        
                        if v == 4{
                            version = v
                            
                            // field 3 has first date
                            
                            guard let dt = Double(fields[3].stringByReplacingOccurrencesOfString(" ", withString: "")) else {return }
                            date0 = NSDate(timeIntervalSince1970: dt)
                            let varstr = fields[5].stringByReplacingOccurrencesOfString(" ", withString: "")
                            variable = WheelValue(rawValue: varstr)
                            self.firstDate = date0
                            
                        } else {
                            AppDelegate.debugLog("Error amb version %d", v)
                            lineNumber += 1
                            return
                        }
                    }
                    
                    
                } else {
                    AppDelegate.debugLog("Incorrect Format")
                    lineNumber += 1
                    return
                }
                lineNumber += 1
                continue
            }
                
            else if version == 4 && fields.count == 2 {
                
                guard let vari = variable else {return} // If there is no variable we may not do anything
                
                guard let dt = Double(fields[0]) else {lineNumber+=1; continue }
                guard let value = Double(fields[1]) else {lineNumber+=1; continue}
                
                addLogValue(dt, variable : vari, value :value)
            }
            
            lineNumber += 1
            
        }
    }
    
    
    func createPackage(name : String) -> NSURL?{
        
        guard let docDir = (UIApplication.sharedApplication().delegate as! AppDelegate).applicationDocumentsDirectory() else {return nil}
        
        let pkgURL = docDir.URLByAppendingPathComponent(name).URLByAppendingPathExtension("9bm")
        
        // Try to use file wrappers (ufff)
        
        let contents = NSFileWrapper(directoryWithFileWrappers: [:])
        
        for(_, v) in self.data {
            NSLog("Data %@, %.2f", v.codi.rawValue, v.currentValue)
            
        }
        
        if let s = createSummaryFile(){
            let filename = "summary.csv"
            if let dat = s.dataUsingEncoding(NSUTF8StringEncoding){
                let fWrapper = NSFileWrapper(regularFileWithContents: dat)
                fWrapper.preferredFilename = filename
                contents.addFileWrapper(fWrapper)
            }
        }
        
        trackImg = imageWithWidth(350.0,  height:350.0, color:UIColor.yellowColor(), backColor:UIColor.clearColor(), lineWidth: 2.0)
        
        if let img = trackImg{
            if let imgData = UIImagePNGRepresentation(img){
                let filename = "image.png"
                let fWrapper = NSFileWrapper(regularFileWithContents: imgData)
                fWrapper.preferredFilename = filename
                contents.addFileWrapper(fWrapper)
            }
            
        }
        
        if hasGPSData() {
            
            if let gpxData = self.createGPXString().dataUsingEncoding(NSUTF8StringEncoding) {
                let filename = "track.gpx"
                let fWrapper = NSFileWrapper(regularFileWithContents: gpxData)
                fWrapper.preferredFilename = filename
                contents.addFileWrapper(fWrapper)
            }
        }
        
        for (_, v) in self.data {
            if v.log.count > 0{
                
                let vn = v.codi.rawValue
                let fileName = String(format: "%@.csv", vn)
                let binName = String(format: "%@.bin", vn)
                
                // Save a binary copy of array
                
                var l = v.log
                let nbytes = sizeof(LogEntry) * l.count
                let dat = NSData(bytes: &l, length: nbytes)
                let binWrapper = NSFileWrapper(regularFileWithContents: dat)
                binWrapper.preferredFilename = binName
                contents.addFileWrapper(binWrapper)
                
                
                if let s = variableLogtoString(v.codi){
                    if let dat = s.dataUsingEncoding(NSUTF8StringEncoding){
                        let fWrapper = NSFileWrapper(regularFileWithContents: dat)
                        fWrapper.preferredFilename = fileName
                        contents.addFileWrapper(fWrapper)
                    }
                }
            }
        }
        do{
            try contents.writeToURL(pkgURL, options: .WithNameUpdating, originalContentsURL: pkgURL)
        }catch let err as NSError{
            
            
            AppDelegate.debugLog("Error al gravar arxius %@", err.description)
            return nil
        }
        
        setThumbImage(pkgURL)
        
        return pkgURL
    }
    
    func loadVariableFromPackage(variable: WheelValue){
        
        if let pkgURL = self.url{
            
            let fileURL = pkgURL.URLByAppendingPathComponent(variable.rawValue).URLByAppendingPathExtension("csv")
            
            
            let binURL = pkgURL.URLByAppendingPathComponent(variable.rawValue).URLByAppendingPathExtension("bin")
            
            
            // Try to load the binary values
            
                if let logData = NSData(contentsOfURL: binURL){
                    
                    let n = logData.length / sizeof(LogEntry)
                    
                    var newLog : [LogEntry] = Array<LogEntry>(count: n, repeatedValue: LogEntry(timestamp: 0.0, value: 0.0))
                    
                    logData.getBytes(&newLog, length: logData.length)
                    
                    if self.data[variable] != nil {
                        self.data[variable]!.log = newLog
                        self.data[variable]!.loaded = true
                        
                        return
                        
                    }
                    
                }
                
            
            do {
                let str = try String(contentsOfURL: fileURL, encoding: NSUTF8StringEncoding)
                addValuesFromString(str)
                
                if self.data[variable] != nil{
                    self.data[variable]!.loaded = true
                 }
                
            }catch{
                
            }
        }
    }
    
    func loadPackage(url : NSURL) {
        
        clearAll()
        
        do{
            let pack = try NSFileWrapper(URL: url, options: [])
            
            if pack.directory{
                
                self.url = url
                
                var binaryEnabled = false
                
                for (name, fw) in pack.fileWrappers!{
                    if fw.regularFile && name == "summary.csv"{
                        
                        if let str = String(data: fw.regularFileContents!, encoding: NSUTF8StringEncoding){
                            loadSummary(str)
                        }
                        
                    } else if fw.regularFile && name == "image.png" {
                        
                        self.trackImg = UIImage(data: fw.regularFileContents!)
                        
                    }else if fw.regularFile && name == "map.gpx"{
                        
                        
                        
                    }else if fw.regularFile {
 
                        if let fnam = fw.filename where fnam.hasSuffix(".bin"){
                            binaryEnabled = true
                        }
                        //if let str = String(data: fw.regularFileContents!, encoding: NSUTF8StringEncoding){
                        //addValuesFromString(str)
                        //}
                    }
                }
                
                if !binaryEnabled {
                    
                    // Reload all data
                    
                    for (_, e) in self.data{
                        loadVariableFromPackage(e.codi)
                    }
                    
                    // OK now update the package
                    
                    if let name = url.URLByDeletingPathExtension?.lastPathComponent {
                        let fm = NSFileManager.defaultManager()
                        if let newUrl = url.URLByDeletingPathExtension?.URLByAppendingPathExtension("bu"){
                            do{
                        
                                try fm.moveItemAtURL(url, toURL: newUrl)
                                let okurl = createPackage(name)
                                if okurl != nil {
                                    try fm.removeItemAtURL(newUrl)
                                } else {
                                    do {
                                        try fm.removeItemAtURL(url)
                                    }catch{
                                        
                                    }
                                    try fm.moveItemAtURL(newUrl, toURL: url)
                                }
                            }catch{
                                
                            }
                        }
                    }
                }
            }
        }catch{
            
        }
    }
    
    
    
    static func createZipFile(pkgUrl : NSURL) -> NSURL?{
        
        
        if let name = pkgUrl.URLByDeletingPathExtension?.lastPathComponent{
            
            
            let tmpDirURL = NSURL.fileURLWithPath(NSTemporaryDirectory(),isDirectory: true)
            let zipURL = tmpDirURL.URLByAppendingPathComponent(name).URLByAppendingPathExtension("9bz")
            
            do {
                var files : [NSURL] = [NSURL]()
                
                
                let pack = try NSFileWrapper(URL: pkgUrl, options: [])
                
                if pack.directory{
                    for (_, fw) in pack.fileWrappers!{
                        if let fname = fw.filename{
                            
                            if !fname.hasSuffix(".bin"){    // bin files are just for caching
                                files.append(pkgUrl.URLByAppendingPathComponent(fname))
                            }
                        }
                    }
                }
                
                try Zip.zipFiles(files, zipFilePath: zipURL, password: nil, progress: { (progress) -> () in
                    NSLog("Zip %f", progress)
                })
                
                return zipURL
            }catch{
                if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                    dele.displayMessageWithTitle("Error",format:"Error when trying to create zip file %@", zipURL)
                }
                AppDelegate.debugLog("Error al crear zip file")
                
                return nil
            }
            
            
        }
        
        return nil
    }
    
    
    internal func createGPXString() -> String{
        
        if !hasGPSData(){
            return ""
        }
        
        var buff = ""
        buff.appendContentsOf(xmlHeader)
        buff.appendContentsOf(trackHeader.stringByReplacingOccurrencesOfString("$", withString: "9BMetricsTrack"))
        
        let n = min(countLogForVariable(.Latitude), countLogForVariable(.Longitude))
        for i in 0..<n {
            
            guard let date = dateAtPointForVariable(.Latitude, atPoint: i) else {return ""}
            let lat = getValueForVariable(.Latitude, atPoint: i)
            let lon = getValueForVariable(.Longitude, atPoint: i)
            
            var ele : Double = 0.0
            if countLogForVariable(.AltitudeGPS) > i {
                ele = getValueForVariable(.AltitudeGPS, atPoint: i)
            }// Altitude in m
            
            
            let timestr =  self.otherFormatter.stringFromDate(date)
            
            let timeString : String = timestr.stringByReplacingOccurrencesOfString(" ",  withString: "").stringByReplacingOccurrencesOfString("\n",withString: "").stringByReplacingOccurrencesOfString("\r",withString: "")
            
            
            let s = String(format:"<trkpt lat=\"%7.5f\" lon=\"%7.5f\">\n<ele>%3.0f</ele>\n<time>\(timeString)</time>\n</trkpt>\n", lat, lon, ele)
            
            buff.appendContentsOf(s)
            
        }
        
        buff.appendContentsOf(xmlFooter)
        return buff
        
    }
    
    internal func createGPXFile(url : NSURL) -> (Bool)
    {
        //let cord : NSFileCoordinator = NSFileCoordinator(filePresenter: self.doc)
        //var error : NSError?
        
        //        cord.coordinateWritingItemAtURL(url,
        //           options: NSFileCoordinatorWritingOptions.ForReplacing,
        //          error: &error)
        //          { ( newURL :NSURL!) -> Void in
        
        // Check if it exits
        
        let mgr =  NSFileManager()
        
        
        
        let exists = mgr.fileExistsAtPath(url.path!)
        
        if !exists{
            mgr.createFileAtPath(url.path!, contents: "Hello".dataUsingEncoding(NSUTF8StringEncoding), attributes:nil)
        }
        
        
        
        if let hdl = NSFileHandle(forWritingAtPath: url.path!){
            hdl.truncateFileAtOffset(0)
            hdl.writeData(self.xmlHeader.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            hdl.writeData(self.trackHeader.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            let n = min(countLogForVariable(.Latitude), countLogForVariable(.Longitude))
            for i in 0..<n {
                
                guard let date = dateAtPointForVariable(.Latitude, atPoint: i) else {return false}
                let lat = getValueForVariable(.Latitude, atPoint: i)
                let lon = getValueForVariable(.Longitude, atPoint: i)
                
                var ele : Double = 0.0
                if countLogForVariable(.AltitudeGPS) > i {
                    ele = getValueForVariable(.AltitudeGPS, atPoint: i)
                }// Altitude in m
                
                
                let timestr =  self.otherFormatter.stringFromDate(date)
                
                let timeString : String = timestr.stringByReplacingOccurrencesOfString(" ",  withString: "").stringByReplacingOccurrencesOfString("\n",withString: "").stringByReplacingOccurrencesOfString("\r",withString: "")
                
                
                let s = String(format:"<trkpt lat=\"%7.5f\" lon=\"%7.5f\">\n<ele>%3.0f</ele>\n<time>\(timeString)</time>\n</trkpt>\n", lat, lon, ele)
                
                hdl.writeData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
                
            }
            
            hdl.writeData(self.xmlFooter.dataUsingEncoding(NSUTF8StringEncoding)!)
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
        
        if let vv = data[.Latitude] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
        }
        
        if let vv = data[.Longitude] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
        }
        
        // Loop over 3 and 4
        
        if let latArray = self.data[.Latitude]?.log, lonArray = self.data[.Longitude]?.log {
            
            let n = min(latArray.count, lonArray.count)
            
            for i in 0..<n{
                let lcd = CLLocationCoordinate2DMake(Double(latArray[i].value), Double(lonArray[i].value))
                locs.append(lcd)
            }
        }
        
        return locs
    }
    
    //MARK: Legacy
    
    func wheelValueFor9Bvalue(nbValue : Int) -> WheelValue?{
        if let wv = WheelTrack.conversion[nbValue] {
            return wv
        }else{
            return nil
        }
        
    }
    
    func loadTextFile(url:NSURL){
        
        self.clearAll()
        self.url = url
        
        do{
            
            let data = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
            let lines = data.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            
            var lineNumber = 0
            var version = 1
            var date0 : NSDate?
            var variable : Int = -1
            
            for line in lines {
                let fields = line.componentsSeparatedByString("\t")
                
                if lineNumber == 0 {
                    
                    if fields[0] == "Version"{
                        if let v = Int(fields[1]){
                            
                            if v >= 1 && v <= 2{
                                version = v
                                
                                // field 3 has first date
                                
                                guard let dt = Double(fields[3].stringByReplacingOccurrencesOfString(" ", withString: "")) else {return}
                                date0 = NSDate(timeIntervalSince1970: dt)
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
                    
                    let time = Double(fields[0].stringByReplacingOccurrencesOfString(" ", withString: ""))
                    let variable = Int(fields[1])
                    let value = Int(fields[2])
                    
                    if let t = time, i = variable, v = value {
                        if let wh = wheelValueFor9Bvalue(i){
                            let vd = Double(v) * WheelTrack.scales[i]
                            
                            self.addValueWithTimeInterval(t, variable: wh, value: vd, forced: true, silent: true)
                        }
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
                    
                    guard let dt = Double(fields[0].stringByReplacingOccurrencesOfString(" ", withString: "")) else {return}
                    
                    if let d = date0{
                        let t = NSDate(timeInterval: dt, sinceDate: d)
                        let value = Int(fields[1])
                        
                        if  let v = value {
                            if let wh = wheelValueFor9Bvalue(variable){
                                let vd = Double(v) * WheelTrack.scales[variable]
                                
                                self.addValueWithDate(t, variable: wh, value: vd, forced: true, silent: true)
                            }
                        }
                    }
                }
                
                lineNumber += 1
                
            }
            
            buildEnergy()
            buildPower()
            
        }catch {
            
        }
        
        // OK now build package.
        
        if let name = url.URLByDeletingPathExtension?.lastPathComponent {
            let newName = name.stringByReplacingOccurrencesOfString("9B_", withString: "")
            if let url = createPackage(newName){
                AppDelegate.debugLog("Package %@ created", url)
            }else{
                AppDelegate.debugLog("Error al crear Package")
            }
        }
        
    }
    
    //MARK: Image and gps track manipulation
    
    func computeTrackSize() -> (l0 : CLLocation?, l1 : CLLocation? ){
        
        if countLogForVariable(.Latitude) <= 0{
            return (nil, nil)
        }
        
        var latmin = getValueForVariable(.Latitude, atPoint: 0)
        var latmax = latmin
        var lonmin = getValueForVariable(.Longitude, atPoint: 0)
        var lonmax = lonmin
        
        for i in 1..<countLogForVariable(.Latitude){
            
            let lat = getValueForVariable(.Latitude, atPoint: i)
            let lon = getValueForVariable(.Longitude, atPoint: i)
            
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
        
        return (CLLocation(latitude: latmin, longitude: lonmin), CLLocation(latitude: latmax, longitude: lonmax))
        
    }
    
    func setThumbImage(url : NSURL){
        
        var thumb : UIImage?
        
        if self.hasGPSData(){
            thumb = self.imageWithWidth(256, height: 256)
        } else {
            thumb = UIImage(named: "9b")
        }
        
        
        let dict = [NSThumbnail1024x1024SizeKey: thumb!] as NSDictionary
        
        do {
            try url.setResourceValue( dict,
                                      forKey:NSURLThumbnailDictionaryKey)
        }
        catch _{
            NSLog("No puc gravar la imatge :)")
        }
        
        
        
    }
    
    
    internal func imageWithWidth(wid:Double,  height:Double) -> UIImage? {
        return imageWithWidth(wid,  height:height, color:UIColor.redColor(), backColor:UIColor.whiteColor(), lineWidth: 5.0)
    }
    
    internal func imageWithWidth(wid:Double,  height:Double, color:UIColor, backColor:UIColor, lineWidth: Double) -> UIImage? {
        
        if !hasGPSData(){
            return nil
        }
        TMKImage.beginImageContextWithSize(CGSizeMake(CGFloat(wid) , CGFloat(height)))
        
        var rect = CGRectMake(0, 0, CGFloat(wid), CGFloat(height))   // Total rectangle
        
        var bz = UIBezierPath(rect: rect)
        
        backColor.set()
        bz.fill()
        bz.stroke()
        
        rect = CGRectInset(rect, 3.0, 3.0);
        
        bz = UIBezierPath(rect:rect)
        bz.lineWidth = 2.0
        bz.stroke()
        
        let (loc0, loc1) = self.computeTrackSize()
        
        if let locmin = loc0, locmax = loc1 {
            
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
            
            let n = countLogForVariable(.Latitude)
            
            
            for i in 0..<n {
                
                
                
                let lat = getValueForVariable(.Latitude, atPoint: i)
                let lon = getValueForVariable(.Longitude, atPoint: i)
                
                let p = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude:lat, longitude: lon ))
                
                let x : CGFloat = CGFloat((p.x-minx) * scale + offset.x)
                let y : CGFloat = CGFloat((p.y-miny) * scale + offset.y)
                if primer
                {
                    bz.moveToPoint(CGPointMake(x,y))
                    primer = false
                }
                else{
                    bz.addLineToPoint(CGPointMake(x,y))
                }
                
            }
            
            bz.lineWidth = CGFloat(lineWidth)
            bz.lineJoinStyle = CGLineJoin.Round
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
    
}

