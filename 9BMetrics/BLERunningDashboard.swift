//
//  BLERunningDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 29/3/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLERunningDashboard: BLEGenericDashboard {
    
    @IBOutlet weak var fTime: UILabel!
    @IBOutlet weak var fDistance: UILabel!
    @IBOutlet weak var fCurrent: UILabel!
    @IBOutlet weak var fPower: UILabel!
    @IBOutlet weak var fSpeed: UILabel!
    @IBOutlet weak var fSpeedUnits: UILabel!
    @IBOutlet weak var fBattery: UILabel!
    @IBOutlet weak var fTemperature: UILabel!
    @IBOutlet weak var fVoltage: UILabel!
    @IBOutlet weak var fSeriaNumber: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        fSpeedUnits.text = UnitManager.sharedInstance.longDistanceUnit+"/h"
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func updateName(_ name : String){
        self.fSeriaNumber.text = name
        
    }
    
    override func updateUI(_ track: WheelTrack){
        
        //cell.detailTextLabel!.text =
        self.fVoltage.text = String(format:"%0.2fV", track.getCurrentValueForVariable(.Voltage))
        
        self.fCurrent.text = String(format:"%0.2fA", track.getCurrentValueForVariable(.Current))
        self.fPower.text = String(format:"%0.0fW", track.getCurrentValueForVariable(.Power))
        self.fDistance.text = String(format:"%@", UnitManager.sharedInstance.formatDistance(track.getCurrentValueForVariable(.Distance) * self.distanceCorrection)) // In m, yd, or km, mi
        let (h, m, s) = track.HMSfromSeconds(track.getCurrentValueForVariable(.Duration))
        self.fTime.text = String(format:"%02d:%02d:%02d", h, m, s)
        self.fBattery.text = String(format:"%4.0f%%", track.getCurrentValueForVariable(.Battery))
        self.fTemperature.text = UnitManager.sharedInstance.formatTemperature(track.getCurrentValueForVariable(.Temperature))
        
        
        
        
        let v =  track.getCurrentValueForVariable(.Speed) * 3.6  * self.speedCorrection // In Km/h
        let vc = UnitManager.sharedInstance.convertSpeed(track.getCurrentValueForVariable(.Speed) * self.speedCorrection)
        
        self.fSpeed.text = String(format:"%0.2f", vc)
        
        if v >= 15.0 && v < 20.0{
            self.fSpeed.textColor = UIColor.orange
        }else if v > 20.0 {
            self.fSpeed.textColor = UIColor.red
        }else {
            self.fSpeed.textColor = UIColor.black
            
        }
        
    }
    
}
