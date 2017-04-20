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
    
    var startDate : Date?
    
    var log = [Exchange]()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setup()
    
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    override func viewDidLoad() {
        self.iPhoneButton.isEnabled = false
        self.ninebotButton.isEnabled = false
        
        if let dv = BLEDeviceSelector.instantiate() as? BLEDeviceSelector {
            deviceSelector = dv
            dv.delegate = self
            client.startScanning()
            present(dv, animated: true, completion: { 
                
                
            })
            
        }

    }
    
    func deviceDiscovered(_ not : Notification){
        
        if let devices  = (not as NSNotification).userInfo?["peripherals"] as? [CBPeripheral] {
            
            if let dv = deviceSelector {
                dv.addDevices(devices)
            }
        }
    }

    
    func setup(){
        
        client.delegate = self
        server.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(BLEMim.deviceDiscovered(_:)), name: NSNotification.Name(rawValue: BLESimulatedClient.kdevicesDiscoveredNotification), object: nil)
       
        
    }
    
    
    func isConnected() -> Bool{
        
        return  self.server.transmiting
        
    }
    
    func connectToClient(){
        
        // First we recover the last device and try to connect directly
        
        let store = UserDefaults.standard
        let device = store.string(forKey: BLESimulatedClient.kLast9BDeviceAccessedKey)
        
        if let dev = device {
            self.client.connectToUUID(dev)
        }
    }

    func stop(){
        
        if self.client.state == .connected{
            self.client.disconnect()
        }
        if self.server.transmiting {
            self.server.stopTransmiting()
        }
        self.startStopButton.title = "Start"
    }
    
    func start(){
        
        if self.client.state != .connected{
            self.client.startScanning()
        }
        if !self.server.transmiting{
            self.server.startTransmiting()
        }
        self.startStopButton.title = "Stop"

    
    }
    
    @IBAction func flip(_ src: AnyObject){
        
        if isConnected() {
            stop()
        }
        else{
            start()
        }
    }
    @IBAction func doSave(_ src: AnyObject){
        _ = self.save()
    }
    
    func save() -> URL?{
        
        if startDate == nil {
            startDate = Date()
        }
       
        let ldateFormatter = DateFormatter()
        let enUSPOSIXLocale = Locale(identifier: "en_US_POSIX")
        
        ldateFormatter.locale = enUSPOSIXLocale
        ldateFormatter.dateFormat = "'9B_'yyyyMMdd'_'HHmmss'.log'"
        let newName = ldateFormatter.string(from: startDate!)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        let path : String
        
        if let dele = appDelegate {
            path = (dele.applicationDocumentsDirectory()?.path)!
        }
        else
        {
            return nil
        }
        
        let tempFile = (path + "/" ) + newName
        
        
        let mgr = FileManager.default
        
        mgr.createFile(atPath: tempFile, contents: nil, attributes: nil)
        let file = URL(fileURLWithPath: tempFile)
        
        
        
        do{
            let hdl = try FileHandle(forWritingTo: file)
            // Get time of first item
            
            ldateFormatter.dateFormat = "yyyy MM dd'_'HH:mm:ss"
           
            let s = ldateFormatter.string(from: startDate!) + "\n"
            hdl.write(s.data(using: String.Encoding.utf8)!)
            
            
            for v in self.log {
                
                var s : String?
                
                if v.dir == .iphone2nb {
                    
                    s = String(format:"< %@ %@ %@\n", v.op.rawValue, v.characteristic, v.data)
                    
                }else {
                    s = String(format:"> %@ %@ %@\n", v.op.rawValue, v.characteristic, v.data)
                }
                
                if let vn = s!.data(using: String.Encoding.utf8){
                    hdl.write(vn)
                }
                
             }
            
            hdl.closeFile()
            
          return file
            
        }
        catch{
            if let dele = UIApplication.shared.delegate as? AppDelegate{
                dele.displayMessageWithTitle("Error".localized(comment: "Standard ERROR message"),format:"Error when creating file handle for %@".localized(), file as CVarArg)
            }

            AppDelegate.debugLog("Error al obtenir File Handle")
        }
        
        return nil
    }
    
    func nsdata2HexString(_ data : Data) -> String{
        
        
        let count = data.count
        var buffer = [UInt8](repeating: 0, count: count)
        (data as NSData).getBytes(&buffer, length:count * MemoryLayout<UInt8>.size)

        var out = ""
        
        for i in 0..<count {
            let str = String(format: "%02x", buffer[i])
            out.append(str)
        }
        
        return out
        
    }

}

extension BLEMim : BLEMimConnectionDelegate{

    func deviceConnected(_ peripheral : CBPeripheral, adapter: BLEWheelAdapterProtocol? ){
        if let s = peripheral.name{
            AppDelegate.debugLog("Device %@ connected", s)
            self.ninebotButton.isEnabled = true
            self.startDate = Date()
        }
    }
    func deviceDisconnected(_ peripheral : CBPeripheral ){
        if let s = peripheral.name{
            AppDelegate.debugLog("Device %@ disconnected", s)
            self.ninebotButton.isEnabled = false
            
        }
    }
    func charUpdated(_ char : CBCharacteristic, data: Data){
        self.server.updateValue(char.uuid.uuidString, data: data)
        let hexdat = self.nsdata2HexString(data)
        
        
        
        let entry = Exchange(dir: .nb2iphone, op:.update, characteristic : char.uuid.uuidString, data: hexdat)
        
        self.log.append(entry)
        self.tableView.reloadData() 

        
    }
    
    func deviceAnalyzed( _ peripheral : CBPeripheral, services : [String : BLEService]) {
        
        AppDelegate.debugLog("Device analyzed %@", peripheral)
        
        for (_, srv) in services {
            
            let entry = Exchange(dir: .nb2iphone, op:.comment, characteristic : "Service", data: srv.id)
            self.log.append(entry)
            
            AppDelegate.debugLog("Services %@", srv.id)
            
            for (_, ch) in srv.characteristics{
                
                let desc = String(format: "%@ (%@)", ch.id, ch.flags)
                let entry = Exchange(dir: .nb2iphone, op:.comment, characteristic : "    Char:", data: desc)
                self.log.append(entry)

                AppDelegate.debugLog("    Char: " + desc)
            }
        }
        
        let wheelKind = BLEWheelSelector.sharedInstance.wheelKind(wheelServices: services)
        AppDelegate.debugLog("Recognized wheel as %@", wheelKind)
        
        self.tableView.reloadData()
        
        server.services = services
        server.startTransmiting()
        
    }

}
extension BLEMim : BLENinebotServerDelegate {

    func readReceived(_ char : CBCharacteristic){
        
        self.client.readValue(char.uuid.uuidString)
        let entry = Exchange(dir: .iphone2nb, op: .read, characteristic: char.uuid.uuidString, data: "")
        self.log.append(entry)
        self.tableView.reloadData()
    }
    
    func writeReceived(_ char : CBCharacteristic, data: Data){
        self.client.writeValue(char.uuid.uuidString, data:data)

        let hexdat = self.nsdata2HexString(data)
        
        let entry = Exchange(dir: .iphone2nb, op: .write, characteristic: char.uuid.uuidString, data: hexdat)
        self.log.append(entry)
        self.tableView.reloadData()
        
    }
    func remoteDeviceSubscribedToCharacteristic(_ char : CBCharacteristic, central : CBCentral){
        
        self.client.subscribeToChar(char.uuid.uuidString)
        let entry = Exchange(dir: .iphone2nb, op: .subscribe, characteristic: char.uuid.uuidString, data: "")
        self.log.append(entry)
        self.tableView.reloadData()

        AppDelegate.debugLog("Device subscribed %@", central)
        
        
        self.iPhoneButton.isEnabled = true
    }
    func remoteDeviceUnsubscribedToCharacteristic(_ char : CBCharacteristic, central : CBCentral){
        self.client.unsubscribeToChar(char.uuid.uuidString)
        
        let entry = Exchange(dir: .iphone2nb, op: .unsubscribe, characteristic: char.uuid.uuidString, data: "")
        self.log.append(entry)
        self.tableView.reloadData()

        AppDelegate.debugLog("Device unsubscribed %@", central)
        self.iPhoneButton.isEnabled = false
    }

}

extension BLEMim : UITableViewDataSource{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.log.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logEntryCellIdentifier", for: indexPath)
        
        let entry = log[(indexPath as NSIndexPath).row]
        
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
    func connectToPeripheral(_ peripheral : CBPeripheral){
        
        self.client.connectPeripheral(peripheral)
        self.dismiss(animated: true) { 
            
            
        }
    }
    

}
