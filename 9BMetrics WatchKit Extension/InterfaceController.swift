//
//  InterfaceController.swift
//  9BMetrics Extension
//
//  Created by Francisco Gorina Vanrell on 11/2/16.
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

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    
    
    @IBOutlet weak  var distLabel : WKInterfaceLabel!
    @IBOutlet weak  var tempsLabel : WKInterfaceLabel!
    @IBOutlet weak  var speedLabel : WKInterfaceLabel!
    @IBOutlet weak  var batteryLabel : WKInterfaceLabel!
    @IBOutlet weak  var temperatureLabel : WKInterfaceLabel!
    @IBOutlet weak  var unitsLabel : WKInterfaceLabel!
    @IBOutlet weak  var batteryButton : WKInterfaceButton!
    @IBOutlet weak  var temperatureButton : WKInterfaceButton!
   
    
    enum mobileFields {
        case speedField
        case batteryField
        case temperatureField
    }
    
    // State
    
    var skyColor = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    var distancia : Double = 0.0
    var oldDistancia : Double = -1.0
    var temps : Double = 0.0
    var oldTemps : Double = -1.0
    var oldTempsString : String = "0:0"
    var speed : Double = 0.0
    var oldSpeed : Double = -1.0
    var battery : Double = 0.0
    var oldBattery : Double = -1.0
    var remaining : Double = 0.0
    var oldRemaining : Double = 0.0
    var temperature : Double = 0.0
    var oldTemperature : Double = -1.0
    var recording : Bool = false
    var oldRecording : Bool = false
    var color : UIColor = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    var oldColor : UIColor = UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    var colorLevel : Int = 0
    var oldColorLevel : Int = 0
    var current : Double = 0.0
    var oldCurrent : Double = -1000.0
    var lockState = false
    var oldLockState = false
    var stateChanged = false
    
    var mainField = mobileFields.speedField
    var oldMainField = mobileFields.speedField
    
    
    var requestTimer : Timer?
    
    
    
    var wcsession : WCSession? = WCSession.default()
    
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        // To Do when we know what to do
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if let session = wcsession{
            session.delegate = self
            
            if #available(watchOSApplicationExtension 2.2, *) {
                if session.activationState != .activated{
                    session.activate()
                }
            } else {
                session.activate()
                // Fallback on earlier versions
            }
            addMenuItem(with: WKMenuItemIcon.play, title: "Start", action: #selector(InterfaceController.start))
            let lockTitle = lockState ? "Unlock" : "Lock"
            addMenuItem(with: WKMenuItemIcon.block, title: lockTitle, action: #selector(InterfaceController.lock))
           
        }
    }
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        requestData()
        
        requestTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true, block: { (tim : Timer) in
            self.requestData()
        })
    }
    

    override func didDeactivate() {
        
        if let tim = requestTimer {
            tim.invalidate()
            requestTimer = nil
        }
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    func requestData(){
        if let session = self.wcsession{
            
            if session.isReachable {
                
                let dict : [String : Any] = ["op" : "data" as Any]
                //let now = Date()
                session.sendMessage(dict, replyHandler: { (_ info: [String : Any]) in
                    
                    self.updateData(info as [String : AnyObject])
                    self.updateFields()
                    
                    //NSLog("Delta %f", Date().timeIntervalSince(now))
                    
                    
                }, errorHandler: { (error : Error) in
                    let nerr  = error as NSError
                    NSLog("Error al demanar dades %@", nerr.localizedDescription)
                })
                
            }
        }
    }

    @IBAction func handleSpeedGesture(){
        
        self.honk()
    
    }
    
    func updateData(_ applicationContext: [String : AnyObject]){
        
        if applicationContext.count == 0 {
            return
        }
        
        if let r = applicationContext["recording"] as? Double {
            
            self.recording = r == 1.0
        }
        
        if let  dist = applicationContext["distancia"] as? Double{
            self.distancia = dist
        }
        
        if let t = applicationContext["temps"]  as? Double{
            self.temps = t
        }
 
        if let c = applicationContext["current"]  as? Double{
            self.current = c
        }

        if let sp = applicationContext["speed"]  as? Double {
            self.speed = sp
        }
        
        if let bat = applicationContext["battery"]  as? Double {
            self.battery = bat
        }
        
        if let rem = applicationContext["remaining"]  as? Double {
            self.remaining = rem
        }
        
        if let temp = applicationContext["temperature"]  as? Double {
            self.temperature = temp
        }
        
        if let lock = applicationContext["lock"]  as? Double {
            self.lockState = lock == 1.0
        }
        
        
        let cx = applicationContext["color"]  as? Double
        
        if let c = cx {
            let ci = Int(floor(c))
            
            switch (ci) {
                
            case 1 :
                self.color = UIColor.orange
                
            case 2 :
                self.color = UIColor.red
                
            default :
                self.color = skyColor
            }
            
            if ci > self.colorLevel {
                WKInterfaceDevice.current().play(WKHapticType.directionUp)
                self.colorLevel = ci
            }
            else if ci < self.colorLevel {
                WKInterfaceDevice.current().play(WKHapticType.directionDown)
                self.colorLevel = ci
            }
        }
        else {
            self.color = skyColor
            self.colorLevel = 0
        }
        
        // Check a change in color and generate haptic feedback
        
        self.stateChanged = true
    }
    
    func updateFields(){
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            if fabs(self.oldDistancia - self.distancia) > 1.0 {
                
                if self.distancia < 1000.0  {
                    let units = "m"
                    self.distLabel.setText(String(format: "%3.0f %@", self.distancia, units))
                }
                else if fabs(self.distancia - self.oldDistancia) >= 10.0 {
                    let units = "Km"
                    self.distLabel.setText(String(format: "%5.2f %@", self.distancia/1000.0, units))
                }
                self.oldDistancia = self.distancia
            
            }
            
            if self.oldTemps != self.temps && false {
                let h = Int(floor(self.temps / 3600.0))
                let m = Int(floor(self.temps - Double(h) * 3600.0)/60.0)
                let s = Int(floor(self.temps - Double(h) * 3600.0 - Double(m)*60.0))
                var tempsString = String(format: "%2d:%2d:%2d", h, m, s)
                
                if h == 0 {
                    tempsString = String(format: "%2d:%2d", m, s)
                }
                
                if tempsString != self.oldTempsString {
                    self.tempsLabel.setText(tempsString)
                    self.oldTempsString = tempsString
                }
                
                self.oldTemps = self.temps
            }
            
            
            if self.oldCurrent != self.current {
                
                let txt = String(format: "%5.2f A", self.current)
                
                self.tempsLabel.setText(txt)
                if self.current >= 0 && self.oldCurrent < 0{
                    
                    self.tempsLabel.setTextColor(self.skyColor)
                    
                } else if self.current < 0 && self.oldCurrent >= 0 {
                    
                    self.tempsLabel.setTextColor(UIColor.red)
                }
                
                self.oldCurrent = self.current
            }
            
            
            if fabs(self.oldSpeed - self.speed) >= 0.01  || self.mainField != self.oldMainField{
                
                switch self.mainField {
                    
                case .speedField:
                    self.speedLabel.setText(String(format: "%5.2f", self.speed))
                    self.unitsLabel.setText("Km/h")
                    
                case .batteryField:
                    
                    self.batteryButton.setTitle(String(format: "%5.0f K/h", self.speed))
                    
                case .temperatureField:
                    self.temperatureButton.setTitle(String(format: "%5.0f K/h", self.speed))

                
            }
            }
            
            if fabs(self.oldBattery - self.battery) >= 1.0  || self.mainField != self.oldMainField{
                
                switch self.mainField {
                
                 case .batteryField:
                    self.speedLabel.setText(String(format: "%2d", Int(self.battery)))
                    self.unitsLabel.setText("%")
 
                default:
                    self.batteryButton.setTitle(String(format: "%2d %%", Int(self.battery)))

                }
                
            }
            
            //self.temperatureLabel.setText(String(format: "%5.2f %@", self.remaining, "Km"))
            
            if fabs(self.oldTemperature - self.temperature) >= 0.1  || self.mainField != self.oldMainField{
                
                
                switch self.mainField {
                    
                case .temperatureField:
                    self.speedLabel.setText(String(format: "%3.0f", self.temperature))
                    self.unitsLabel.setText("ºC")
                    
                    
                default:
                    self.temperatureButton.setTitle(String(format: "%3.0f%@", self.temperature, "ºC"))
                    
                }
               
                
             }
            
            
            // Colors only affect mainField
            
             
            
            switch self.mainField {
                
            case .speedField:
                if self.colorLevel != self.oldColorLevel || self.mainField != self.oldMainField{
                
                    self.speedLabel.setTextColor(self.color)
                    self.unitsLabel.setTextColor(self.color)
                }
                
            case .batteryField:
                if fabs(self.oldBattery - self.battery) >= 1.0  || self.mainField != self.oldMainField{
                    if self.battery < 30.0{
                        self.speedLabel.setTextColor(UIColor.red)
                        self.unitsLabel.setTextColor(UIColor.red)
                    }else{
                        self.speedLabel.setTextColor(UIColor.green)
                        self.unitsLabel.setTextColor(UIColor.green)
                    }
                }
                
            default:
                
                if self.mainField != self.oldMainField {
                    self.speedLabel.setTextColor(self.skyColor)
                    self.unitsLabel.setTextColor(self.skyColor)

                }
                
            }
            
            self.oldSpeed = self.speed
            self.oldTemperature = self.temperature
            self.oldBattery = self.battery
            self.oldColorLevel = self.colorLevel
            self.oldMainField = self.mainField
            
            
            
            
            if self.recording != self.oldRecording || self.lockState != self.oldLockState{
                if self.recording {
                    self.clearAllMenuItems()
                    self.addMenuItem(with: WKMenuItemIcon.play, title: "Stop", action: #selector(InterfaceController.stop))
                    let lockTitle = self.lockState ? "Unlock" : "Lock"

                    self.addMenuItem(with: WKMenuItemIcon.block, title: lockTitle, action: #selector(InterfaceController.lock))

                }
                else {
                    self.clearAllMenuItems()
                    self.addMenuItem(with: WKMenuItemIcon.play, title: "Start", action: #selector(InterfaceController.start))
                    let lockTitle = self.lockState ? "Unlock" : "Lock"

                    self.addMenuItem(with: WKMenuItemIcon.block, title: lockTitle, action: #selector(InterfaceController.lock))
                }
                self.oldRecording = self.recording
                self.oldLockState = self.lockState
            }
            
            
            self.stateChanged = false
        })
    }
    
    func start(){
        self.sendOp("start", value: nil)
    }
    
    func stop(){
        self.sendOp("stop", value: nil)
    }
    
    func honk(){
        self.sendOp("honk", value: nil)
    }
    
    func lock(){
        self.sendOp("lock", value: nil)
    }
    
    func sendOp(_ op : String, value : AnyObject?){
        if let session = self.wcsession{
            
            if session.isReachable {
                
                var dict : [String : AnyObject] = ["op" : op as AnyObject]
                if let v = value {
                    dict["value"] = v
                }
                session.sendMessage(dict, replyHandler: nil, errorHandler: { (err : Error) -> Void in
                    
                    let nerr  = err as NSError
                    NSLog("Error al enviar missatge %@", nerr.localizedDescription)
                    
                })
            }
        }
    }
    
    
    
    @IBAction func temperatureAction(){
        
        self.mainField = self.mainField == .temperatureField ? .speedField : .temperatureField
        self.updateFields()
     }
    
    
    @IBAction func batteryAction(){
        self.mainField = self.mainField == .batteryField ? .speedField : .batteryField
        self.updateFields()
    }
     /*
     func sessionWatchStateDidChange(_ session: WCSession) {
     
     // NSLog("WCSessionState changed. Reachable %@", session.reachable)
     } */
    
    func  session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
   
        
        if let v = applicationContext as? [String : Double]{
            
            self.updateData(v as [String : AnyObject])
            self.updateFields()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]){
        if let v = message as? [String : Double]{
            
            self.updateData(v as [String : AnyObject])
            self.updateFields()
        }

    }
    
}
