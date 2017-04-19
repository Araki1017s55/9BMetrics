//
//  BLESimulatedNinebot.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 11/3/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import CoreBluetooth

class BLESimulatedNinebot: UIViewController {
    
    @IBOutlet weak var fNinebot: UIButton!
    @IBOutlet weak var fIphone: UIButton!
    @IBOutlet weak var fMessages: UITextView!
    @IBOutlet weak var fSlider: UISlider!
    
    var url : URL?
    var ninebot : BLENinebot = BLENinebot()
    var logData : [BLENinebot.LogEntry] = Array<BLENinebot.LogEntry>()
    
    var ip = 0  // Instruction pointer
    
    var firstDate : Date?
    var startDate = Date()
    var timer : Timer?
    
    var server : BLESimulatedServer?
    
    var simulating = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cursor = UIImage(named: "9bcursor")
        self.fSlider.setThumbImage(cursor, for: UIControlState())
        // Load data file
        
        let bundle = Bundle.main
        url = bundle.url(forResource: "simulated_log", withExtension: "txt")
        if let u = url {
            self.loadURL(u)
            
            
        }
        

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.stop()
    }
    
    func startTransmitting(){
        
        if self.server == nil{
            
            self.server = BLESimulatedServer()
            self.server!.delegate = self
        }
        
        self.server!.startTransmiting()
        self.fNinebot.isEnabled = true
        
    }
    
    func loadURL(_ url : URL){
        self.ninebot.clearAll()
        self.logData.removeAll()
        do{
            
            
            let data = try String(contentsOf: url, encoding: String.Encoding.utf8)
            let lines = data.components(separatedBy: CharacterSet.newlines)
            
            for line in lines {
                let fields = line.components(separatedBy: "\t")
                
                if fields.count == 3{   // Good Data
                    
                    let time = Double(fields[0].replacingOccurrences(of: " ", with: ""))
                    let variable = Int(fields[1])
                    let value = Int(fields[2])
                    
                    if let t = time, let i = variable, let v = value {
                        
                        let date =  Date(timeIntervalSince1970: t)
                        
                        if firstDate == nil {
                            firstDate = date
                        }
 
                        let le = BLENinebot.LogEntry(time:date, variable: i, value: v)
                        logData.append(le)

                    }
                }
                
            }
            
        }catch {
            
        }
        
        
        // OK now we must sort in place logData 
        
        logData.sort { (b0 :BLENinebot.LogEntry, b1 : BLENinebot.LogEntry) -> Bool in
            return b0.time.compare(b1.time as Date) == ComparisonResult.orderedAscending
        }
        
        self.firstDate = logData[0].time as Date
        
        self.fSlider.maximumValue = Float(logData.count)
        
        
        
        // Now all is OK; we may simulate everything
    }
    
    func start(){
        
        if self.logData.count > 0{
            
            self.startTransmitting()
        }
        
    }
    
    func stop(){
        
        if let srv = self.server{
            srv.stopTransmiting()
        }
        self.fNinebot.isEnabled = false
    }
    
    func startSimulate(){
        self.simulating = true
        self.ip = 0
        self.fSlider.value = 0.0
        self.startDate = Date()
        
       // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            self.processData()
       // })

     }
    
    func stopSimulate(){
        self.simulating = false
        self.fSlider.value = 0.0
    }
    
    func processData(){
        
        if !simulating{
            return
        }
        
        var w = self.logData[ip]
        let now = Date()
        
        while w.time.timeIntervalSince(self.firstDate!) < now.timeIntervalSince(self.startDate){
            
            
            self.ninebot.addValueWithDate(now, variable: w.variable, value: w.value)
            
            self.ip += 1
            
            if ip == self.logData.count{
               // self.startDate = now
                ip = 0
            }
            self.fSlider.value = Float(ip)

            w = self.logData[ip]
         }
        
        w = self.logData[ip]
        var ti = w.time.timeIntervalSince(self.firstDate!) - now.timeIntervalSince(self.startDate)
        
        if ti < 0 {
            ti = 0.01
        }
        
        self.timer = Timer.scheduledTimer(timeInterval: ti, target: self, selector: #selector(BLESimulatedNinebot.processData), userInfo: nil, repeats: false)
    }
    
    
    func getVariable(_ variable : Int) -> Int{
        return self.ninebot.currentValueForVariable(variable)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension BLESimulatedNinebot : BLENinebotServerDelegate{
    
    
    
    
    func remoteDeviceSubscribedToCharacteristic(_ characteristic : CBCharacteristic, central : CBCentral){
        
        DispatchQueue.main.async(execute: { () -> Void in
            self.fMessages.text = self.fMessages.text + String(format: "Device %@ subscribed.\n", central.identifier.uuidString)
        })

        
        self.startSimulate()
        self.fIphone.isEnabled = true
        
        
    }
    
    func remoteDeviceUnsubscribedToCharacteristic(_ characteristic : CBCharacteristic, central : CBCentral){
 
        self.fMessages.text = self.fMessages.text + String(format: "Device %@ unsubscribed.\n", central.identifier.uuidString)

        self.stopSimulate()
        self.fIphone.isEnabled = false
        
    }
    //TODO: Seria interessant canviar les nostres variables per les que fa servir Ninebot per compat
    func readReceived(_ char: CBCharacteristic) {
        
        
    }
    
    func writeReceived(_ char : CBCharacteristic, data: Data){
        
        if let msg = BLENinebotMessage(data: data , fixed: 0x09){
        
            let v = msg.command // Primera variable
            let l = msg.data[0] // Número de variables * 2
            let n = l/2         // Numero de variables a enviar
            
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.fMessages.text = self.fMessages.text + String(format:"< v[%d] - v[%d]\n", v, v+n);
//            })
//            
            var buff : [UInt8] = [UInt8]()
            
            for i in 0..<n{
                
                var j  = UInt8(0)
                
                switch i+v {
                    
                case 180:
                    j = 34
                    
                case 181:
                    j = 38
                    
                case 187:
                    j = 62
                    
                case 188:
                    j = 71
                    
        
                    
                default :
                    j = i+v
                }
                
                var value = self.ninebot.currentValueForVariable(Int(j))
                //                let vx = value
                
            

                if self.ninebot.signed[Int(j)]{
                    if value < 0 {
                        value = value + 65536
                    }
                }else if value == -1{
                    value = 0
                 }
                
                if j == 115 {
                    value = 20000
                }else if j == 116{
                    value = 10000
                }
                
                let v1 = UInt8(value / 256)
                let v0 = UInt8(value % 256)
                               
                
                buff.append(v0)
                buff.append(v1)
                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.fMessages.text = self.fMessages.text + String(format:"> %@[%d] = %02x%02x (%d)\n", BLENinebot.labels[Int(j)]  ,j,v0, v1, vx);
//                })

            }
            
            let answer = BLENinebotMessage(com: v, dat: buff, fixed: 0x09)
            
            if let dat = answer?.toNSData(){
                
                self.server!.updateValue(dat)

            }
        }
    }
    
}
