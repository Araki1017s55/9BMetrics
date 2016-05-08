//
//  BLERunningDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 29/3/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLERunningDashboard: UIViewController {
    
    @IBOutlet weak var fTime: UILabel!
    @IBOutlet weak var fDistance: UILabel!
    @IBOutlet weak var fCurrent: UILabel!
    @IBOutlet weak var fPower: UILabel!
    @IBOutlet weak var fSpeed: UILabel!
    @IBOutlet weak var fSpeedUnits: UILabel!
    @IBOutlet weak var fBattery: UILabel!
    @IBOutlet weak var fTemperature: UILabel!
    @IBOutlet weak var fStartStopButton: UIButton!
    @IBOutlet weak var fVoltage: UILabel!
    @IBOutlet weak var fSeriaNumber: UILabel!
    @IBOutlet weak var fSettingsButton: UIButton!

    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initNotifications()
        
        // Just check if we are already connecting
        
        if let cli = self.client {
            if cli.connection.connecting {
                
                self.connectionStarted(NSNotification(name: BLESimulatedClient.kStartConnection, object: ["state" : "connecting"]))
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                    self.fVoltage.text = String(format:"%0.2fV", nb.getCurrentValueForVariable(.Voltage))
                    
                    self.fCurrent.text = String(format:"%0.2fA", nb.getCurrentValueForVariable(.Current))
                    self.fPower.text = String(format:"%0.0fW", nb.getCurrentValueForVariable(.Power))
                    self.fDistance.text = String(format:"%6.2fkm", nb.getCurrentValueForVariable(.Distance) / 1000.0) // In Km
                    let (h, m, s) = nb.HMSfromSeconds(nb.getCurrentValueForVariable(.Duration))
                    self.fTime.text = String(format:"%02d:%02d:%02d", h, m, s)
                    self.fBattery.text = String(format:"%4.0f%%", nb.getCurrentValueForVariable(.Battery))
                    self.fTemperature.text = String(format:"%0.1fºC", nb.getCurrentValueForVariable(.Temperature))
                    
                    
                    
                    let v = nb.currentValueForVariable(.Speed)! * 3.6 // In Km/h
                    
                    self.fSpeed.text = String(format:"%0.2f", v)
                    
                    if v >= 15.0 && v < 20.0{
                        self.fSpeed.textColor = UIColor.orangeColor()
                    }else if v > 20.0 {
                        self.fSpeed.textColor = UIColor.redColor()
                    }else {
                        self.fSpeed.textColor = UIColor.blackColor()

                    }

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
                vc.delegate = self
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
        else if segue.identifier == "ninebotSettingsSegue"{
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
