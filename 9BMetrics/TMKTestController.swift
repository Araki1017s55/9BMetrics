//
//  TMKTestController.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 21/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class TMKTestController: UIViewController {

    @IBOutlet weak var fBattery: TMKClockView!
    @IBOutlet weak var fSpeed: TMKClockView!
    @IBOutlet weak var fPower: TMKClockView!
    @IBOutlet weak var fTemp: TMKClockView!
    @IBOutlet weak var fRoll: TMKVerticalView!
    @IBOutlet weak var fPitch: TMKLevelView!
   
    weak var ninebot : BLENinebot?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Max security level in speed = 23. Max speed to show = 30
        // Min security level in battery = 20%.
        
        if let nb = self.ninebot {
            
            let (dist, ascent, descent, time, avgSpeed, maxSpeed) = nb.analCinematics()
            let(bat0, bat1, batMin, batMax, energy, batEnergy, currMax, currAvg, pwMax, pwAvg) = nb.analEnergy()
            let (tmin, tmax, tavg, _) = nb.temperature(from: 0.0, to: 86400.0)
            let (pmin, pmax, pavg, _) = nb.pitch(from: 0.0, to: 86400.0)
            let (rmin, rmax, ravg, _) = nb.roll(from: 0.0, to: 86400.0)
           
            // Compute speed data
            
            let topSpeed = 30.0
            var limits = [TMKClockView.arc(start: 0.0, end: 23.0/30.0, color: UIColor.greenColor())]
                          
            if maxSpeed > 23.0{
                limits.append( TMKClockView.arc(start: 23.0/30.0, end: maxSpeed / 30.0, color: UIColor.redColor()))
                
             }
            
            
            let speeds : [TMKClockView.arc] = [TMKClockView.arc(start: avgSpeed / topSpeed, end: 0.5, color: UIColor.greenColor()), TMKClockView.arc(start: maxSpeed / topSpeed, end: 0.9, color: UIColor.redColor())]
            
            fSpeed.updateData(String(format:"%0.2f", dist) , units: "Km", radis: speeds, arcs: limits, minValue: 0.0, maxValue: 30.0)
         
            // Compute battery data
            
            // areas show min and max excursion of battery
            // levels show start (green) and end (red) levels
            // value is battery use in %
            
            var batAreas : [TMKClockView.arc] = []
            
            if batMin < 20.0 && batMax <= 20.0 {
                batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: batMax/100.0, color: UIColor.redColor()))
            }else if batMin < 20.0 && batMax > 20.0 {
                batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: 20.0/100.0, color: UIColor.redColor()))
                batAreas.append(TMKClockView.arc(start: 20.0 / 100.0, end: batMax/100.0, color: UIColor.greenColor()))
            }else {
                batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: batMax/100.0, color: UIColor.greenColor()))
            }
            
            let batLevels : [TMKClockView.arc] = [TMKClockView.arc(start: bat0 / 100.0, end: 0.5, color: UIColor.greenColor()),
                                                  TMKClockView.arc(start: bat1 / 100.0, end: 0.9, color: UIColor.redColor())]
           
            
            fBattery.updateData(String(format:"%0.0f", (bat0 - bat1)) , units: "%", radis: batLevels, arcs: batAreas, minValue: 0.0, maxValue: 100.0)
            
            
            // Power data :
            // Power has 3 levels : 0-500w green 500-1000w orange 1000-max (minimum 1500) red
            // Power labels are in w/100 so they are from 0-5-10-15...
            // Power value is the total energy used according to power (Integral)
            // Green indicator is average, red is maximum
            // Power minimum is always 0 (well, it should be if you stop sometimes)
            
            let pwCont = 500.0
            let pwPeak = 1000.0
            
            let pwRange = ceil(max(pwMax, 1500.0) / 100.0) * 100.0
            var pwAreas : [TMKClockView.arc] = []
            
            pwAreas.append(TMKClockView.arc(start: 0.0 / pwRange, end:min(pwMax, pwCont) / pwRange, color: UIColor.greenColor()))
            
            if pwMax > pwCont {
                pwAreas.append(TMKClockView.arc(start: pwCont / pwRange, end:min(pwMax, pwPeak) / pwRange, color: UIColor.orangeColor()))
            }
            
            if pwMax > pwPeak {
                pwAreas.append(TMKClockView.arc(start: pwPeak / pwRange, end:pwMax / pwRange, color: UIColor.redColor()))
            }
            
            let pwLevels : [TMKClockView.arc] = [TMKClockView.arc(start: pwAvg / pwRange, end: 0.5, color: UIColor.greenColor()),
                                                  TMKClockView.arc(start: pwMax / pwRange, end: 0.9, color: UIColor.redColor())]
            
            
            fPower.updateData(String(format:"%0.0f", ceil(energy)) , units: "wh", radis: pwLevels, arcs: pwAreas, minValue: 0.0, maxValue: pwRange / 100.0)
            
            // Temperature
            //
            //  let's say ti 60ºC is OK
            // maxT = 90
            // minT = 0

            let tempOk = 60.0
            
            let tempRange = ceil(max(tmax, 90.0) / 10.0) * 10.0
            var tempAreas : [TMKClockView.arc] = []
            
            if tmin < tempOk {
                tempAreas.append(TMKClockView.arc(start: tmin / tempRange, end:min(tmax, tempOk) / tempRange, color: UIColor.greenColor()))
            }
            
            if tmax > tempOk{
                tempAreas.append(TMKClockView.arc(start: max(tmin, tempOk) / tempRange, end:tmax / tempRange, color: UIColor.redColor()))
            }
            
            
            let tempLevels : [TMKClockView.arc] = [TMKClockView.arc(start: tavg / tempRange, end: 0.5, color: UIColor.greenColor()),
                                                 TMKClockView.arc(start: tmax / tempRange, end: 0.9, color: UIColor.redColor())]
            
            
            
            fTemp.updateData(String(format:"%0.0f", tmax) , units: "ºC", radis: tempLevels, arcs: tempAreas, minValue: 0.0, maxValue: tempRange)

            // Pitch
            
            
            fRoll.updateData(ravg, minValue: rmin, maxValue: rmax, scale: 1.0)
            fPitch.updateData(pavg, minValue: pmin, maxValue: pmax, scale: 1.0)
            
        }

        
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goBack(src : AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
    }

    override func viewWillAppear(animated: Bool) {
         self.navigationController?.navigationBar.hidden = true
    }
}
