//
//  BLEGraphicRunningDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 9/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
import UIKit
import CoreBluetooth
import GyrometricsDataModel

class BLEGraphicRunningDashboard: BLEGenericDashboard {
    //
    //  BLERunningDashboard.swift
    //  9BMetrics
    //
    //  Created by Francisco Gorina Vanrell on 29/3/16.
    //  Copyright © 2016 Paco Gorina. All rights reserved.
    //
    
    
    
    @IBOutlet weak var fTime: UILabel!
    @IBOutlet weak var fDistance: UILabel!
    @IBOutlet weak var fCurrent: UILabel!
    @IBOutlet weak var fPower: UILabel!
    @IBOutlet weak var fSpeed: TMKClockViewFast!
    @IBOutlet weak var fBattery: TMKClockView!
    @IBOutlet weak var fTemperature: TMKClockView!
    @IBOutlet weak var fVoltage: UILabel!
    @IBOutlet weak var fSeriaNumber: UILabel!
    
    @IBOutlet weak var fCCurrent : TMKClockView!
    
    
    
    
    
    let sphereColor = UIColor.black
    let labelColor = UIColor.black
    
    var batTop = 1.0
    var batOk = 0.2
    
    let tempTop = 90.0
    let tempOK = 60.0
    
    var speedTop = 30.0
    var speedOK = 23.0
    
    
    var tempAreas : [TMKClockView.arc] = []
    var battAreas : [TMKClockView.arc] = []
    var speedAreas  : [TMKClockView.arc] = []
    
    var timer : Timer?
    
    var deviceName : String = ""
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        battAreas = [TMKClockView.arc(start: 0.0, end: batOk/batTop, color: UIColor.red),
                     TMKClockView.arc(start: batOk/batTop, end: 1.0, color: UIColor.green)]
        
        
        tempAreas = [TMKClockView.arc(start: 0.0, end: tempOK / tempTop, color: UIColor.green),
                     TMKClockView.arc(start: tempOK / tempTop, end: 1.0, color: UIColor.red)]
        
        
        
        speedAreas = [TMKClockView.arc(start: 0.0, end: speedOK/speedTop, color: UIColor.green),
                      TMKClockView.arc(start: speedOK/speedTop, end: 1.0, color: UIColor.red)]
        
        
        self.fSpeed.sphereColor = sphereColor
        self.fSpeed.labelsColor = labelColor
        self.fSpeed.arcs = self.speedAreas
        //self.fSpeed.setup()
        
        self.fTemperature.sphereColor = sphereColor
        self.fTemperature.labelsColor = labelColor
        self.fTemperature.label.textColor = labelColor
        self.fTemperature.unitsLabel.textColor = labelColor
        
        self.fBattery.sphereColor = sphereColor
        self.fBattery.labelsColor = labelColor
        self.fBattery.label.textColor = labelColor
        self.fBattery.unitsLabel.textColor = labelColor
        
        // Do any additional setup after loading the view.
        
        //timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(BLEGraphicRunningDashboard.testSpeed(_:)), userInfo: nil, repeats: true)
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func testSpeed (_ timer : Timer){
        //  Tests
        
        // Get a value
        
        let val = fabs(Double(arc4random()) / Double(UINT32_MAX)) * speedTop;
        
        let _ = [TMKClockView.arc(start:val/speedTop, end: 0.5, color: UIColor.red)] // Speed Levels
        
        
        self.fSpeed.updateData(String(format:"%0.2f", val) , units: "Km/h", value: val, minValue: 0, maxValue: self.speedTop)
        
        
    }
    
    override func updateName(_ name : String){
        self.fSeriaNumber.text = name
        
    }
    
    override func updateUI(_ track: WheelTrack){
        
        //cell.detailTextLabel!.text =
        
        self.fCurrent.text = String(format:"%0.2fA", track.getCurrentValueForVariable(.Current))
        self.fPower.text = String(format:"%0.0fW", track.getCurrentValueForVariable(.Power))
        self.fDistance.text = String(format:"%@", UnitManager.sharedInstance.formatDistance(track.getCurrentValueForVariable(.Distance) * self.distanceCorrection))
        let (h, m, s) = track.HMSfromSeconds(track.getCurrentValueForVariable(.Duration))
        self.fTime.text = String(format:"%02d:%02d:%02d", h, m, s)
        
        let v = UnitManager.sharedInstance.convertSpeed(track.getCurrentValueForVariable(.Speed) * self.speedCorrection) // In Km/h or mi/h
        let b = track.getCurrentValueForVariable(.Battery)
        let t = UnitManager.sharedInstance.convertTemperature(track.getCurrentValueForVariable(.Temperature))
        let volt = track.getCurrentValueForVariable(.Voltage)
        
        let battLevels = [TMKClockView.arc(start: b / 100.0, end: 0.5, color: UIColor.red)]
        let tempLevels = [TMKClockView.arc(start: track.getCurrentValueForVariable(.Temperature) / self.tempTop, end: 0.5, color: UIColor.red)]
        
        
        self.fSpeed.updateData(String(format:"%0.2f", v) , units: UnitManager.sharedInstance.longDistanceUnit + "/h", value: v, minValue: 0, maxValue: self.speedTop)
        
        self.fBattery.updateData(String(format:"%0.1f", volt) , units: "V", radis: battLevels, arcs: self.battAreas, minValue: 0, maxValue: 100.0)
        
        self.fTemperature.updateData(String(format:"%0.1f", t) ,
                                     units: UnitManager.sharedInstance.temperatureUnit,
                                     radis: tempLevels,
                                     arcs: self.tempAreas,
                                     minValue: UnitManager.sharedInstance.convertTemperature(0.0),
                                     maxValue: UnitManager.sharedInstance.convertTemperature(self.tempTop))
        
    }
    
    
    
    
    
    // Just block swipe right for UINavigator
    
    @IBAction func swipeRight(){
        
        NSLog("Hello right swipe")
        
    }
    
    // Push map dasboard
    
    @IBAction func swipeLeft(){
        
        NSLog("Hello left swipe")
        
        
    }
}
