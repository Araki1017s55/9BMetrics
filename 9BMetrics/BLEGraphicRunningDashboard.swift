//
//  BLEGraphicRunningDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 9/5/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
import UIKit
import CoreBluetooth

class BLEGraphicRunningDashboard: UIViewController, BLEDeviceSelectorDelegate {
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
    
    
    let sphereColor = UIColor.black
    let labelColor = UIColor.black
    
    var batTop = 1.0
    var batOk = 0.2

    let tempTop = 90.0
    let tempOK = 60.0
    
    var speedTop = 30.0
    var speedOK = 23.0
    
    var distanceCorrection = 1.0
    var speedCorrection = 1.0
    
    
    var tempAreas : [TMKClockView.arc] = []
    var battAreas : [TMKClockView.arc] = []
    var speedAreas  : [TMKClockView.arc] = []

    
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
    
    var timer : Timer?
    
    var deviceName : String = ""
    
    required init?(coder aDecoder: NSCoder) {
        
  
        

        super.init(coder: aDecoder)
        
    }
    
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.initNotifications()
            
            // Just check if we are already connecting
            
            if let cli = self.client {
                if cli.connection.state == .connecting {
                    
                    self.connectionStarted(Notification(name: Notification.Name(rawValue: BLESimulatedClient.kStartConnection), object: ["state" : "connecting"]))
                }
            }
 
            
            
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
    
        func initNotifications(){
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.connectionStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStartConnection), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.hasStopped(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStoppedRecording), object: nil)
            
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.recordingStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kHeaderDataReadyNotification), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.dataUpdated(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kNinebotDataUpdatedNotification), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.listDevices(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kdevicesDiscoveredNotification), object: nil)
            
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.recordingStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kConnectionReadyNotification), object: nil)
            
            NotificationCenter.default.addObserver(self, selector: #selector(BLEGraphicRunningDashboard.dataUpdated(_:)), name: NSNotification.Name(rawValue: kWheelVariableChangedNotification), object: nil)
            
            
            
        }
        
        func removeNotifications(){
            
            NotificationCenter.default.removeObserver(self)
            
        }
        
        @IBAction func startStop(_ src : AnyObject){
            
            if let cl = self.client {
                
                if cl.isRecording(){
                    cl.stop()
                }
                 else{
                    cl.start()
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
                        
                        self.fCurrent.text = String(format:"%0.2fA", nb.getCurrentValueForVariable(.Current))
                        self.fPower.text = String(format:"%0.0fW", nb.getCurrentValueForVariable(.Power))
                        self.fDistance.text = String(format:"%6.2fkm", nb.getCurrentValueForVariable(.Distance) / 1000.0 * self.distanceCorrection) // In Km
                        let (h, m, s) = nb.HMSfromSeconds(nb.getCurrentValueForVariable(.Duration))
                        self.fTime.text = String(format:"%02d:%02d:%02d", h, m, s)
                        
                        let v = nb.getCurrentValueForVariable(.Speed) * 3.6 * self.speedCorrection// In Km/h
                        let b = nb.getCurrentValueForVariable(.Battery)
                        let t = nb.getCurrentValueForVariable(.Temperature)
                        let volt = nb.getCurrentValueForVariable(.Voltage)
                        
                        let battLevels = [TMKClockView.arc(start: b / 100.0, end: 0.5, color: UIColor.red)]
                        let tempLevels = [TMKClockView.arc(start: t / self.tempTop, end: 0.5, color: UIColor.red)]
                        
                        
                        self.fSpeed.updateData(String(format:"%0.2f", v) , units: "Km/h", value: v, minValue: 0, maxValue: self.speedTop)
 
                        self.fBattery.updateData(String(format:"%0.1f", volt) , units: "V", radis: battLevels, arcs: self.battAreas, minValue: 0, maxValue: 100.0)

                        self.fTemperature.updateData(String(format:"%0.1f", t) , units: "ºC", radis: tempLevels, arcs: self.tempAreas, minValue: 0.0, maxValue: self.tempTop)

                        
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
                    
                    //self.devList.removeAll()    // Remove old ones
                    self.devList.append(contentsOf: devs)
                    
                    self.performSegue(withIdentifier: "grDeviceSelectorSegue", sender: self)
                }
                else{
                    if let vc = self.devSelector{
                        vc.addDevices(devs)
                    }
                    
                }
            }
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
            if segue.identifier == "grDeviceSelectorSegue" {
                
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
            else if segue.identifier == "graphicSettingsSegue"{
                if let vc = segue.destination as? BLENinebotSettingsViewController{
                    vc.ninebotClient = self.client
                    
                }
            }
            
            else if segue.identifier == "graphMapSegue"{
                if let vc = segue.destination as? BLEMapViewController,
                    let nb = self.client?.datos{
                    vc.dades = nb
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
