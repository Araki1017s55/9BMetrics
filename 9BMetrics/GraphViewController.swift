//
//  GraphViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 9/2/16.
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

class GraphViewController: UIViewController, TMKGraphViewDataSource {
    
    @IBOutlet weak var graphView : TMKGraphView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var fDataView: UIView!
   // weak var delegate : BLENinebotDashboard?
    @IBOutlet weak var fVariableName: UILabel!
    @IBOutlet weak var fAverageValue: UILabel!
    @IBOutlet weak var fExtremeValues: UILabel!
    @IBOutlet weak var fNumberOfValues: UILabel!
    
    weak var ninebot : WheelTrack?
    var shownVariable = 0
    let displayableVariables : [WheelTrack.WheelValue] = [.Speed, .Temperature,
                                                      .Voltage, .Current, .Battery, .Pitch, .Roll,
                                                      .Distance, .Altitude, .Power, .Energy]
  
    let scales : [Double] = [3.6, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.001, 1.0, 1.0, 1.0 / 3600.0]
        
    let units : [String] = ["km/h", "ºC", "V", "A", "%", "º", "º", "km", "m", "v"  , "wh"]
    

    var resampledLog : [WheelTrack.LogEntry]?
    var step = 0.1


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.hidden = true
        self.graphView.yValue = shownVariable
        self.buildLog(shownVariable)
        self.graphView.setup()
        
      
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.updateStats()
            self.graphView.setNeedsDisplay()
        })
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func updateStats(){
        if self.ninebot != nil{
            
            fVariableName.text = nameOfValue(shownVariable)
            let (minv, maxv, avgv, _) = getLogStats(shownVariable, from: 0.0, to: 86400.0)
            
            fAverageValue.text = String(format:"Average Value : %0.2f", avgv)
            fExtremeValues.text = String(format:"Minimum : %0.2f Maximum : %0.2f", minv, maxv)
            fNumberOfValues.text = String(format:"Samples %d", numberOfPointsForSerie(0, value: shownVariable))
            
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            if size.width > size.height{
                // graphToShow = graphValue[0]
                // self.performSegueWithIdentifier("graphicSegue", sender: self)
                
                bottomConstraint.constant = 0.0
                
                
            } else {
                bottomConstraint.constant = fDataView.bounds.size.height
        }
        
    }
    
    
    // MARK: TMKGraphViewDataSource
    
    func valueForSerie(serie : Int, value : Int) -> Int{
        
        switch serie {
        case 1:
            return 3
        case 2:
            return 5
        default:
            return value
        }
     }
    
    func numberOfSeries() -> Int{
        return 1 //  Put 3 but for the moment too slow
    }
    func numberOfPointsForSerie(serie : Int, value: Int) -> Int{
        
        let val = valueForSerie(serie, value: value)
         
        if self.ninebot != nil{
            return countLog(val)
        }
        else{
            return 0
        }
    }
    func styleForSerie(serie : Int) -> Int{
        return 0
    }
    func colorForSerie(serie : Int) -> UIColor{
        
        switch  serie {
        case 1:
            return UIColor.greenColor()
        case 2:
            return UIColor.cyanColor()
        default:
            return UIColor.redColor()
        }
        
    }
    func offsetForSerie(serie : Int) -> CGPoint{
        return CGPoint(x: 0, y: 0)
    }
    
    func value(value : Int, axis: Int,  forPoint point: Int,  forSerie serie:Int) -> CGPoint{
        
        let val = valueForSerie(serie, value: value)
        if self.ninebot != nil{

            let v = getLogValue(val, index: point)
            let t = getTimeValue(val, index: point)
            return CGPoint(x: CGFloat(t), y:CGFloat(v) )
        }
        else{
            return CGPoint(x: 0, y: 0)
        }
    
    }
    
    func value(value : Int, axis: Int,  forX x:CGFloat,  forSerie serie:Int) -> CGPoint{
 
        let val = valueForSerie(serie, value: value)
        if self.ninebot != nil{
            
            let v = getLogValue(val, time: NSTimeInterval(x))
            return CGPoint(x: x, y:CGFloat(v))
            
        }else{
            return CGPoint(x: x, y: 0.0)
        }
      }

    func numberOfWaypointsForSerie(serie: Int) -> Int{
            return 0
     
    }
    func valueForWaypoint(point : Int,  axis:Int,  serie: Int) -> CGPoint{
        return CGPoint(x: 0, y: 0)
    }
    func isSelectedWaypoint(point: Int, forSerie serie:Int) -> Bool{
        return false
    }
    func isSelectedSerie(serie: Int) -> Bool{
        return serie == 0
     }
    func numberOfXAxis() -> Int {
        return 1
    }
    func nameOfXAxis(axis: Int) -> String{
        return "t"
    }
    func numberOfValues() -> Int{
        return BLENinebot.displayableVariables.count
    }
    func nameOfValue(value: Int) -> String{
        return displayableVariables[value].rawValue
    }
    func numberOfPins() -> Int{
        return 0
    }
    func valueForPin(point:Int, axis:Int) -> CGPoint{
        return CGPoint(x: 0, y: 0)
    }
    func isSelectedPin(pin: Int) -> Bool{
        return false
    }
    
    func statsForSerie(value: Int, from t0: NSTimeInterval, to t1: NSTimeInterval) -> String{
        
        if self.ninebot != nil{
            
            let (min, max, avg, acum) = getLogStats(value, from: t0, to: t1)
            let (h, m, s) = BLENinebot.HMSfromSeconds(t1 - t0)
            
            var answer = String(format: "%02d:%02d:%02d",  h, m, s)
            
            switch value {
                
            case 0: // Speed
                
                let dist = acum / 3600.0
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f Dist: %4.2f Km", min, avg, max, dist))
                
            case 1: //T
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f", min, avg, max))
                
            case 2:                 // Voltage
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f", min, avg, max))
                
            case 3:                 // Current
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f Q: %4.2fC", min, avg, max, acum))
                
            case 4:     //Battery
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f", min, avg, max))
                
            case 5:     // Pitch
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f", min, avg, max))
                
            case 6:     //Roll
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f", min, avg, max))
                
            case 7:     //Distance
                answer.appendContentsOf(String(format:" Dist: %4.2f Km ", max - min))
                
            case 8:     //Altitude
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f", min, avg, max))
                
            case 9:     //Power
                let wh = acum / 3600.0
                answer.appendContentsOf(String(format:" Min: %4.2f  Avg: %4.2f  Max: %4.2f W: %4.2f wh", min, avg, max, wh))
                
            case 10:     //Energy
                answer.appendContentsOf(String(format:" Energy: %4.2f wh ", max - min))

                
                
            default:
                answer.appendContentsOf(" ")
                
            }
              return answer
            
        }else{
            return ""
        }
    }
    
    func minMaxForSerie(serie : Int, value: Int) -> (CGFloat, CGFloat){
        
        let val = valueForSerie(serie, value: value)
        
        switch(val){
            
        case 0:
            return (0.0, 1.0)   // Speed
            
        case 1:
            return (15.0, 20.0) // T
            
        case 2:                 // Voltage
            return (50.0, 60.0)
            
        case 3:                 // Current
            return  (-1.0, 1.0)
            
        case 4:
            return (0.0, 100.0) // Battery
            
        case 5:
            return (-1.0, 1.0)  // Pitch
            
        case 6:
            return (-1.0, 1.0)  //  Roll
            
        case 7:
            return (0.0, 0.5)   // Distance
            
        case 8:
            return (-10.0,10.0)   // Altitude
        
        case 9:
            return (-50.0, +50.0) // Power
            
            
        default:
            return (0.0, 0.0)
            
            
            
        }
        
        
        
    }
    
    func doGearActionFrom(from: Double, to: Double, src: AnyObject){
        var url : NSURL?
        
        if let nb = self.ninebot{
            url = nb.createCSVFileFrom(from, to: to)
        }
        
        
        if let u = url {
            self.shareData(u, src: src, delete: true)
        }
          
        // Export all selected data to a file
    }
    
    // Create a file with actual data and share it
    
    func shareData(file: NSURL?, src:AnyObject, delete: Bool){
        
        if let aFile = file {
            let activityViewController = UIActivityViewController(
                activityItems: [aFile.lastPathComponent!,   aFile],
                applicationActivities: [PickerActivity()])
            
            activityViewController.completionWithItemsHandler = {(a : String?, completed:Bool, objects:[AnyObject]?, error:NSError?) in
                
                if delete {
                    do{
                        try NSFileManager.defaultManager().removeItemAtURL(aFile)
                    }catch{
                        AppDelegate.debugLog("Error al esborrar %@", aFile)
                    }
                }
            }
            
            activityViewController.popoverPresentationController?.sourceView = src as? UIView
            
            activityViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            
            self.presentViewController(activityViewController,
                animated: true,
                completion: nil)
        }
    }
    
    //MARK: Log Management
    
    func buildLog(variable : Int){
        
        if shownVariable == variable && resampledLog != nil {
            return
        }
        
        let v = displayableVariables[variable]
        
    
        if let nb = self.ninebot{
            let t = nb.getLastTimeValueForVariable(v)
            step = t / 2000.0
            
            if step == 0.0 {
                resampledLog = nil
            }else{
                resampledLog = nb.resample(v, from: 0.0, to: t, step: step)    // Will update with othe data
            }
            shownVariable = variable
        }
    }
    
    func countLog(variable : Int) -> Int{
        buildLog(variable)
        
        if let log = resampledLog {
            return log.count
        }else{
            return 0        }
        
    }

    
    func getLogValue(variable : Int, time : NSTimeInterval) -> Double{
        buildLog(variable)
 
        if resampledLog == nil{
            return 0.0
        }
        let i = Int(round(time / step))
        
        if let log = resampledLog where log.count > i{
            return log[i].value * scales[variable]
        }else{
            return 0.0
        }
        
    }
    
    func getLogValuex(variable : Int, time : NSTimeInterval) -> Double{
        
        
        
        if variable >= 0 && variable < displayableVariables.count{
            if let nb = self.ninebot{
                return nb.getValueForVariable(displayableVariables[variable], time: time)
            }else{
                return 0.0
            }
            
        }else{
            return 0.0
        }
    }
    
    
    func getLogStats(variable : Int, from t0 : NSTimeInterval, to t1 : NSTimeInterval) -> (Double, Double, Double, Double){
        buildLog(variable)
        
        if variable >= 0 && variable < displayableVariables.count{
            if let nb = self.ninebot{
                let (m0, m1, av, ii) = nb.stats(displayableVariables[variable], from: t0, to: t1)
                let s = scales[variable]
                return (m0 * s, m1*s, av*s, ii*s)
  
            }else{
                return (0.0, 0.0, 0.0, 0.0)
            }

        } else {
            return (0.0, 0.0, 0.0, 0.0)
        }
    }
    
    func getLogValue(variable : Int, index : Int) -> Double{
        buildLog(variable)
        
        if let log = resampledLog where log.count > index{
            return log[index].value * scales[variable]
        }else{
            return 0.0
        }
    }
    
    func getTimeValue(variable : Int, index : Int) -> Double{
        buildLog(variable)
        
        if let log = resampledLog where log.count > index{
            return log[index].timestamp
        }else{
            return 0.0
        }
    }
    
        
        func getLogValuex(variable : Int, index : Int) -> Double{
       
        
        if variable >= 0 && variable < displayableVariables.count{
            if let nb = self.ninebot{
                return nb.getValueForVariable(displayableVariables[variable], atPoint: index)
            }else{
                return 0.0
            }
        }else{
            return 0.0
        }
    }

    
 }
