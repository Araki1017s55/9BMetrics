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
    
    var oldRidingLevel = 0.0
    var oldSpeedLimit = 0.0
    var oldMaxSpeed = 0.0
   
    weak var ninebotClient : BLESimulatedClient?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let nb = self.ninebotClient{
            if let dat = nb.datos {
                
                speedLimitSlider.value = Float(dat.getCurrentValueForVariable(.LimitSpeed))
                speedLimitSlider.maximumValue = Float(dat.getCurrentValueForVariable(.MaxSpeed))
                vSpeedLimitSetings.text = String(format: "%1.0f km/h", Float(dat.getCurrentValueForVariable(.LimitSpeed)*3.6))
                maxSpeedSlider.value = Float(Float(dat.getCurrentValueForVariable(.MaxSpeed)))
                vMaxSpeedSettings.text = String(format: "%1.0f km/h", Float(dat.getCurrentValueForVariable(.MaxSpeed)*3.6))
                
                ridingSettingsSlider.value = Float(dat.getCurrentValueForVariable(.RidingLevel))
                vRidingSettings.text = String(format: "%d", dat.getCurrentValueForVariable(.RidingLevel))
                oldRidingLevel = dat.getCurrentValueForVariable(.RidingLevel)
                oldSpeedLimit = dat.getCurrentValueForVariable(.LimitSpeed)
                oldMaxSpeed = dat.getCurrentValueForVariable(.MaxSpeed)
            }
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func ridingSettingsSliderMoved(src : AnyObject){
        
        let v = Double(round(ridingSettingsSlider.value))
        
        if v != oldRidingLevel{
            vRidingSettings.text = String(format: "%d", v)
            oldRidingLevel = v
        }
    
        
        if let nb = self.ninebotClient{
            
            
            if let dat = nb.datos {
                
                let v0 =  dat.getCurrentValueForVariable(.RidingLevel)
                
                if v != v0 {
                    //TODO: Set an interface for different charateristics nb.setRidingLevel(v)
                    vRidingSettings.textColor = UIColor.redColor()
                }
               
            }
        }
    }
    
    
    @IBAction func speedLimitSliderMoved(src : AnyObject){
        
        let v = Double(round(speedLimitSlider.value))
        
        if v != oldSpeedLimit{
            vSpeedLimitSetings.text = String(format: "%1.0f km/h", v)
            oldSpeedLimit = v
        }
        
        
        if let nb = self.ninebotClient{
             if let dat = nb.datos {
                let v0 = dat.getCurrentValueForVariable(.LimitSpeed)
                
                if fabs(v - v0) >= 1.0 {
                    
                     vSpeedLimitSetings.textColor = UIColor.redColor()
                }
                
            }
        }
    }
    
    @IBAction func maxSpeedSliderMoved(src : AnyObject){
        
        let v = Double(round(maxSpeedSlider.value))
        
        if v != oldMaxSpeed{
            vMaxSpeedSettings.text = String(format: "%1.0f km/h", v)
            oldMaxSpeed = v
            speedLimitSlider.maximumValue = round(maxSpeedSlider.value)
        }
        
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
                let v0 = dat.getCurrentValueForVariable(.MaxSpeed)
                
                if fabs(v - v0) >= 1.0 {
                     //nb.setMaxSpeed(v)
                    vMaxSpeedSettings.textColor = UIColor.redColor()
                }
                
            }
        }
    }

    @IBAction func setSerialNumber(src : AnyObject){
    
        let newSn = fSerialNumber.text
        if let nb = self.ninebotClient{
            
            if let sn = newSn{
                nb.setSerialNumber(sn)
            }
        }

    }
    
    func rideModeChanged(not : NSNotification){
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
                   // ridingSettingsSlider.value = Float(dat.ridingLevel())
                    vRidingSettings.text = String(format: "%d", Int(dat.getCurrentValueForVariable(.RidingLevel)))
                    vRidingSettings.textColor = UIColor.blackColor()
            }
        }
        
    }
 
    func limitSpeedChanged(not : NSNotification){
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
               // speedLimitSlider.value = Float(dat.limitSpeed())
                vSpeedLimitSetings.text = String(format: "%1.0f km/h", dat.getCurrentValueForVariable(.LimitSpeed)*3.6)
                vSpeedLimitSetings.textColor = UIColor.blackColor()
            }
        }
    }
    func maxSpeedChanged(not : NSNotification){
        
        if let nb = self.ninebotClient{
            if let dat = nb.datos {
               // maxSpeedSlider.value = Float(dat.maxSpeed())
                vMaxSpeedSettings.text = String(format: "%1.0f km/h", dat.getCurrentValueForVariable(.MaxSpeed)*3.6)
                speedLimitSlider.maximumValue = Float(dat.getCurrentValueForVariable(.MaxSpeed)*3.6)
                vMaxSpeedSettings.textColor = UIColor.blackColor()
                
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        
        let notRidingName = BLENinebot.nameOfVariableChangedNotification(BLENinebot.kvRideMode)
        let notSpeedLimitName = BLENinebot.nameOfVariableChangedNotification(BLENinebot.kSpeedLimit)
        let maxSpeedName = BLENinebot.nameOfVariableChangedNotification(BLENinebot.kAbsoluteSpeedLimit)
      
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLENinebotSettingsViewController.rideModeChanged(_:)), name: notRidingName, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLENinebotSettingsViewController.limitSpeedChanged(_:)), name: notSpeedLimitName, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLENinebotSettingsViewController.maxSpeedChanged(_:)), name: maxSpeedName, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
