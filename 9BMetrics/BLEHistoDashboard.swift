//
//  BLEHistoDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 22/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class BLEHistoDashboard: UIViewController {

    weak var ninebot : BLENinebot?
    
    var titulo = ""
    var dist = 0.0
    var ascent = 0.0
    var descent = 0.0
    var time = 0.0
    var avgSpeed = 0.0
    var maxSpeed = 0.0
    var bat0 = 0.0
    var bat1 = 0.0
    var batMin = 0.0
    var batMax = 0.0
    var energy = 0.0
    var batEnergy = 0.0
    var currMax = 0.0
    var currAvg = 0.0
    var pwMax = 0.0
    var pwAvg = 0.0
    var tmin = 0.0
    var tmax = 0.0
    var tavg = 0.0
    var pmin = 0.0
    var pmax = 0.0
    var pavg = 0.0
    var rmin = 0.0
    var rmax = 0.0
    var ravg = 0.0
    var eplus = 0.0
    var erec = 0.0
    var trackImg : UIImage?
    
    let defaultTopSpeed = 30.0
    let secureSpeed = 23.0
    
    @IBOutlet  weak var collectionView : UICollectionView!
    @IBOutlet weak var fTitle : UILabel!
    
    private let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)

    static var displayableVariables : [Int] = [BLENinebot.kCurrentSpeed, BLENinebot.kTemperature,
                                               BLENinebot.kVoltage, BLENinebot.kCurrent, BLENinebot.kBattery, BLENinebot.kPitchAngle, BLENinebot.kRollAngle,
                                               BLENinebot.kvSingleMileage, BLENinebot.kAltitude, BLENinebot.kPower, BLENinebot.kEnergy]
    
    
    private let graphValue = [0, 4, 9, 10, 1, 6, 5]
    
    var graphToShow : Int = 0
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        fTitle.text = titulo
        
        if let nb = self.ninebot {
             (dist, ascent, descent, time, avgSpeed, maxSpeed) = nb.analCinematics()
             (bat0, bat1, batMin, batMax, energy, batEnergy, currMax, currAvg, pwMax, pwAvg) = nb.analEnergy()
             (tmin, tmax, tavg, _) = nb.temperature(from: 0.0, to: 86400.0)
             (pmin, pmax, pavg, _) = nb.pitch(from: 0.0, to: 86400.0)
             (rmin, rmax, ravg, _) = nb.roll(from: 0.0, to: 86400.0)
            
             (eplus, erec) = nb.energyDetails(from: 0.0, to: 86400.0)
            trackImg = nb.imageWithWidth(350.0,  height:350.0, color:UIColor.yellowColor(), backColor:UIColor.clearColor(), lineWidth: 2.0)
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.collectionView.performBatchUpdates(nil, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.hidden = true
    }
    
    @IBAction func goBack(src : AnyObject){
        self.navigationController?.popViewControllerAnimated(true)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
            
            case "otherMapSegue":
                  if let vc = segue.destinationViewController as? BLEMapViewController  {
                    vc.dades = self.ninebot
            }
            
        case "graphicSegue":

            if let vc = segue.destinationViewController as? GraphViewController  {
                
                if let nb = self.ninebot{
                    nb.buildEnergy()
                }
                vc.ninebot = self.ninebot
                vc.shownVariable = self.graphToShow
            }
            
        default:
            break
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue){
        
        self.dismissViewControllerAnimated(true) {
            
        }
        
    }
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height{
            graphToShow = graphValue[0]
            self.performSegueWithIdentifier("graphicSegue", sender: self)
        }
    }
}

extension BLEHistoDashboard : UICollectionViewDelegateFlowLayout{
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        
        let vbounds = collectionView.bounds
        let vsize = vbounds.size
        
        var s = CGFloat(150.0)
        var s1 = CGFloat(0.0)
        
       if vsize.height > vsize.width {
            
            var w = Double(vsize.width / 2.0) - 5.0
            var h = Double(vsize.height / 3.0) - 10.0
            
            s = CGFloat(min(w, h))

            w = Double(vsize.width / 3.0) - 10.0
            h = Double(vsize.height / 3.0) - 10.0
        
            s1 = CGFloat(min(w, h))
        
        
        }else {
            let h = Double(vsize.width / 4.0) - 15.0
            let w = Double(vsize.height / 2.0) - 5.0
            
            s = CGFloat(min(w, h)) - 20.0
        
            s1 = s
        }

        
        let row = indexPath.row
        switch row {
            
        case 0...3:
            return CGSize(width: s, height: s+20.0)
        
        
        case 4...6:
            return CGSize(width: s1, height :s1 + 20.0)
        
        
        default:
            return CGSize(width: 100.0, height : 120.0)
        }
        
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    
}
extension BLEHistoDashboard : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let row = indexPath.row
        
        switch row {
            
        case 0: // Speed/map , open Map
            performSegueWithIdentifier("otherMapSegue", sender: self)
            
            
        default:
            graphToShow = self.graphValue[row]
            
            performSegueWithIdentifier("graphicSegue", sender: self)
            
            
        }
    }
    
    
}

extension BLEHistoDashboard : UICollectionViewDataSource{
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        switch indexPath.row {
            
        case 0:
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            var speedView : TMKClockView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKClockView){
                    speedView = v as? TMKClockView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            if let tit = title {
                tit.text = "Speed"
            }
            
            
            var topSpeed = defaultTopSpeed
            if maxSpeed > defaultTopSpeed {
                topSpeed = ceil(maxSpeed / 10.0) * 10.0
            }
            
            if let sv = speedView {
                var limits = [TMKClockView.arc(start: 0.0, end: 23.0/topSpeed, color: UIColor.greenColor())]
                
                if maxSpeed > secureSpeed{
                    limits.append( TMKClockView.arc(start: 23.0/topSpeed, end: maxSpeed / topSpeed, color: UIColor.redColor()))
                    
                }
                
                
                let speeds : [TMKClockView.arc] = [TMKClockView.arc(start: avgSpeed / topSpeed, end: 0.5, color: UIColor.greenColor()), TMKClockView.arc(start: maxSpeed / topSpeed, end: 0.9, color: UIColor.redColor())]
                
                sv.backImage = self.trackImg
                
                
                sv.updateData(String(format:"%0.2f", dist) , units: "Km", radis: speeds, arcs: limits, minValue: 0.0, maxValue: topSpeed)
            }
            return cell
            
        case 1:
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)

            var batteryView : TMKClockView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKClockView){
                    batteryView = v as? TMKClockView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            
            if let tit = title {
                tit.text = "Battery"
            }
            
            if let bv = batteryView{

                var batAreas : [TMKClockView.arc] = []
                
                if batMin < 20.0 && batMax <= 20.0 {
                    batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: batMax/100.0, color: UIColor.redColor()))
                }else if batMin < 20.0 && batMax > 20.0 {
                    batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: 20.0/100.0, color: UIColor.redColor()))
                    batAreas.append(TMKClockView.arc(start: 20.0 / 100.0, end: batMax/100.0, color: UIColor.greenColor()))
                }else {
                    batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: batMax/100.0, color: UIColor.greenColor()))
                }
                
                let batLevels : [TMKClockView.arc] = [TMKClockView.arc(start: bat0 / 100.0, end: 0.5, color: UIColor.greenColor()),
                                                      TMKClockView.arc(start: bat1 / 100.0, end: 0.9, color: UIColor.redColor())]
                
                bv.backImage = nil
                
                bv.updateData(String(format:"%0.0f", (bat0 - bat1)) , units: "%", radis: batLevels, arcs: batAreas, minValue: 0.0, maxValue: 100.0)
            }
            
            return cell

        case 2:
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            
            var powerView : TMKClockView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKClockView){
                    powerView = v as? TMKClockView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            
            if let tit = title {
                tit.text = "Power"
            }
            if let pw = powerView{

                let pwCont = 500.0
                let pwPeak = 1000.0
                
                let pwRange = ceil(max(pwMax, 1500.0) / 100.0) * 100.0
                var pwAreas : [TMKClockView.arc] = []
                
                pwAreas.append(TMKClockView.arc(start: 0.0 / pwRange, end:min(pwMax, pwCont) / pwRange, color: UIColor.greenColor()))
                
                if pwMax > pwCont {
                    pwAreas.append(TMKClockView.arc(start: pwCont / pwRange, end:min(pwMax, pwPeak) / pwRange, color: UIColor.orangeColor()))
                }
                
                if pwMax > pwPeak {
                    pwAreas.append(TMKClockView.arc(start: pwPeak / pwRange, end:pwMax / pwRange, color: UIColor.redColor()))
                }
                
                let pwLevels : [TMKClockView.arc] = [TMKClockView.arc(start: pwAvg / pwRange, end: 0.5, color: UIColor.greenColor()),
                                                     TMKClockView.arc(start: pwMax / pwRange, end: 0.9, color: UIColor.redColor())]
                
                pw.backImage = nil
               
                pw.updateData(String(format:"%0.0f", pwMax) , units: "w", radis: pwLevels, arcs: pwAreas, minValue: 0.0, maxValue: pwRange / 100.0)
            }
            
            return cell
            
        case 3:
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            var energyView : TMKClockView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKClockView){
                    energyView = v as? TMKClockView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            
            if let tit = title {
                tit.text = "Energy"
            }
            if let ew = energyView{

            // Energy  eplus / erec
            
            
                var eAreas : [TMKClockView.arc] = []
                
                let emax = eplus
                
                eAreas.append(TMKClockView.arc(start: 0.0, end: (eplus-erec) / emax, color: UIColor.greenColor()))
                
                eAreas.append(TMKClockView.arc(start: (eplus-erec) / emax, end: eplus/emax, color: UIColor.redColor()))
                
                let eLevels =  [TMKClockView.arc(start: (eplus-erec) / emax, end: 0.5, color: UIColor.greenColor()),
                                TMKClockView.arc(start: eplus/emax, end: 0.9, color: UIColor.redColor())]
                
                ew.backImage = nil

                ew.updateData(String(format:"%0.0f", eplus-erec) , units: "wh", radis: eLevels, arcs: eAreas, minValue: 0.0, maxValue: emax)
            }
            
            return cell
            
        case 4:
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            
            var tempView : TMKClockView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKClockView){
                    tempView = v as? TMKClockView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            
            if let tit = title {
                tit.text = "T ºC"
            }
            
            // Temperature
            //
            //  let's say ti 60ºC is OK
            // maxT = 90
            // minT = 0
            
            if let tw = tempView{
                let tempOk = 60.0
                
                let tempRange = ceil(max(tmax, 60.0) / 10.0) * 10.0
                var tempAreas : [TMKClockView.arc] = []
                
                if tmin < tempOk {
                    tempAreas.append(TMKClockView.arc(start: tmin / tempRange, end:min(tmax, tempOk) / tempRange, color: UIColor.greenColor()))
                }
                
                if tmax > tempOk{
                    tempAreas.append(TMKClockView.arc(start: max(tmin, tempOk) / tempRange, end:tmax / tempRange, color: UIColor.redColor()))
                }
                
                
                let tempLevels : [TMKClockView.arc] = [TMKClockView.arc(start: tavg / tempRange, end: 0.5, color: UIColor.greenColor()),
                                                       TMKClockView.arc(start: tmax / tempRange, end: 0.9, color: UIColor.redColor())]
                
                
                tw.backImage = nil
                
                tw.updateData(String(format:"%0.0f", tmax) , units: "ºC", radis: tempLevels, arcs: tempAreas, minValue: 0.0, maxValue: tempRange)
            }
            
            return cell
            
        case 5:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("verticalCellIdentifier", forIndexPath: indexPath)

            var rollView : TMKVerticalView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKVerticalView){
                    rollView = v as? TMKVerticalView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            
            if let tit = title {
                tit.text = "Roll"
            }
            if let rw = rollView{
  
                rw.updateData(ravg, minValue: rmin, maxValue: rmax, scale: 1.0)
            }
            
            return cell

            
        case 6:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("levelCellIdentifier", forIndexPath: indexPath)
            
            var pitchView : TMKLevelView?
            var title : UILabel?
            
            for v in cell.contentView.subviews{
                if v.isKindOfClass(TMKLevelView){
                    pitchView = v as? TMKLevelView
                } else if v.isKindOfClass(UILabel){
                    title = v as? UILabel
                }
            }
            
            if let tit = title {
                tit.text = "Pitch"
            }
            if let pw = pitchView{
                pw.updateData(pavg, minValue: pmin, maxValue: pmax, scale: 1.0)

            }
            return cell
           
            
          
        default:
            
            return UICollectionViewCell()
            
            
            
        }
        
    }
    
}
