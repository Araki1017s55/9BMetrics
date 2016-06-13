//
//  BLEGraphicRunningDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 9/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
import UIKit
import CoreBluetooth

class BLEGraphicRunningDashboard: UIViewController {
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
        @IBOutlet weak var fStartStopButton: UIButton!
        @IBOutlet weak var fVoltage: UILabel!
        @IBOutlet weak var fSeriaNumber: UILabel!
        @IBOutlet weak var fSettingsButton: UIButton!
        
        @IBOutlet weak var fCCurrent : TMKClockView!
    
    
    let sphereColor = UIColor.blackColor()
    let labelColor = UIColor.blackColor()
    
    let batTop = 1.0

    let tempTop = 90.0
    let tempOK = 60.0
    
    let speedTop = 30.0
    let speedOK = 23.0
    
    
    let tempAreas : [TMKClockView.arc]
    let battAreas : [TMKClockView.arc]
    let speedAreas  : [TMKClockView.arc]

    
    let kTextMode = "enabled_test"
        
        weak var client : BLESimulatedClient?
        
        var devSelector : BLEDeviceSelector?
        var devList = [CBPeripheral]()
        
        var searching = false
        
        var headersReceived = false
        
        enum connectionState {
            case stopped
            case connecting
            case connected
        }
        
        var state : connectionState = connectionState.stopped
    
    var timer : NSTimer?
    
    required init?(coder aDecoder: NSCoder) {
        
        
        battAreas = [TMKClockView.arc(start: 0.0, end: 0.2, color: UIColor.redColor()),
                     TMKClockView.arc(start: 0.2, end: 1.0, color: UIColor.greenColor())]
        
        
        tempAreas = [TMKClockView.arc(start: 0.0, end: tempOK / tempTop, color: UIColor.greenColor()),
                     TMKClockView.arc(start: tempOK / tempTop, end: 1.0, color: UIColor.redColor())]
        
        
        speedAreas = [TMKClockView.arc(start: 0.0, end: speedOK/speedTop, color: UIColor.greenColor()),
                      TMKClockView.arc(start: speedOK/speedTop, end: 1.0, color: UIColor.redColor())]
        

        super.init(coder: aDecoder)
        
    }
    
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.initNotifications()
            
            // Just check if we are already connecting
            
            if let cli = self.client {
                if cli.connection.connecting {
                    
                    self.connectionStarted(NSNotification(name: BLESimulatedClient.kStartConnection, object: ["state" : "connecting"]))
                }
            }
            
            self.fSpeed.sphereColor = sphereColor
            self.fSpeed.labelsColor = labelColor
            self.fSpeed.arcs = self.speedAreas
            self.fSpeed.setup()
            
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
        
    func testSpeed (timer : NSTimer){
        //  Tests
        
        // Get a value
        
        let val = fabs(Double(arc4random()) / Double(UINT32_MAX)) * speedTop;
        
        let speedLevels = [TMKClockView.arc(start:val/speedTop, end: 0.5, color: UIColor.redColor())]
        
        
        self.fSpeed.updateData(String(format:"%0.2f", val) , units: "Km/h", value: val, minValue: 0, maxValue: self.speedTop)
        

    }
    
        func initNotifications(){
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.connectionStarted(_:)), name: BLESimulatedClient.kStartConnection, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.hasStopped(_:)), name: BLESimulatedClient.kStoppedRecording, object: nil)
            
            
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.recordingStarted(_:)), name: BLESimulatedClient.kHeaderDataReadyNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.dataUpdated(_:)), name: BLESimulatedClient.kNinebotDataUpdatedNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.listDevices(_:)), name: BLESimulatedClient.kdevicesDiscoveredNotification, object: nil)
            
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.recordingStarted(_:)), name: BLESimulatedClient.kConnectionReadyNotification, object: nil)
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLERunningDashboard.dataUpdated(_:)), name: kWheelVariableChangedNotification, object: nil)
            
            
            
        }
        
        func removeNotifications(){
            
            NSNotificationCenter.defaultCenter().removeObserver(self)
            
        }
        
        @IBAction func startStop(src : AnyObject){
            
            if let cl = self.client {
                
                if cl.connection.subscribed{
                    cl.stop()
                }
                else if cl.connection.connecting {
                    cl.stop()
                    self.hasStopped(NSNotification(name: BLESimulatedClient.kStoppedRecording, object: nil))
                }
                else{
                    cl.connect()
                }
            }
            
        }
        
        func hasStopped(not : NSNotification){
            let img = UIImage(named: "record")
            self.fStartStopButton.setImage(img, forState: UIControlState.Normal)
            self.state = connectionState.stopped
            self.navigationController!.popViewControllerAnimated(true)
            self.headersReceived = false
        }
        
        
        func dataUpdated(not : NSNotification){
            
            if !(UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                if let cli = self.client{
                    if let nb = cli.datos{
                        
                        if let name = nb.getName() where !name.isEmpty && !self.headersReceived{
                            self.headersReceived = true
                            self.fSeriaNumber.text = nb.getName()
                        }
                        
                        //cell.detailTextLabel!.text =
                        
                        self.fCurrent.text = String(format:"%0.2fA", nb.getCurrentValueForVariable(.Current))
                        self.fPower.text = String(format:"%0.0fW", nb.getCurrentValueForVariable(.Power))
                        self.fDistance.text = String(format:"%6.2fkm", nb.getCurrentValueForVariable(.Distance) / 1000.0) // In Km
                        let (h, m, s) = nb.HMSfromSeconds(nb.getCurrentValueForVariable(.Duration))
                        self.fTime.text = String(format:"%02d:%02d:%02d", h, m, s)
                        
                        let v = nb.currentValueForVariable(.Speed)! * 3.6 // In Km/h
                        let b = nb.getCurrentValueForVariable(.Battery)
                        let t = nb.getCurrentValueForVariable(.Temperature)
                        let volt = nb.getCurrentValueForVariable(.Voltage)
                        
                        let battLevels = [TMKClockView.arc(start: b / 100.0, end: 0.5, color: UIColor.redColor())]
                        let tempLevels = [TMKClockView.arc(start: t / self.tempTop, end: 0.5, color: UIColor.redColor())]
                        
                        
                        self.fSpeed.updateData(String(format:"%0.2f", v) , units: "Km/h", value: v, minValue: 0, maxValue: self.speedTop)
 
                        self.fBattery.updateData(String(format:"%0.1f", volt) , units: "V", radis: battLevels, arcs: self.battAreas, minValue: 0, maxValue: 100.0)

                        self.fTemperature.updateData(String(format:"%0.1f", t) , units: "ºC", radis: tempLevels, arcs: self.tempAreas, minValue: 0.0, maxValue: self.tempTop)

                        
                    }
                    
                }
            })
        }
        
        
        
        func updateScreen(){
            
            
            
        }
        
        func connectionStarted(not: NSNotification){
            
            self.state = connectionState.connecting
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                var imageArray : [UIImage] = [UIImage]()
                
                for i in 0...9 {
                    
                    if let img = UIImage(named: String(format:"record_%d", i)){
                        imageArray.append(img)
                    }
                }
                
                self.fStartStopButton.setImage(UIImage(named:"record_0"), forState: UIControlState.Normal)
                
                if let iv = self.fStartStopButton.imageView{
                    iv.animationImages = imageArray
                    iv.animationDuration = 0.5
                    iv.startAnimating()
                    
                }
            })
        }
        
        func recordingStarted(not: NSNotification){
            
            self.state = connectionState.connected
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.stopAnimation()
                let img = UIImage(named: "recordOn")
                self.fStartStopButton.setImage(img, forState: UIControlState.Normal)
                if let cli = self.client{
                    if let nb = cli.datos{
                        self.fSeriaNumber.text = nb.getSerialNo()
                    }
                }
            })
        }
        
        func recordingStopped(not: NSNotification){
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                let img = UIImage(named: "record")
                self.fStartStopButton.setImage(img, forState: UIControlState.Normal)
            })
        }
        
        func stopAnimation(){
            if let iv = self.fStartStopButton.imageView{
                iv.stopAnimating()
                iv.animationImages = []
                iv.animationDuration = 0.5
                
            }
        }
        
        func connectToPeripheral(peripheral : CBPeripheral){
            
            
            if let cli = self.client {
                cli.connection.connectPeripheral(peripheral)
            }
            self.dismissViewControllerAnimated(true) { () -> Void in
                
                self.searching = false
                self.devSelector = nil
                self.devList.removeAll()
            }
            
        }
        
        
        func listDevices(notification: NSNotification){
            
            let devices = notification.userInfo?["peripherals"] as? [CBPeripheral]
            
            // if searching is false we must create a selector
            
            if let devs = devices {
                
                if !self.searching {
                    
                    self.devList.removeAll()    // Remove old ones
                    self.devList.appendContentsOf(devs)
                    
                    self.performSegueWithIdentifier("deviceSelectorSegue", sender: self)
                }
                else{
                    if let vc = self.devSelector{
                        vc.addDevices(devs)
                    }
                    
                }
            }
        }
        
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            
            if segue.identifier == "deviceSelectorSegue" {
                
                if let vc = segue.destinationViewController as? BLEDeviceSelector{
                    
                    self.devSelector = vc
                    vc.addDevices(self.devList)
                 //TODO: Correct this   vc.delegate = self
                    self.devList.removeAll()
                    self.searching = true
                    
                }
            }
                
            else if segue.identifier == "graphSegueIdentifier" {
                if let vc = segue.destinationViewController as? GraphViewController  {
                    if let nb = self.client?.datos {
                        nb.buildEnergy()
                        
                        vc.ninebot = nb
                    }
                }
                
            }
            else if segue.identifier == "graphicSettingsSegue"{
                if let vc = segue.destinationViewController as? BLENinebotSettingsViewController{
                    vc.ninebotClient = self.client
                    
                }
            }
            
            
        }
        
        @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
            
            self.dismissViewControllerAnimated(true) { 
                
                
            }
            
        }
        
        override func viewWillAppear(animated: Bool) {
            self.navigationController?.navigationBar.hidden = true
            self.initNotifications()
            
            let store = NSUserDefaults.standardUserDefaults()
            let testMode = store.boolForKey(kTextMode)
            
            self.fSettingsButton.hidden = !testMode
            self.fSettingsButton.enabled = testMode
            
            super.viewWillAppear(animated)
            
        }
        
        override func viewWillDisappear(animated: Bool) {
            self.removeNotifications()
            super.viewWillDisappear(animated)
        }
        
        
        override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            if size.width > size.height{
                // self.performSegueWithIdentifier("graphSegueIdentifier", sender: self)
            }
        }
        
        
    

}
