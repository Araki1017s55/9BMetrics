//
//  BLERunningDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 29/3/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLERunningDashboard: UIViewController, BLEDeviceSelectorDelegate {
    
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
                
                self.connectionStarted(Notification(name: Notification.Name(rawValue: BLESimulatedClient.kStartConnection), object: ["state" : "connecting"]))
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    func initNotifications(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.connectionStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStartConnection), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.hasStopped(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStoppedRecording), object: nil)

        
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.recordingStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kHeaderDataReadyNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.dataUpdated(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kNinebotDataUpdatedNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.listDevices(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kdevicesDiscoveredNotification), object: nil)
  
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.recordingStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kConnectionReadyNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLERunningDashboard.dataUpdated(_:)), name: NSNotification.Name(rawValue: kWheelVariableChangedNotification), object: nil)
       
        

    }
    
    func removeNotifications(){
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    @IBAction func startStop(_ src : AnyObject){
        
        if let cl = self.client {
            
            if cl.connection.subscribed{
                cl.stop()
             }
            else if cl.connection.connecting {
                cl.stop()
                self.hasStopped(Notification(name: Notification.Name(rawValue: BLESimulatedClient.kStoppedRecording), object: nil))
            }
            else{
                cl.connect()
            }
        }
        
    }
    
    func hasStopped(_ not : Notification){
        let img = UIImage(named: "record")
        self.fStartStopButton.setImage(img, for: UIControlState())
        self.state = connectionState.stopped
        self.navigationController!.popViewController(animated: true)
        self.headersReceived = false
    }

    
    func dataUpdated(_ not : Notification){
        
        if !(UIApplication.shared.applicationState == UIApplicationState.active) {
            return
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            if let cli = self.client{
                if let nb = cli.datos{
                    
                    if !nb.getName().isEmpty && !self.headersReceived{
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
                    
                    
                    
                    let v = nb.getCurrentValueForVariable(.Speed) * 3.6 // In Km/h
                    
                    self.fSpeed.text = String(format:"%0.2f", v)
                    
                    if v >= 15.0 && v < 20.0{
                        self.fSpeed.textColor = UIColor.orange
                    }else if v > 20.0 {
                        self.fSpeed.textColor = UIColor.red
                    }else {
                        self.fSpeed.textColor = UIColor.black

                    }

                }
                
            }
        })
    }
    
    
 
    func updateScreen(){
        
        
        
    }
    
    func connectionStarted(_ not: Notification){
        
        self.state = connectionState.connecting
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            var imageArray : [UIImage] = [UIImage]()
            
            for i in 0...9 {
                
                if let img = UIImage(named: String(format:"record_%d", i)){
                    imageArray.append(img)
                }
            }
            
            self.fStartStopButton.setImage(UIImage(named:"record_0"), for: UIControlState())
            
            if let iv = self.fStartStopButton.imageView{
                iv.animationImages = imageArray
                iv.animationDuration = 0.5
                iv.startAnimating()
                
            }
        })
    }
    
    func recordingStarted(_ not: Notification){
        
        self.state = connectionState.connected
        
        DispatchQueue.main.async(execute: { () -> Void in
        
            self.stopAnimation()
            let img = UIImage(named: "recordOn")
            self.fStartStopButton.setImage(img, for: UIControlState())
            if let cli = self.client{
                if let nb = cli.datos{
                    self.fSeriaNumber.text = nb.getName()
                }
            }
        })
    }
    
    func recordingStopped(_ not: Notification){
        DispatchQueue.main.async(execute: { () -> Void in
        
            let img = UIImage(named: "record")
            self.fStartStopButton.setImage(img, for: UIControlState())
        })
    }
    
    func stopAnimation(){
        if let iv = self.fStartStopButton.imageView{
            iv.stopAnimating()
            iv.animationImages = []
            iv.animationDuration = 0.5
            
        }
    }
    
    func connectToPeripheral(_ peripheral : CBPeripheral){
        
        
        if let cli = self.client {
            cli.connection.connectPeripheral(peripheral)
        }
        self.dismiss(animated: true) { () -> Void in
            
            self.searching = false
            self.devSelector = nil
            self.devList.removeAll()
        }
        
    }
    
    
    func listDevices(_ notification: Notification){
        
        let devices = (notification as NSNotification).userInfo?["peripherals"] as? [CBPeripheral]
        
        // if searching is false we must create a selector
        
        if let devs = devices {
            
            if !self.searching {
                
                self.devList.removeAll()    // Remove old ones
                self.devList.append(contentsOf: devs)
                
                self.performSegue(withIdentifier: "deviceSelectorSegue", sender: self)
            }
            else{
                if let vc = self.devSelector{
                    vc.addDevices(devs)
                }
                
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "deviceSelectorSegue" {
            
            if let vc = segue.destination as? BLEDeviceSelector{
                
                self.devSelector = vc
                vc.addDevices(self.devList)
                vc.delegate = self
                self.devList.removeAll()
                self.searching = true
                
            }
        }
        
        else if segue.identifier == "graphSegueIdentifier" {
            if let vc = segue.destination as? GraphViewController  {
                if let nb = self.client?.datos {
                    nb.buildEnergy()
                
                    vc.ninebot = nb
            }
            }
            
        }
        else if segue.identifier == "ninebotSettingsSegue"{
            if let vc = segue.destination as? BLENinebotSettingsViewController{
                vc.ninebotClient = self.client
                
            }
        }


    }
    
    @IBAction func prepareForUnwind(_ segue: UIStoryboardSegue){
        
        self.dismiss(animated: true) { 
            
            
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.initNotifications()
        
        let store = UserDefaults.standard
        let testMode = store.bool(forKey: kTextMode)
        
        self.fSettingsButton.isHidden = !testMode
        self.fSettingsButton.isEnabled = testMode

        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeNotifications()
        super.viewWillDisappear(animated)
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height{
           // self.performSegueWithIdentifier("graphSegueIdentifier", sender: self)
        }
    }

    
}
