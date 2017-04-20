//
//  SettingsViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 19/2/16.
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


import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var fAllowSpeech: UISwitch!
    @IBOutlet weak var uuidLabel: UILabel!
    
    @IBOutlet weak var fBlockSleepTimer: UISwitch!
    @IBOutlet weak var fGraphicDashboard: UISwitch!
    weak var delegate : ViewController?
    @IBOutlet weak var fWheelName: UILabel!
    @IBOutlet weak var fWheelSN: UILabel!
    @IBOutlet weak var fSpeedAlarm: UITextField!
    @IBOutlet weak var fBatteryAlarm: UITextField!
    @IBOutlet weak var fPassword: UITextField!
    @IBOutlet weak var fNotifySpeed: UISwitch!
    @IBOutlet weak var fNotifyBattery: UISwitch!
    
    @IBOutlet weak var fDistanceCoef: UILabel!
    
    @IBOutlet weak var fSpeedCoef: UILabel!
    
    @IBOutlet weak var fEnableCorrectionsSwitch: UISwitch!
    
    @IBOutlet weak var fSpeedUnitsLabel: UILabel!
    
    @IBOutlet weak var fProgressCalibration: UIProgressView!
    
    @IBOutlet weak var fRecalculateButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fSpeedUnitsLabel.text = UnitManager.sharedInstance.longDistanceUnit+"/h"
        // Do any additional setup after loading the view.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
        // setupNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        let store = UserDefaults.standard
        
        if let stspeed = fSpeedAlarm.text {
            
            if let dspeed = Double(stspeed.replacingOccurrences(of: ",", with: ".")){     // Dades en m/s
                store.set(dspeed / UnitManager.sharedInstance.convertSpeed(1.0), forKey: kSpeedAlarm)
            }
            
        }
        
        
        
        if let stbattery = fBatteryAlarm.text {
            
            if let dbattery = Double(stbattery.replacingOccurrences(of: ",", with: ".")){
                if dbattery >= 0.0 && dbattery <= 100.0 {
                    store.set(dbattery, forKey: kBatteryAlarm)
                }
            }
        }
        
        
        
        if let stpassword = fPassword.text {
            
            store.set(stpassword, forKey: kPassword)
            
        }
        
        store.set(fNotifySpeed.isOn, forKey: kNotifySpeed)
        store.set(fNotifySpeed.isOn, forKey: kNotifyBattery)
        store.set(!fAllowSpeech.isOn, forKey: kForbidSpeech)
        
        updateWheel()
        
        
        
        //   removeNotifications()
        super.viewWillDisappear(animated)
    }
    
    func updateWheel(){
        
        if let uuid = uuidLabel.text {
            if let wheel = WheelDatabase.sharedInstance.getWheelFromUUID(uuid: uuid){
                
                if let stspeed = fSpeedAlarm.text {
                    
                    if let dspeed = Double(stspeed.replacingOccurrences(of: ",", with: ".")){     // Dades en m/s
                        wheel.alarmSpeed = dspeed / UnitManager.sharedInstance.convertSpeed(1.0)
                    }
                    
                }
                
                if let stbattery = fBatteryAlarm.text {
                    if let dbattery = Double(stbattery.replacingOccurrences(of: ",", with: ".")){
                        if dbattery >= 0.0 && dbattery <= 100.0 {
                            wheel.batteryAlarm = dbattery
                        }
                    }
                }
                
                if let stpassword = fPassword.text {
                    
                    wheel.password = stpassword
                    
                }
                
                wheel.notifySpeed = fNotifySpeed.isOn
                wheel.notifyBattery = fNotifyBattery.isOn
                wheel.enableCorrections = fEnableCorrectionsSwitch.isOn
                
                WheelDatabase.sharedInstance.setWheel(wheel: wheel)
            }
        }
        
        
        
    }
    func loadData(){
        if let dele = delegate {
            
            let store = UserDefaults.standard
            let dashboardMode = store.bool(forKey: dele.kDashboardMode)
            fGraphicDashboard.isOn = dashboardMode
            let allowSpeech = !store.bool(forKey: kForbidSpeech)
            fAllowSpeech.isOn = allowSpeech
            
            
            if let uuid = store.object(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey) as? String{
                uuidLabel.text = uuid
                // Load wheel and show current wheel data if it exists
                
                if let wheel = WheelDatabase.sharedInstance.getWheelFromUUID(uuid: uuid){  // Got a wheel
                    
                    let sa = wheel.alarmSpeed
                    
                    let ssa = String(format: "%0.2f", UnitManager.sharedInstance.convertSpeed(sa))       // Presentem dades en km/h
                    fSpeedAlarm.text = ssa
                    
                    let ba = wheel.batteryAlarm
                    let sba  = String(format: "%0.0f", ba)
                    fBatteryAlarm.text = sba
                    
                    let pwd = wheel.password
                    fPassword.text = pwd
                    
                    fWheelName.text = wheel.name
                    fWheelSN.text = wheel.serialNo
                    fNotifySpeed.isOn = wheel.notifySpeed
                    fNotifyBattery.isOn = wheel.notifyBattery
                    
                    fSpeedCoef.text = String(format: "Speed %0.2f", wheel.speed_coef)
                    fDistanceCoef.text = String(format: "Dist %0.2f", wheel.distance_coef)
                    
                    fEnableCorrectionsSwitch.isOn = wheel.enableCorrections
                    
                    
                } else {    // No Wheel
                    let sa = store.double(forKey: kSpeedAlarm)
                    
                    let ssa = String(format: "%0.2f", UnitManager.sharedInstance.convertSpeed(sa))       // Presentem dades en km/h
                    fSpeedAlarm.text = ssa
                    
                    let ba = store.double(forKey: kBatteryAlarm)
                    let sba  = String(format: "%0.0f", ba)
                    fBatteryAlarm.text = sba
                    
                    
                    if let pwd = store.string(forKey: kPassword){
                        fPassword.text = pwd
                    } else {
                        fPassword.text = "000000"
                    }
                    fWheelName.text = ""
                    fWheelSN.text = ""
                    
                    fNotifySpeed.isOn = store.bool(forKey: kNotifySpeed)
                    fNotifyBattery.isOn = store.bool(forKey: kNotifyBattery)
                    
                    
                }
                
                
            }else {     // No UUID
                uuidLabel.text = ""
                let sa = store.double(forKey: kSpeedAlarm)
                
                let ssa = String(format: "%0.2f", sa * 3.6)       // Presentem dades en km/h
                fSpeedAlarm.text = ssa
                
                let ba = store.double(forKey: kBatteryAlarm)
                let sba  = String(format: "%0.0f", ba)
                fBatteryAlarm.text = sba
                
                
                if let pwd = store.string(forKey: kPassword){
                    fPassword.text = pwd
                } else {
                    fPassword.text = "000000"
                }
                fWheelName.text = ""
                fWheelSN.text = ""
                fNotifySpeed.isOn = store.bool(forKey: kNotifySpeed)
                fNotifyBattery.isOn = store.bool(forKey: kNotifyBattery)
                
                
            }
            
            fBlockSleepTimer.isOn = store.bool(forKey: kBlockSleepMode)
            
            
            
        }
        
    }
    
    //    func setupNotifications(){
    //
    //        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    //        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    //
    //        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChange:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    //
    //        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardDidChange:", name: UIKeyboardDidChangeFrameNotification, object: nil)
    //
    //    }
    //
    //    func removeNotifications(){
    //        NSNotificationCenter.defaultCenter().removeObserver(self)
    //    }
    //
    //    func keyboardWillHide(notification : NSNotification){
    //        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
    //            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
    //            var frame = self.view.frame
    //            frame.size.height = frame.size.height - keyboardSize.height
    //            self.view.frame = frame
    //        }
    //    }
    //    func keyboardWillShow(notification : NSNotification){
    //        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
    //            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
    //            var frame = self.view.frame
    //            frame.size.height = frame.size.height + keyboardSize.height
    //            self.view.frame = frame
    //       }
    //     }
    //    func keyboardWillChange(not : NSNotification){
    //
    //    }
    //    func keyboardDidChange(not : NSNotification){
    //
    //    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clearUUID(_ src : AnyObject){
        
        let store = UserDefaults.standard
        store.removeObject(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        loadData()
        
    }
    
    
    
    @IBAction func setGraphicDashboard(_ src : UISwitch){
        
        let store = UserDefaults.standard
        if let dele = delegate {
            
            store.set(src.isOn, forKey: dele.kDashboardMode)
        }
        
        var state = "Off"
        
        if src.isOn{
            state = "On"
        }
        
        AppDelegate.debugLog("Switch Value %@", state)
        
    }
    
    @IBAction func setBlockSleep(_ src : UISwitch){
        
        let store = UserDefaults.standard
        if let dele = delegate {
            
            store.set(src.isOn, forKey: dele.kBlockSleepMode)
        }
        
        var state = "Off"
        
        if src.isOn{
            state = "On"
        }
        
        AppDelegate.debugLog("Switch Value %@", state)
        
    }
    
    @IBAction func recalculateCalibration(){
        
        fRecalculateButton.isHidden = true
        
        fProgressCalibration.setProgress(0.0, animated: false)
        fProgressCalibration.isHidden = false
        
        DispatchQueue.global().async( execute: {
            
            if let uuid = self.uuidLabel.text , uuid.characters.count > 10{
                
                if let wheel = WheelDatabase.sharedInstance.getWheelFromUUID(uuid: uuid){
                    
                    wheel.recomputeAdjust(progressItem: self.fProgressCalibration)
                    WheelDatabase.sharedInstance.setWheel(wheel: wheel)
                }
            }
            
            DispatchQueue.main.sync(execute: {
                self.fProgressCalibration.isHidden = true
                self.fRecalculateButton.isHidden = false
                self.loadData()
                
            })
            
        })
    }
    
    @IBAction func resetCalibration(){
        
        if let uuid = uuidLabel.text , uuid.characters.count > 10{
            
            if let wheel = WheelDatabase.sharedInstance.getWheelFromUUID(uuid: uuid){
                
                wheel.resetCalibration()
                WheelDatabase.sharedInstance.setWheel(wheel: wheel)
                loadData()
            }
        }
        
    }
    
    @IBAction func selectWheel(){
        
        if let vc = WheelSelectorTableViewController.instantiate() as?  WheelSelectorTableViewController{
            navigationController?.pushViewController(vc, animated: true)
         }
        
    }
    
}
