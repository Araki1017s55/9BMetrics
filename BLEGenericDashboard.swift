//
//  BLEGenericDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 14/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//
// BLEGenericDashboard is a class to be subclassed for different Dashboards.
// Has most of the logic and only needs to be modified to update the User Interface with the track data
// It needs 2 UIButtons, fStartStopButton is the standard start/stop rotating button
// The second one is fSettingsButton that open the running wheel settings button. Not sure will use it
//
// Only things to customize
//
//  Add outlets for your widgets
//  Implement
//    func updateName(_ name : String){
// and
//  func updateUI(_ track : WheelTrack){
//
//  That's all folks


import UIKit
import CoreBluetooth
import GyrometricsDataModel

class BLEGenericDashboard: UIViewController, BLEDeviceSelectorDelegate, UIGestureRecognizerDelegate {
    
    // These buttons are mandatory!!!
    
    @IBOutlet weak var fStartStopButton: UIButton!
    @IBOutlet weak var fSettingsButton: UIButton?
    
    // The source of all our data
    
    weak var client : BLESimulatedClient?
    var devSelector : BLEDeviceSelector?
    
    var devSelectorSegue = "deviceSelectorSegue"
    
    // For BLEDeviceSelectorDelegate
    var devList = [CBPeripheral]()
    var searching = false
    
    // Managing state
    var headersReceived = false
    
    var distanceCorrection = 1.0
    var speedCorrection = 1.0
    
    let delta = 5.0 // minuts que mostra el gràfic de velocitat en el moment que el treiem desde el dashboard

    
    enum connectionState {
        case stopped
        case connecting
        case connected
    }
    
    var state : connectionState = connectionState.stopped
    
    let kTextMode = "enabled_test"
    
    
    // Generic minimum viewDidLoad. Manage already connecting situation
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let but = fSettingsButton{
            but.addTarget(self, action: #selector(BLEGenericDashboard.showRunningSettings), for: .primaryActionTriggered)
        }
        
        self.initNotifications()
        
        // Just check if we are already connecting
        
        if let cli = self.client {
            if cli.connection.state == .connecting {
                
                connectionStarted(Notification(name: Notification.Name(rawValue: BLESimulatedClient.kStartConnection), object: ["state" : "connecting"]))
            }
        }
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Set notifications to receive information
    
    func initNotifications(){
        
        // Main connection notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.connectionStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStartConnection), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.hasStopped(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kStoppedRecording), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.recordingStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kHeaderDataReadyNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.dataUpdated(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kNinebotDataUpdatedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.dataUpdated(_:)), name: NSNotification.Name(rawValue: kWheelVariableChangedNotification), object: nil)
        
        
        // Device Selector notifications
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.listDevices(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kdevicesDiscoveredNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BLEGenericDashboard.recordingStarted(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kConnectionReadyNotification), object: nil)
    }
    
    // Just remove Notifications when not needed
    
    func removeNotifications(){
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    // Very important, should be connected to start/stop button
    
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
    
    // OK, just we stop recording data
    
    func hasStopped(_ not : Notification){
        let img = UIImage(named: "record")
        self.fStartStopButton.setImage(img, for: UIControlState())
        self.state = connectionState.stopped
        self.navigationController!.popViewController(animated: true)
        self.headersReceived = false
    }

    
    // We have received new data, update UI
    
    func dataUpdated(_ not : Notification){
        
        
        DispatchQueue.main.async(execute: { () -> Void in
            if !(UIApplication.shared.applicationState == UIApplicationState.active) {
                return
            }

            if let cli = self.client{
                if let track = cli.datos{
                    self.prepareForUpdate(track)
                     if !track.getName().isEmpty && !self.headersReceived{
                        self.headersReceived = true
                        self.updateName(track.getName())
                    }
                    self.updateUI(track)
                }
            }
        })
    }
    
    // Connection is starting. It is a BLE connection so we turn the square till connection is finished.
    
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
    
    // Recording has started correctly. Is called when headers are OK an we have the name.
    // Just stop the square and set it filled. If needed update name
    func recordingStarted(_ not: Notification){
        
        self.state = connectionState.connected
        
        DispatchQueue.main.async(execute: { () -> Void in
            
            self.stopAnimation()
            let img = UIImage(named: "recordOn")
            self.fStartStopButton.setImage(img, for: UIControlState())
            if let cli = self.client{
                if let track = cli.datos{
                    self.updateName(track.getName())
                }
                (self.distanceCorrection, self.speedCorrection) = cli.getCorrections()

            }
        })
    }
    
    // Stop recording. Just change square button to empty
    
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
    
    
    // This function shoud update the name of the wheel in UI if there is a field for it. Dummy here
    func updateName(_ name : String){
        
        
    }
    
    // This function shoud update the UI. Is called from the main thread so no problems with that
    
    func updateUI(_ track : WheelTrack){
        
        
        
    }
    
    // This function updates the data internally off main thread
    
    func prepareForUpdate(_ track : WheelTrack){
        
    }
    
    //MARK: Navigation options
    
    // Shows a graphic of speed of last delta minutes
    
    @IBAction func showFastGraphic(){
        if let vc = GraphViewController.instantiate() as? GraphViewController {
            if let nb = self.client?.datos {
                vc.shownVariable = 0
                vc.ninebot = nb
                vc.from = fmax(nb.getLastTimeValueForVariable(.Speed) - delta * 60.0, 0.0)
                vc.enabledMagnitudeSwitch = false
                navigationController?.pushViewController(vc, animated: true)
                
            }
        }
    }
    
    @IBAction func showMapDashboard(){

        if let dash = BLEMapDashboard.instantiate() as? BLEMapDashboard{
            
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dash.client = dele.client
                navigationController?.pushViewController(dash, animated: true)
            }
        }
    }

    func showRunningSettings(){
        
        if let vc = BLENinebotSettingsViewController.instantiate() as? BLENinebotSettingsViewController{
            vc.ninebotClient = self.client
            present(vc, animated: true, completion: { 
                
                
            })
        }
        
    }
    
    
    //MARK: BLEDeviceSelectorDelegate
    
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
                
                self.devSelector = BLEDeviceSelector.instantiate() as? BLEDeviceSelector
                
                if let vc = self.devSelector{
                    self.devSelector = vc
                    vc.addDevices(self.devList)
                    vc.delegate = self
                    self.devList.removeAll()
                    self.searching = true
                    present(vc, animated: true, completion: { 
                        
                        
                    })
                }
                
                
            }
            else{
                if let vc = self.devSelector{
                    vc.addDevices(devs)
                }
                
            }
        }
    }
    
    
    // MARK: Navigation and auxiliar
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "graphSegueIdentifier" {
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
        
        if let but = fSettingsButton {
            but.isHidden = !testMode
            but.isEnabled = testMode
        }
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeNotifications()
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true

    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height{
            // self.performSegueWithIdentifier("graphSegueIdentifier", sender: self)
        }
    }
}
