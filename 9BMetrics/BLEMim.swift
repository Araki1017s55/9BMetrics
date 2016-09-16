//
//  BLEMim.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 15/2/16.
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
import CoreBluetooth

class BLEMim: UIViewController {
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var startStopButton : UIBarButtonItem!
    @IBOutlet weak var ninebotButton : UIButton!
    @IBOutlet weak var iPhoneButton : UIButton!
    
    var deviceSelector : BLEDeviceSelector?
    
    
    enum Direction : Int {
        case nb2iphone = 0
        case iphone2nb
    }
    
    enum Op : String {
        case read = "r"
        case write = "w"
        case update = "d"
        case subscribe = "s"
        case unsubscribe = "u"
        case comment = "c"
    }
    
    struct Exchange {
        var dir : Direction = .nb2iphone
        var op : Op = .read
        var characteristic : String = ""
        var data : String = ""
    }
    
    let client : BLEMimConnection = BLEMimConnection()
    let server : BLEMimServer = BLEMimServer()
    
    var startDate : NSDate?
    
    var log = [Exchange]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup()
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    override func viewDidLoad() {
        self.iPhoneButton.enabled = false
        self.ninebotButton.enabled = false
        
        performSegueWithIdentifier("debugDeviceSelector", sender: self)
    }
    
    func deviceDiscovered(not : NSNotification){
        
        if let devices  = not.userInfo?["peripherals"] as? [CBPeripheral] {
            
            if let dv = deviceSelector {
                dv.addDevices(devices)
            }
        }
    }

    
    func setup(){
        
        client.delegate = self
        server.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BLEMim.deviceDiscovered(_:)), name: BLESimulatedClient.kdevicesDiscoveredNotification, object: nil)
       
        
    }
    
    
    func isConnected() -> Bool{
        
        return  self.server.transmiting
        
    }
    
    func connectToClient(){
        
        // First we recover the last device and try to connect directly
        
        let store = NSUserDefaults.standardUserDefaults()
        let device = store.stringForKey(BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let dev = device {
            self.client.connectToDeviceWithUUID(dev)
        }
    }

    func stop(){
        
        if self.client.connected{
            self.client.stopConnection()
        }
        if self.server.transmiting {
            self.server.stopTransmiting()
        }
        self.startStopButton.title = "Start"
    }
    
    func start(){
        
        if !self.client.connected {
            self.connectToClient()
        }
        if !self.server.transmiting{
            self.server.startTransmiting()
        }
        self.startStopButton.title = "Stop"

    
    }
    
    @IBAction func flip(src: AnyObject){
        
        if isConnected() {
            stop()
        }
        else{
            start()
        }
    }
    @IBAction func doSave(src: AnyObject){
        _ = self.save()
    }
    
    func save() -> NSURL?{
        
        if startDate == nil {
            startDate = NSDate()
        }
       
        let ldateFormatter = NSDateFormatter()
        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'9B_'yyyyMMdd'_'HHmmss'.log'"
        let newName = ldateFormatter.stringFromDate(startDate!)
        
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        let path : String
        
        if let dele = appDelegate {
            path = (dele.applicationDocumentsDirectory()?.path)!
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ).stringByAppendingString(newName )
        
        
        let mgr = NSFileManager.defaultManager()
        
        mgr.createFileAtPath(tempFile, contents: nil, attributes: nil)
        let file = NSURL.fileURLWithPath(tempFile)
        
        
        
        do{
            let hdl = try NSFileHandle(forWritingToURL: file)
            // Get time of first item
            
            ldateFormatter.dateFormat = "yyyy MM dd'_'HH:mm:ss"
           
            let s = ldateFormatter.stringFromDate(startDate!) + "\n"
            hdl.writeData(s.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            
            for v in self.log {
                
                var s : String?
                
                if v.dir == .iphone2nb {
                    
                    s = String(format:"< %@ %@ %@\n", v.op.rawValue, v.characteristic, v.data)
                    
                }else {
                    s = String(format:"> %@ %@ %@\n", v.op.rawValue, v.characteristic, v.data)
                }
                
                if let vn = s!.dataUsingEncoding(NSUTF8StringEncoding){
                    hdl.writeData(vn)
                }
                
             }
            
            hdl.closeFile()
            
          return file
            
        }
        catch{
            if let dele = UIApplication.sharedApplication().delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error",format:"Error when creating file handle for %@", file)
            }

            AppDelegate.debugLog("Error al obtenir File Handle")
        }
        
        return nil
    }
    
    func nsdata2HexString(data : NSData) -> String{
        
        
        let count = data.length
        var buffer = [UInt8](count: count, repeatedValue: 0)
        data.getBytes(&buffer, length:count * sizeof(UInt8))

        var out = ""
        
        for i in 0..<count {
            let str = String(format: "%02x", buffer[i])
            out.appendContentsOf(str)
        }
        
        return out
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "debugDeviceSelector" {
            
            if let dv = segue.destinationViewController as? BLEDeviceSelector {
                deviceSelector = dv
                dv.delegate = self
                client.doRealScan()

            }
            
        }
    }

}

extension BLEMim : BLEMimConnectionDelegate{

    func deviceConnected(peripheral : CBPeripheral, adapter: BLEWheelAdapterProtocol ){
        if let s = peripheral.name{
            AppDelegate.debugLog("Device %@ connected", s)
            self.ninebotButton.enabled = true
            self.startDate = NSDate()
        }
    }
    func deviceDisconnected(peripheral : CBPeripheral ){
        if let s = peripheral.name{
            AppDelegate.debugLog("Device %@ disconnected", s)
            self.ninebotButton.enabled = false
            
        }
    }
    func charUpdated(char : CBCharacteristic, data: NSData){
        self.server.updateValue(char.UUID.UUIDString, data: data)
        let hexdat = self.nsdata2HexString(data)
        
        
        
        let entry = Exchange(dir: .nb2iphone, op:.update, characteristic : char.UUID.UUIDString, data: hexdat)
        
        self.log.append(entry)
        self.tableView.reloadData() 

        
    }
    
    func deviceAnalyzed( peripheral : CBPeripheral, services : [String : BLEService]) {
        
        AppDelegate.debugLog("Device analyzed %@", peripheral)
        
        for (_, srv) in services {
            AppDelegate.debugLog("Services %@", srv.id)
            
            for (_, ch) in srv.characteristics{
                AppDelegate.debugLog("    Char  %@ (%@)",ch.id, ch.flags)
            }
        }
        
        server.services = services
        server.startTransmiting()
        
    }

}
extension BLEMim : BLENinebotServerDelegate {

    func readReceived(char : CBCharacteristic){
        
        self.client.readValue(char)
        let entry = Exchange(dir: .iphone2nb, op: .read, characteristic: char.UUID.UUIDString, data: "")
        self.log.append(entry)
        self.tableView.reloadData()
    }
    
    func writeReceived(char : CBCharacteristic, data: NSData){
        self.client.writeValue(char, data:data)

        let hexdat = self.nsdata2HexString(data)
        
        let entry = Exchange(dir: .iphone2nb, op: .write, characteristic: char.UUID.UUIDString, data: hexdat)
        self.log.append(entry)
        self.tableView.reloadData()
        
    }
    func remoteDeviceSubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral){
        
        self.client.subscribeToChar(characteristic)
        let entry = Exchange(dir: .iphone2nb, op: .subscribe, characteristic: characteristic.UUID.UUIDString, data: "")
        self.log.append(entry)
        self.tableView.reloadData()

        AppDelegate.debugLog("Device subscribed %@", central)
        
        
        self.iPhoneButton.enabled = true
    }
    func remoteDeviceUnsubscribedToCharacteristic(characteristic : CBCharacteristic, central : CBCentral){
        self.client.unsubscribeToChar(characteristic)
        
        let entry = Exchange(dir: .iphone2nb, op: .unsubscribe, characteristic: characteristic.UUID.UUIDString, data: "")
        self.log.append(entry)
        self.tableView.reloadData()

        AppDelegate.debugLog("Device unsubscribed %@", central)
        self.iPhoneButton.enabled = false
    }

}

extension BLEMim : UITableViewDataSource{
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.log.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("logEntryCellIdentifier", forIndexPath: indexPath)
        
        let entry = log[indexPath.row]
        
        let img : UIImage?
        
        if entry.dir == .nb2iphone{
            img = UIImage(named: "9b2iPhone")
        }
        else{
            img = UIImage(named: "iPhone29b")
        }
        
        
        if let iv = cell.imageView  {
            iv.image = img
        }
        
        
        
        cell.textLabel!.text = entry.op.rawValue + " - " +    entry.data
        cell.detailTextLabel!.text = entry.characteristic
        
        return cell
    }
    
}

extension BLEMim : BLEDeviceSelectorDelegate {
    func connectToPeripheral(peripheral : CBPeripheral){
        
        self.client.connectPeripheral(peripheral)
        self.dismissViewControllerAnimated(true) { 
            
            
        }
    }
    

}