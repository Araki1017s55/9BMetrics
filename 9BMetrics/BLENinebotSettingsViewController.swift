//
//  BLENinebotSettingsViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 23/2/16.
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


//TODO: We need to decide what to do when maxSpeed goes less than limitSpeed. Logically
// we should reduce limitSpeed automatically. Will think about

import UIKit

class BLENinebotSettingsViewController: UIViewController {
    
    @IBOutlet weak var speedLimitSlider: UISlider!
    @IBOutlet weak var maxSpeedSlider: UISlider!
    @IBOutlet weak var ridingSettingsSlider: UISlider!
    
    @IBOutlet weak var vSpeedLimitSetings: UILabel!
    @IBOutlet weak var vMaxSpeedSettings: UILabel!
    @IBOutlet weak var vRidingSettings: UILabel!
    
    @IBOutlet weak var fSerialNumber: UITextField!
    
    var oldRidingLevel = 0
    var oldSpeedLimit = 0.0
    var oldMaxSpeed = 0.0
    
    weak var ninebotClient : BLESimulatedClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
                
                
                let maxSpeed = dat.getCurrentValueForVariable(.MaxSpeed)
                let limitSpeed = dat.getCurrentValueForVariable(.LimitSpeed)
                let ridingLevel = Int(dat.getCurrentValueForVariable(.RidingLevel))
                
                speedLimitSlider.maximumValue = Float(maxSpeed)
                
                speedLimitSlider.value = Float(limitSpeed)
                vSpeedLimitSetings.text = String(format: "%1.0f km/h",limitSpeed * 3.6)
                
                ridingSettingsSlider.value = Float(ridingLevel)
                vRidingSettings.text = String(format: "%1d", ridingLevel)
                oldRidingLevel = ridingLevel
                oldSpeedLimit = limitSpeed
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func ridingSettingsSliderMoved(_ src : AnyObject){
        
        let v = Int(round(ridingSettingsSlider.value))
        
        if v != oldRidingLevel{
            vRidingSettings.text = String(format: "%d", v)
            oldRidingLevel = v
        }
        
        
        if let nb = self.ninebotClient{
            
            
            if let dat = nb.datos {
                
                let v0 =  Int(dat.getCurrentValueForVariable(.RidingLevel))
                
                if v != v0 {
                    //TODO: Set an interface for different charateristics nb.setRidingLevel(v)
                    if let wheel = ninebotClient {
                        wheel.setRidingLevel(v)
                    }
                    vRidingSettings.textColor = UIColor.red
                }
                
            }
        }
    }
    
    
    @IBAction func speedLimitSliderMoved(_ src : AnyObject){
        
        let v = Double(round(speedLimitSlider.value))
        
        if v != oldSpeedLimit{
            vSpeedLimitSetings.text = String(format: "%1.0f km/h", v*3.6)
            oldSpeedLimit = v
        }
        
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
                let v0 = dat.getCurrentValueForVariable(.LimitSpeed)
                
                if fabs(v - v0) >= 0.5 {
                    
                    nb.setLimitSpeed(v*3.6)
                    
                    vSpeedLimitSetings.textColor = UIColor.red
                }
                
            }
        }
    }
    
    
    @IBAction func setSerialNumber(_ src : AnyObject){
        
        let newSn = fSerialNumber.text
        if let nb = self.ninebotClient{
            
            if let sn = newSn{
                nb.setSerialNumber(sn)
            }
        }
        
    }
    
    func someValueChanged(_ not : Notification){
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
                
                
                if let info  : [AnyHashable: Any] = not.userInfo {
                    
                    if let v = info["variable"] as? String {
                        
                        switch v {
                        case WheelTrack.WheelValue.RidingLevel.rawValue:
                            
                            vRidingSettings.text = String(format: "%d", Int(dat.getCurrentValueForVariable(.RidingLevel)))
                            vRidingSettings.textColor = UIColor.black
                            
                        case WheelTrack.WheelValue.LimitSpeed.rawValue:
                            vSpeedLimitSetings.text = String(format: "%1.0f km/h", dat.getCurrentValueForVariable(.LimitSpeed)*3.6)
                            vSpeedLimitSetings.textColor = UIColor.black
                            
                        default:
                            break
                        }
                    }
                    
                    
                }
            }
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLENinebotSettingsViewController.someValueChanged(_:)), name: NSNotification.Name(rawValue: kWheelVariableChangedNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Necessitem
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
