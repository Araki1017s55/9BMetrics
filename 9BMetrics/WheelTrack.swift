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
        case DistanceGPS
        
        case limitSpeedEnabled
        case lockEnabled
        
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
        var timestamp : TimeInterval
        var value : Double
    }
    
    struct WheelVariable {
        var codi : WheelValue      // Meaning
        var timeStamp : TimeInterval     // Last Update since firstDate
        var currentValue : Double         // Value
        var minValue : Double      // Minimum value
        var maxValue : Double      // Maximum Value
        var avgValue : Double      // Avg Value = integralValue/timeStamp
        var intValue : Double      // Integral (value * dt)
        var loaded : Bool = false  // Log loaded from file
        var log : [LogEntry] // Log Array
    }
    
    fileprivate var units : [WheelValue : Unit] = [
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
        .DistanceGPS : .Meters,
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
    
    
    var url : URL?
    fileprivate var name : String?
    fileprivate var serialNo : String?
    fileprivate var version : String?
    fileprivate var adapter : String?
    fileprivate var uuid : String?
    
    fileprivate var trackImg : UIImage?
    
    
    fileprivate var data = [WheelValue : WheelVariable]()
    
    var firstDate : Date?
    
    fileprivate var distOffset = 0.0  // Just to support stop start without affecting total distance. We supose we start at same place we stopped
    
    fileprivate var distCorrection = 1.0  // Just to support stop start without affecting total distance. We supose we start at same place we stopped
    fileprivate var ascent : Double?
    fileprivate var descent : Double?
    fileprivate var energyUsed : Double?
    fileprivate var energyRecovered : Double?
    fileprivate var batCapacity : Double = 340.0 * 3600.0
    
    //MARK: Conversion variables
    
    static var conversion = Array<WheelTrack.WheelValue?>(repeating: nil, count: 256)
    static var scales = Array<Double>(repeating: 1.0, count: 256)
    
    
    //MARK: .gpx export variables
    
    fileprivate let xmlHeader : String = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<gpx xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.cluetrust.com/XML/GPXDATA/1/0 http://www.cluetrust.com/Schemas/gpxdata10.xsd http://www.gorina.es/XML/TRACESDATA/1/0/tracesdata.xsd\" xmlns:gpxdata=\"http://www.cluetrust.com/XML/GPXDATA/1/0\" xmlns:tracesdata=\"http://www.gorina.es/XML/TRACESDATA/1/0\" version=\"1.1\" creator=\"9BMetrics - http://www.gorina.es/9BMetrics\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n"
    
    fileprivate let xmlFooter = "</trkseg>\n</trk>\n</gpx>\n"
    
    
    fileprivate var trackHeader : String {
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
    
    
    var otherFormatter : DateFormatter = DateFormatter()
    
    override init(){
        super.init()
        
        WheelTrack.initConversion()
        
        otherFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        otherFormatter.timeZone = TimeZone(abbreviation: "UTC")
        otherFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.000Z'"
    }
    
    func clearVariable(_ vr : WheelValue){
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }

        
        if data[vr] != nil{
            data[vr]!.log.removeAll()
        }
    }
    
    func clearAll(){
        
        url = nil
        data.removeAll()
        name = nil
        serialNo = nil
        version = nil
        firstDate = nil
        distOffset = 0.0
        distCorrection = 1.0
        ascent = nil
        descent = nil
        energyUsed = nil
        energyRecovered = nil
        trackImg = nil
    }
    
    func HMSfromSeconds(_ secs : TimeInterval) -> (Int, Int, Int) {
        
        let hours =  floor(secs / 3600.0)
        let minutes = floor((secs - (hours * 3600.0)) / 60.0)
        let seconds = round(secs - (hours * 3600.0) - (minutes * 60.0))
        
        return (Int(hours), Int(minutes), Int(seconds))
        
    }
    
    
    fileprivate func postVariableChanged(_ variable : WheelVariable){
        
        let info : [AnyHashable: Any] = ["variable" : variable.codi.rawValue]
        let not = Notification(name: Notification.Name(rawValue: kWheelVariableChangedNotification), object: self, userInfo: info)
        
        NotificationCenter.default.post(not)
    }
    
    func computeDistanceCorrection(){
        let dGPS = getCurrentValueForVariable(.DistanceGPS)
        let dWheel = getCurrentValueForVariable(.Distance)
        
        if dWheel != 0.0 && dGPS != 0.0 {
            distCorrection = dGPS / dWheel
        } else {
            distCorrection = 1.0
        }
    }
    
    
    
    //MARK: Adding data
    
    
    // addValueWithDate is the main addValue function for numeric values
    //
    // All other functions call this one. If there is a change in some value
    // sends a Notification so everybody may update its user interface
    // forced forgets optimization if many values
    // silent doesn't posts notification if values change (for loading files, etc.)
    //
    // As of version 2.3 we change the concept od duration being not what is reported from the wheel but time since beginning of recording
    //
    // Also when distance falls down to 0 (in case we stop the wheel) distnace NOT goes to 0 but continues to add
    //
    // That is diferent from older versions in which the wheel values where respected
    //
    
    func addValueWithDate(_ dat: Date, variable : WheelValue, value : Double, forced : Bool, silent: Bool){
        
        // First value of all sets firstDate!!!
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if firstDate == nil {
            firstDate = dat
        }
        
        
        let t = dat.timeIntervalSince(firstDate!)
        
        var myVal = 0.0
        
        
        switch(variable){
            
        case .Duration:     // Set duration from the start of recording to be coherent with all the data
            myVal = t
            
        case .Distance:     // When stopped / started recover last distance. Distance shoud always increase
            let last = getCurrentValueForVariable(.Distance)
            
            if (value + distOffset) < last {
                distOffset = last
            }
            
            myVal = distOffset + value
            
        default:
            myVal = value
        }
        
        if data[variable] == nil {
            
            let varData = WheelVariable(codi: variable, timeStamp: t, currentValue: myVal, minValue: myVal, maxValue: myVal, avgValue: myVal, intValue: 0.0, loaded: true , log: [])
            data[variable] = varData
        }
        
        
        let v = LogEntry(timestamp: dat.timeIntervalSince(firstDate!), value: myVal)
        
        let postChange = data[variable]!.currentValue != myVal && !silent
        
        if data[variable]!.currentValue != myVal || data[variable]!.log.count <= 1 || forced {
            data[variable]!.log.append(v)
            
        }else {
            
            let c = data[variable]!.log.count
            let e = data[variable]!.log[c-2]
            
            if e.value != myVal{
                data[variable]!.log.append(v)
            }else {
                data[variable]!.log[c-1] = v
            }
            
        }
        
        // OK, now update all acums. That is interesting
        
        data[variable]!.minValue = min( data[variable]!.minValue, myVal)
        data[variable]!.maxValue = max( data[variable]!.maxValue, myVal)
        data[variable]!.intValue =  data[variable]!.intValue + ((myVal + data[variable]!.currentValue) * (t -  data[variable]!.timeStamp) / 2.0)
        data[variable]!.avgValue =  data[variable]!.intValue / t
        data[variable]!.currentValue = myVal
        data[variable]!.timeStamp = t
        data[variable]!.loaded = true
        
        
        
        if postChange{
            postVariableChanged( data[variable]!)
        }
    }
    
    
    // Auxiliary addValue functions
    
    func addValue(_ variable:WheelValue, value:Double){
        addValueWithDate(Date(), variable : variable, value : value, forced : false, silent: false)
    }
    
    func addValueWithDate(_ dat: Date, variable : WheelValue, value : Double){
        addValueWithDate(dat, variable : variable, value : value, forced : false, silent: false)
    }
    
    
    func addValueWithTimeInterval(_ time: TimeInterval, variable : WheelValue, value : Double){
        
        addValueWithTimeInterval(time, variable : variable, value : value, forced : false, silent: false)
    }
    
    func addValueWithTimeInterval(_ time: TimeInterval, variable : WheelValue, value : Double, forced : Bool, silent: Bool){
        
        if firstDate == nil {
            firstDate = Date().addingTimeInterval(-time)
        }
        
        let date = firstDate!.addingTimeInterval(time)
        
        self.addValueWithDate(date, variable: variable, value: value, forced: forced, silent: silent)
    }
    
    func addLogValue(_ time: TimeInterval, variable : WheelValue, value : Double){
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if data[variable] == nil {
            return
        }
        
        data[variable]!.log.append(LogEntry(timestamp: time, value: value))
        
    }
    
    // Setting general information
    
    func setName(_ name : String){
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        self.name = name
    }
    func setSerialNo(_ serialNo : String){
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        self.serialNo = serialNo
    }
    func setVersion(_ version : String){
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        self.version = version
    }
    func setAdapter(_ adapter : String){
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        self.adapter = adapter
    }
    func setUUID(_ device : String){
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        self.uuid = device
    }
    
    
    // MARK: Query Functions
    
    
    func hasDataInVariable(_ v : WheelValue) -> Bool{
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        guard let vv = data[v] , vv.log.count > 0 else {return false}
        return true
    }
    
    func hasData()->Bool{       // Returns true if we have logged at least current data
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        return hasDataInVariable(.Current)
    }
    
    func hasGPSData() -> Bool{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        let n1 = countLogForVariable(.Latitude)
        let n2 = countLogForVariable(.Longitude)
        
        return n1 > 0 && n2 > 0
    }
    
    
    func lastLocation() -> CLLocation?{
        if hasGPSData(){
            let n = min(countLogForVariable(.Latitude), countLogForVariable(.Longitude))
            
            return CLLocation(latitude: valueAtPointForVariable(.Latitude, atPoint: n)!, longitude: valueAtPointForVariable(.Longitude, atPoint: n)!)
    
        }else {
            return nil
        }
        
    }
    func countLogForVariable(_ v : WheelValue) -> Int{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        
        if let vv = data[v] {
            if !vv.loaded{
                loadVariableFromPackage(v)
            }
            
            return data[v]!.log.count
        }else {
            return 0
        }
    }
    
    func currentValueForVariable(_ v : WheelValue) -> Double?{
        
        if let vv = data[v] {
            return vv.currentValue
        }else {
            return nil
        }
    }
    
    func entryAtPointForVariable(_ v : WheelValue, atPoint point : Int) -> LogEntry?{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
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
    
    func valueAtPointForVariable(_ v : WheelValue, atPoint point : Int) -> Double?{
        if let e = entryAtPointForVariable(v, atPoint : point){
            return e.value
        }else {
            return nil
        }
    }
    
    func timeAtPointForVariable(_ v : WheelValue, atPoint point : Int) -> TimeInterval?{
        if let e = entryAtPointForVariable(v, atPoint : point){
            return e.timestamp
        }else {
            return nil
        }
    }
    
    func dateAtPointForVariable(_ v : WheelValue, atPoint point : Int) -> Date?{
        if let e = entryAtPointForVariable(v, atPoint : point), let date = firstDate{
            return date.addingTimeInterval(e.timestamp)
        }else {
            return nil
        }
    }
    
    
    
    func value(_ variable : WheelValue,  forTime t:TimeInterval) -> LogEntry?{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if let vv = data[variable] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
        }
        
        guard let v = data[variable] , v.log.count > 0 else {return nil}
        
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
    
    func getFirstLast(_ variable: WheelValue) -> (Double, Double){
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
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
    
    func getCurrentStats(_ variable : WheelValue) -> (Double, Double, Double, Double){
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if let vv = data[variable] {
            return (vv.minValue, vv.maxValue, vv.avgValue, vv.intValue)
        } else {
            return (0.0, 0.0, 0.0, 0.0)
        }
    }
    
    func stats(_ variable : WheelValue,  from t:TimeInterval, to t1: TimeInterval) -> (Double, Double, Double, Double){
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if let vv = data[variable] {
            if !vv.loaded {
                loadVariableFromPackage(vv.codi)
            }
        }
        
        guard let v = data[variable] , v.log.count > 0 else {return (0.0, 0.0, 0.0, 0.0)}
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
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        
        if hasDataInVariable(.Power){ // Don't touch data if posible
            return
        }
        
        guard let current = data[.Current] , current.log.count > 0 else {return} // Nothing to do :(
        
        for e in current.log{
            
            if let v = value(.Voltage, forTime: e.timestamp){
                
                addValueWithTimeInterval(e.timestamp, variable: .Power, value: e.value * v.value, forced: false, silent: true)
            }
            
        }
        
    }
    func buildEnergy(){
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if hasDataInVariable(.Energy){      // Don't touch
            return
        }
        buildPower()
        
        guard let current = self.data[.Current] , current.log.count > 0 else {return}   // No Way
        guard let power = data[.Power] , power.log.count > 0 else {return}
        
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
    
    func getLastTimeValueForVariable(_ variable: WheelValue) -> TimeInterval{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if let v = data[variable]{
            return v.timeStamp
        }else{
            return 0.0
        }
    }
    
    func getTimeIntervalForVariable(_ variable: WheelValue, toDate: Date) -> TimeInterval{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        if let v = data[variable]{
            
            if let fd = firstDate{
                return toDate.timeIntervalSince(fd) - v.timeStamp
            }else{
                return 0.0
            }
        } else {
            return 0.0
        }
    }
    
    func getCurrentValueForVariable(_ variable: WheelValue) -> Double{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        
        switch variable{
            // case .Power:
        //     buildPower()
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
    
    func getValueForVariable(_ variable:WheelValue, atPoint: Int) -> Double{
        
        switch variable{
            //case .Power:
        // buildPower()
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
    
    func getValueForVariable(_ variable:WheelValue, time: TimeInterval) -> Double {
        
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
    
    func getName() -> String{
        if let v = self.name{
            return v
        }else{
            return ""
        }
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
    
    func getAdapter() -> String{
        if let v = self.adapter{
            return v
        }else{
            return ""
        }
    }
    func getUUID() -> String{
        if let v = self.uuid{
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
        
        return batCapacity * (b0 - b1) / 100.0
        
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
            
            trackImg = imageWithWidth(350.0,  height:350.0, color:UIColor.yellow, backColor:UIColor.clear, lineWidth: 2.0)
            
            return trackImg
            
        }
    }
    func energyDetails(from t0: TimeInterval, to t1: TimeInterval) -> (Double, Double){
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
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
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
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
    
    func resample(_ variable:WheelValue, from:TimeInterval, to:TimeInterval, step:Double) -> [LogEntry]?{
        
        objc_sync_enter(self);
        defer { objc_sync_exit(self) }
        
        
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
        
        var t0 : TimeInterval = 0
        var t1 : TimeInterval = step
        
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
    
    func getGPXURL() -> URL?{
        
        if let myUrl = self.url {
            let gpxURL = myUrl.appendingPathComponent("track.gpx")
            
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
    
    func createCSVFileFrom(_ from : TimeInterval, to: TimeInterval) -> URL?{
        // Format first date into a filepath
        
        let newName : String
        let ldateFormatter = DateFormatter()
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'Sel_'yyyyMMdd'_'HHmmss'.csv'"
        if let date = firstDate{
            newName = ldateFormatter.string(from: date)
        }else{
            newName = ldateFormatter.string(from: Date())
        }
        
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
                        if let vn = s.data(using: String.Encoding.utf8){
                            hdl.write(vn)
                        }
                    }
                }
            }
            
            
            hdl.closeFile()
            
            return file
            
        }
        catch{
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"Error when trying to get handle for %@".localized(), file.absoluteString)
            }
            
            AppDelegate.debugLog("Error al obtenir File Handle")
        }
        
        return nil
        
    }
    
    // Version 4 uses variable names standardized for all wheels and uses SI units
    
    func createSummaryFile() -> String?{
        
        guard let date = firstDate else {return nil}    // Timestamps have no sens without firstDate
        
        var str = String(format: "Date,%f,Adapter,%@,Name,%@,SN,%@,Version,%@,UUID,%@\n",
                         date.timeIntervalSince1970, getAdapter(), getName(), getSerialNo(), getVersion(),getUUID())
        str.append(String(format: "Energy_Used,%f\n", getEnergyUsed()))
        str.append(String(format: "Energy_Recovered,%f\n", getEnergyRecovered()))
        str.append(String(format: "Ascent,%f\n", getAscent()))
        str.append(String(format: "Descent,%f\n", getDescent()))
        
        for (_, v) in data{
            // Linies tenen el nom de la variable + currentValue, min, max, avg, int values
            
            str.append(String(format: "%@,%.3f,%.2f,%.2f,%.2f,%.2f,%.2f\n", v.codi.rawValue, v.timeStamp,  v.currentValue, v.minValue, v.maxValue, v.avgValue, v.intValue))
        }
        
        return str
        
    }
    
    static func loadSummaryDistance(_ str : String) -> (Double, Double, String, Date, String) {
        
        let lines = str.components(separatedBy: CharacterSet.newlines)
        var name = ""
        var adapter = ""
        var date : Date = Date(timeIntervalSince1970: 0.0)
        
        for line in lines {
            let fields = line.components(separatedBy: ",")
            let codeStr = fields[0]
            
            switch codeStr {
                
            case "Date":
                
                if let ti = Double(fields[1].replacingOccurrences(of: " ", with: "")) {
                     date = Date(timeIntervalSince1970: ti)
                }
                
                if fields.count >= 6{
                    name = fields[5]
                }
                
                
                if fields.count >= 4{
                    adapter = fields[3]
                }

                
            case "Distance":
                guard let dt = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {return (0.0, 0.0 , name, date, adapter) }
                guard let df  = Double(fields[2].replacingOccurrences(of: " ", with: ""))  else {return (0.0, 0.0 , name, date, adapter) }
                guard let d0  = Double(fields[3].replacingOccurrences(of: " ", with: ""))  else {return (0.0, 0.0 , name, date, adapter) }
                let distance = df - d0
                return (dt, distance, name, date, adapter)
                
            default:
                break
                
             }
        }
        return (0.0, 0.0, name, date, adapter)
    }

    
    func loadSummary(_ str : String) {
        
        let lines = str.components(separatedBy: CharacterSet.newlines)
        for line in lines {
            let fields = line.components(separatedBy: ",")
            let codeStr = fields[0]
            
            switch codeStr {
                
            case "Date":
                guard let dt = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {continue }
                firstDate = Date(timeIntervalSince1970: dt)
                
                if fields.count >= 4{
                    self.setAdapter(fields[3])
                }
                
                if fields.count >= 6{
                    self.setName(fields[5])
                }
                
                if fields.count >= 8{
                    self.setSerialNo(fields[7])
                }
                
                if fields.count >= 10{
                    self.setVersion(fields[9])
                }
                if fields.count >= 12{
                    self.setUUID(fields[11])
                }
                
            case "Energy_Used":
                guard let val = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {continue }
                energyUsed = val
                
            case "Energy_Recovered":
                guard let val = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {continue }
                energyRecovered = val
                
            case "Ascent":
                guard let val = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {continue }
                ascent = val
                
            case "Descent":
                guard let val = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {continue }
                descent = val
                
            default:
                
                if let codi = WheelValue(rawValue: codeStr){
                    
                    guard let dt = Double(fields[1].replacingOccurrences(of: " ", with: "")) else {continue }
                    guard let curv = Double(fields[2].replacingOccurrences(of: " ", with: "")) else {continue }
                    guard let minv = Double(fields[3].replacingOccurrences(of: " ", with: "")) else {continue }
                    guard let maxv = Double(fields[4].replacingOccurrences(of: " ", with: "")) else {continue }
                    guard let avgv = Double(fields[5].replacingOccurrences(of: " ", with: "")) else {continue }
                    guard let intv = Double(fields[6].replacingOccurrences(of: " ", with: "")) else {continue }
                    
                     
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
    
    
    
    
    func variableLogtoString(_ variable : WheelValue) -> String?{
        
        guard let v = data[variable] , v.log.count > 0 else {return nil}
        
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
    
    func addValuesFromString(_ s : String, clear : Bool) {
        
        
        let lines = s.components(separatedBy: CharacterSet.newlines)
        
        var lineNumber = 0
        var version = 1
        var date0 : Date?
        var variable : WheelValue?
        
        
        for line in lines {
            let fields = line.components(separatedBy: ",")
            
            if lineNumber == 0 {
                
                if fields[0] == "Version"{
                    if let v = Int(fields[1]){
                        
                        if v == 4{
                            version = v
                            
                            // field 3 has first date
                            
                            guard let dt = Double(fields[3].replacingOccurrences(of: " ", with: "")) else {return }
                            date0 = Date(timeIntervalSince1970: dt)
                            let varstr = fields[5].replacingOccurrences(of: " ", with: "")
                            variable = WheelValue(rawValue: varstr)
                            if let vari = variable , clear {
                                clearVariable(vari)
                            }

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
    
    func packageURL(_ name: String) -> URL?{
        
        guard let docDir = (UIApplication.shared.delegate as! AppDelegate).applicationDocumentsDirectory() else {return nil}
        
        let ext = "9bm"
        let fm = FileManager.default
        
        let pkgURL = docDir.appendingPathComponent(name).appendingPathExtension(ext)
        
        var isDirectory: ObjCBool = ObjCBool(false)
        
        fm.fileExists(atPath: pkgURL.path, isDirectory: &isDirectory)
        
        if isDirectory.boolValue {
            
            
            let summaryURL = pkgURL.appendingPathComponent("summary.csv")
            
            if fm.fileExists(atPath: summaryURL.path){
                return pkgURL
            }
        }
        
        return nil
    }
    
    func appendToPackage(_ name: String){
        
        
        //guard let url = packageURL(name) else { _ = createPackage(name) ; return}
        
        
        
        
        
    }
    
    
    
    
    func createPackage(_ name : String) -> URL?{
        
        guard let docDir = (UIApplication.shared.delegate as! AppDelegate).applicationDocumentsDirectory() else {return nil}
        
        if let url = createPackage(name, inDirectory: docDir, snapshot: false){
        
        
            let wts = WheelTrackSummary()
        
            wts.adapter = getAdapter()
            wts.name = getName()
            wts.date    = firstDate!
            wts.distance = self.getCurrentValueForVariable(.Distance)
            wts.duration = self.getCurrentValueForVariable(.Duration)
            wts.pathname = url.lastPathComponent
        
            WheelTrackDatabase.sharedInstance.addObject(wts)
        
            return url
        }
        return nil
        
    }
    
    
    func createPackage(_ name : String, inDirectory: URL, snapshot : Bool) -> URL?{
        
        let ext : String
        
        if snapshot {
            ext = "snap"
        } else {
            ext = "9bm"
        }
        
        let pkgURL = inDirectory.appendingPathComponent(name).appendingPathExtension(ext)
        
        // Try to use file wrappers (ufff)
        
        let contents = FileWrapper(directoryWithFileWrappers: [:])
        
        if !snapshot {
            for(_, v) in self.data {
                AppDelegate.debugLog("Data %@, %.2f", v.codi.rawValue, v.currentValue)
                
            }
            
            if let s = createSummaryFile(){
                let filename = "summary.csv"
                if let dat = s.data(using: String.Encoding.utf8){
                    let fWrapper = FileWrapper(regularFileWithContents: dat)
                    fWrapper.preferredFilename = filename
                    contents.addFileWrapper(fWrapper)
                }
            }
            
            trackImg = imageWithWidth(350.0,  height:350.0, color:UIColor.yellow, backColor:UIColor.clear, lineWidth: 2.0)
            
            if let img = trackImg{
                if let imgData = UIImagePNGRepresentation(img){
                    let filename = "image.png"
                    let fWrapper = FileWrapper(regularFileWithContents: imgData)
                    fWrapper.preferredFilename = filename
                    contents.addFileWrapper(fWrapper)
                }
                
            }
            
            if hasGPSData() {
                
                if let gpxData = self.createGPXString().data(using: String.Encoding.utf8) {
                    let filename = "track.gpx"
                    let fWrapper = FileWrapper(regularFileWithContents: gpxData)
                    fWrapper.preferredFilename = filename
                    contents.addFileWrapper(fWrapper)
                }
            }
            
        }
        
        
        for (_, v) in self.data {
            if v.log.count > 0{
                
                let vn = v.codi.rawValue
                let fileName = String(format: "%@.csv", vn)
                let binName = String(format: "%@.bin", vn)
                
                // Save a binary copy of array
                
                var l = v.log
                let nbytes = MemoryLayout<LogEntry>.size * l.count
                let dat = Data(bytes: &l, count: nbytes)
                
                let binWrapper = FileWrapper(regularFileWithContents: dat)
                binWrapper.preferredFilename = binName
                contents.addFileWrapper(binWrapper)
                
                
                if let s = variableLogtoString(v.codi) , !snapshot{
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
            
            AppDelegate.alert("Error when saving data", format: "Error %@ when writing data", err.description)
            AppDelegate.debugLog("Error al gravar arxius %@", err.description)
            return nil
        }
        
        if !snapshot {
            setThumbImage(pkgURL)
        }
        
        return pkgURL
    }
    
    func loadVariableFromPackage(_ variable: WheelValue){
        
        if let vari = data[variable], vari.loaded{
            return
        }
        
        if let pkgURL = self.url{
            
            let fileURL = pkgURL.appendingPathComponent(variable.rawValue).appendingPathExtension("csv")
            let binURL = pkgURL.appendingPathComponent(variable.rawValue).appendingPathExtension("bin")
            
            
            // Try to load the binary values
            
            do {
                let logData = try Data(contentsOf: binURL)
                
                let n = logData.count / MemoryLayout<LogEntry>.size
                
                var newLog : [LogEntry] = Array<LogEntry>(repeating: LogEntry(timestamp: 0.0, value: 0.0), count: n)
                
                (logData as NSData).getBytes(&newLog, length: logData.count)
                
                if self.data[variable] != nil {
                    self.data[variable]!.log = newLog
                    self.data[variable]!.loaded = true
                    
                    return
                    
                }
                
                
            }catch {
                
                do {
                    let str = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
                    
                    addValuesFromString(str,clear: true)
                    
                    if self.data[variable] != nil{
                        self.data[variable]!.loaded = true
                    }
                    
                }catch{
                    
                }
            }
        }
    }
    
    func locationForPoint(_ p : Int) -> CLLocation {
        return CLLocation(latitude: getValueForVariable(.Latitude, atPoint: p), longitude: getValueForVariable(.Longitude, atPoint: p))
    }
    
    func location2DForPoint(_ p : Int) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: getValueForVariable(.Latitude, atPoint: p), longitude: getValueForVariable(.Longitude, atPoint: p))
    }
    
    func angle(p0 : MKMapPoint, p1 : MKMapPoint, p2 : MKMapPoint) -> Double{
        
        let dx0 = p1.x - p0.x
        let dy0 = p1.y - p0.y
        let dx1 = p2.x - p1.x
        let dy1 = p2.y - p1.y
        
        let cos = (dx0 * dx1 + dy0 * dy1) / (sqrt(dx0*dx0+dy0*dy0)*sqrt(dx1*dx1+dy1*dy1))
        return acos(cos)
        
        
    }
    
    func getStraightEnoughSegments() -> [(from : Int, to : Int, length: Double)] {
        
        if !hasGPSData() {
            return []
        }
        
        var segments : [(from : Int, to : Int, length : Double)] = []
        
        let n = min(countLogForVariable(.Latitude) , countLogForVariable(.Longitude))
        
        var segmentStart = 0
        var segmentEnd = 1
        var segmentLength = locationForPoint(1).distance(from: locationForPoint(0))
        
        var c0 = locationForPoint(0)
        var c1 = locationForPoint(1)
        var p0 = MKMapPointForCoordinate(c0.coordinate)
        var p1 = MKMapPointForCoordinate(c1.coordinate)
        
        
        
        for i in 1..<n-1 {  // Loop throug points.
            
            let c2 = locationForPoint(i+1)
            let p2 = MKMapPointForCoordinate(c2.coordinate)
            
            let ang = angle(p0: p0, p1: p1, p2: p2)
            
            if fabs(ang) > 0.20 {   // That should be aprox 20º - Stop segment
                if segmentEnd > segmentStart && segmentLength > 100.0{  // Segments at leat 100m
                    segments.append((from:segmentStart, to:segmentEnd, length: segmentLength))
                }
                segmentStart = i
                segmentEnd = i+1
                segmentLength = c2.distance(from: c1)
            } else {
                
                segmentEnd = i+1
                segmentLength += c2.distance(from: c1)
                
            }
            
            c0 = c1
            c1 = c2
            p0 = p1
            p1 = p2
        }
        return segments
    }
    
    static func loadSummaryDistanceFromURL(_ url : URL) -> (Double, Double, String, Date, String){

        do{
            let pack = try FileWrapper(url: url, options: [])
            
            if pack.isDirectory{
                
                if let fw = pack.fileWrappers!["summary.csv"]{
                    if let str = String(data: fw.regularFileContents!, encoding: String.Encoding.utf8){
                        return WheelTrack.loadSummaryDistance(str)
                    }
                }
                
            }
        }catch{
    
        }

        return (0.0, 0.0, "", Date(timeIntervalSince1970: 0.0), "")
    }

    func loadPackage(_ url : URL) {
        
        clearAll()
        
        do{
            let pack = try FileWrapper(url: url, options: [])
            
            if pack.isDirectory{
                
                self.url = url
                
                var binaryEnabled = false
                
                for (name, fw) in pack.fileWrappers!{
                    if fw.isRegularFile && name == "summary.csv"{
                        
                        if let str = String(data: fw.regularFileContents!, encoding: String.Encoding.utf8){
                            loadSummary(str)
                            
                            // OK now load gpx data
                           
                            let distanceGPX = getCurrentValueForVariable(.DistanceGPS)  // Abans ho calculaba
                            let wheelDistance = getCurrentValueForVariable(.Distance)
                            let (_, _, _, anotherDistance) = getCurrentStats(.Speed)
                            
                            AppDelegate.debugLog("GPS Distance %f Wheel Distance %f Another Distance %f", distanceGPX, wheelDistance, anotherDistance)
                            
                            if distanceGPX > 0.0 {
                                AppDelegate.debugLog("Correction %f", wheelDistance / distanceGPX)
                                AppDelegate.debugLog("Speed Correction %f", anotherDistance / distanceGPX)
                            }
                        }
                        
                    } else if fw.isRegularFile && name == "image.png" {
                        
                        self.trackImg = UIImage(data: fw.regularFileContents!)
                        
                    }else if fw.isRegularFile && name == "map.gpx"{
                        
                        
                        
                    }else if fw.isRegularFile {
                        
                        if let fnam = fw.filename , fnam.hasSuffix(".bin"){
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
                    
                    
                    if let v = self.data[.Latitude]{
                        AppDelegate.debugLog("Latitut %d", v.log.count)
                    }

                    if let v = self.data[.Longitude]{
                        AppDelegate.debugLog("Longitut %d", v.log.count)
                    }

                    
                    // OK now update the package
                    
                    let name = url.deletingPathExtension().lastPathComponent
                    let fm = FileManager.default
                    let newUrl = url.deletingPathExtension().appendingPathExtension("bu")
                    do{
                        
                        try fm.moveItem(at: url, to: newUrl)
                        let okurl = createPackage(name)
                        if okurl != nil {
                            try fm.removeItem(at: newUrl)
                        } else {
                            do {
                                try fm.removeItem(at: url)
                            }catch{
                                
                            }
                            try fm.moveItem(at: newUrl, to: url)
                        }
                    }catch{
                        
                    }
                    
                    
                }
            }
        }catch{
            
        }
        /*
         let segments = getStraightEnoughSegments()
         
         var lenWheel = 0.0
         var lenGPS = 0.0
         
         for s in segments {
         
         let l = s.length    // That is GPS Length
         
         let t0 = timeAtPointForVariable(.Latitude, atPoint: s.from)
         let t1 = timeAtPointForVariable(.Latitude, atPoint: s.to)
         
         let d = getValueForVariable(.Distance, time: t1!) - getValueForVariable(.Distance, time: t0!)
         
         lenWheel += d
         lenGPS += l
         
         AppDelegate.debugLog("GPS %f - Wheel %f - Correccio : %f", l, d, d  / l)
         
         
         
         }
         
         AppDelegate.debugLog("TOTAL GPS %f - Wheel %f - Correccio : %f", lenGPS, lenWheel, lenWheel / lenGPS)
         */
        
        checkBattery()
    }
    
    
    
    static func createZipFile(_ pkgUrl : URL) -> URL?{
        
        
        let name = pkgUrl.deletingPathExtension().lastPathComponent
        
        
        let tmpDirURL = URL(fileURLWithPath: NSTemporaryDirectory(),isDirectory: true)
        let zipURL = tmpDirURL.appendingPathComponent(name).appendingPathExtension("9bz")
        
        do {
            var files : [URL] = [URL]()
            
            
            let pack = try FileWrapper(url: pkgUrl, options: [])
            
            if pack.isDirectory{
                for (_, fw) in pack.fileWrappers!{
                    if let fname = fw.filename{
                        
                        if !fname.hasSuffix(".bin"){    // bin files are just for caching
                            files.append(pkgUrl.appendingPathComponent(fname))
                        }
                    }
                }
            }
            
            try Zip.zipFiles(files, zipFilePath: zipURL, password: nil, progress: { (progress) -> () in
                AppDelegate.debugLog("Zip %f", progress)
            })
            
            return zipURL
        }catch{
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"Error when trying to create zip file %@".localized(), zipURL as CVarArg)
            }
            AppDelegate.debugLog("Error al crear zip file")
            
            return nil
        }
    }
    
    
    internal func createGPXString() -> String{
        
        if !hasGPSData(){
            return ""
        }
        
        var buff = ""
        buff.append(xmlHeader)
        buff.append(trackHeader.replacingOccurrences(of: "$", with: "9BMetricsTrack"))
        
        let n = min(countLogForVariable(.Latitude), countLogForVariable(.Longitude))
        for i in 0..<n {
            
            guard let date = dateAtPointForVariable(.Latitude, atPoint: i) else {return ""}
            let lat = getValueForVariable(.Latitude, atPoint: i)
            let lon = getValueForVariable(.Longitude, atPoint: i)
            
            var ele : Double = 0.0
            if countLogForVariable(.AltitudeGPS) > i {
                ele = getValueForVariable(.AltitudeGPS, atPoint: i)
            }// Altitude in m
            
            
            let timestr =  self.otherFormatter.string(from: date)
            
            let timeString : String = timestr.replacingOccurrences(of: " ",  with: "").replacingOccurrences(of: "\n",with: "").replacingOccurrences(of: "\r",with: "")
            
            
            let s = String(format:"<trkpt lat=\"%7.5f\" lon=\"%7.5f\">\n<ele>%3.0f</ele>\n<time>\(timeString)</time>\n</trkpt>\n", lat, lon, ele)
            
            buff.append(s)
            
        }
        
        buff.append(xmlFooter)
        return buff
        
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
            
            let n = min(countLogForVariable(.Latitude), countLogForVariable(.Longitude))
            for i in 0..<n {
                
                guard let date = dateAtPointForVariable(.Latitude, atPoint: i) else {return false}
                let lat = getValueForVariable(.Latitude, atPoint: i)
                let lon = getValueForVariable(.Longitude, atPoint: i)
                
                var ele : Double = 0.0
                if countLogForVariable(.AltitudeGPS) > i {
                    ele = getValueForVariable(.AltitudeGPS, atPoint: i)
                }// Altitude in m
                
                
                let timestr =  self.otherFormatter.string(from: date)
                
                let timeString : String = timestr.replacingOccurrences(of: " ",  with: "").replacingOccurrences(of: "\n",with: "").replacingOccurrences(of: "\r",with: "")
                
                
                let s = String(format:"<trkpt lat=\"%7.5f\" lon=\"%7.5f\">\n<ele>%3.0f</ele>\n<time>\(timeString)</time>\n</trkpt>\n", lat, lon, ele)
                
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
        
        if let latArray = self.data[.Latitude]?.log, let lonArray = self.data[.Longitude]?.log {
            
            let n = min(latArray.count, lonArray.count)
            
            for i in 0..<n{
                let lcd = CLLocationCoordinate2DMake(Double(latArray[i].value), Double(lonArray[i].value))
                locs.append(lcd)
            }
        }
        
        return locs
    }
    
    
    func getGPXDistance() -> Double{
        
        let arr = self.locationArray()
        
        if arr.count < 2{
            return 0.0
        }
        
        var dist = 0.0
        
        var lastLoc = CLLocation(latitude: arr[0].latitude, longitude: arr[0].longitude)
        
        
        
        for cord in arr {
            let newLoc = CLLocation(latitude: cord.latitude, longitude: cord.longitude)
            dist  += newLoc.distance(from: lastLoc)
            lastLoc = newLoc
            
        }
        
        return dist
    }
    
    //MARK: Legacy
    
    func checkBattery(){
        let batt = getBatteryEnergy()
        let used = getEnergyUsed()
        let recovered = getEnergyRecovered()
        
        let power = used - recovered
        let eficiency = power/batt
        
        AppDelegate.debugLog("Bateria : %f  Power %f Eficiency %f", batt, power, eficiency)
    }
    
    func wheelValueFor9Bvalue(_ nbValue : Int) -> WheelValue?{
        if let wv = WheelTrack.conversion[nbValue] {
            return wv
        }else{
            return nil
        }
        
    }
    
    func loadTextFile(_ url:URL){
        
        self.clearAll()
        self.url = url
        
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
                    
                    guard let dt = Double(fields[0].replacingOccurrences(of: " ", with: "")) else {return}
                    
                    if let d = date0{
                        let t = Date(timeInterval: dt, since: d)
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
        
        let name = url.deletingPathExtension().lastPathComponent
        let newName = name.replacingOccurrences(of: "9B_", with: "")
        if let url = createPackage(newName){
            AppDelegate.debugLog("Package %@ created", url as CVarArg)
        }else{
            AppDelegate.debugLog("Error al crear Package")
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
    
    func setThumbImage(_ url : URL){
        
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
        
        if !hasGPSData(){
            return nil
        }
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
            
            let n = countLogForVariable(.Latitude)
            
            
            for i in 0..<n {
                
                
                
                let lat = getValueForVariable(.Latitude, atPoint: i)
                let lon = getValueForVariable(.Longitude, atPoint: i)
                
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
    
}

