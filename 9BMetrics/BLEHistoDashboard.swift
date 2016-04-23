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
    
    let topSpeed = 30.0
    let secureSpeed = 23.0
    
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
       
        
        if let nb = self.ninebot {
             (dist, ascent, descent, time, avgSpeed, maxSpeed) = nb.analCinematics()
             (bat0, bat1, batMin, batMax, energy, batEnergy, currMax, currAvg, pwMax, pwAvg) = nb.analEnergy()
             (tmin, tmax, tavg, _) = nb.temperature(from: 0.0, to: 86400.0)
             (pmin, pmax, pavg, _) = nb.pitch(from: 0.0, to: 86400.0)
             (rmin, rmax, ravg, _) = nb.roll(from: 0.0, to: 86400.0)
            
             (eplus, erec) = nb.energyDetails(from: 0.0, to: 86400.0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

extension BLEHistoDashboard : UICollectionViewDelegateFlowLayout{
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let row = indexPath.row
        switch row {
            
        case 0...3:
            return CGSize(width: 155.0, height: 155.0)
        
        
        case 4...6:
            return CGSize(width: 100.0, height : 100.0)
        
        
        default:
            return CGSize(width: 100.0, height : 100.0)
        }
        
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return sectionInsets
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
            
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            var speedView = TMKClockView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))
            cell.contentView.addSubview(speedView)
            
            var limits = [TMKClockView.arc(start: 0.0, end: 23.0/30.0, color: UIColor.greenColor())]
            
            if maxSpeed > secureSpeed{
                limits.append( TMKClockView.arc(start: 23.0/30.0, end: maxSpeed / 30.0, color: UIColor.redColor()))
                
            }
            
            
            let speeds : [TMKClockView.arc] = [TMKClockView.arc(start: avgSpeed / topSpeed, end: 0.5, color: UIColor.greenColor()), TMKClockView.arc(start: maxSpeed / topSpeed, end: 0.9, color: UIColor.redColor())]
            
            speedView.updateData(String(format:"%0.2f", dist) , units: "Km", radis: speeds, arcs: limits, minValue: 0.0, maxValue: 30.0)
            
            return cell
            
        case 1:
            
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            var batteryView = TMKClockView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))
            cell.contentView.addSubview(batteryView)

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
            
            
            batteryView.updateData(String(format:"%0.0f", (bat0 - bat1)) , units: "%", radis: batLevels, arcs: batAreas, minValue: 0.0, maxValue: 100.0)
            
            return cell

        case 2:
            
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            var powerView = TMKClockView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))
            cell.contentView.addSubview(powerView)

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
            
            
            powerView.updateData(String(format:"%0.0f", pwMax) , units: "w", radis: pwLevels, arcs: pwAreas, minValue: 0.0, maxValue: pwRange / 100.0)
            
            return cell
            
        case 3:
            
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            
            var energyView = TMKClockView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))
            cell.contentView.addSubview(energyView)

            // Energy  eplus / erec
            
            
            var eAreas : [TMKClockView.arc] = []
            
            let emax = eplus
            
            eAreas.append(TMKClockView.arc(start: 0.0, end: (eplus-erec) / emax, color: UIColor.greenColor()))
            
            eAreas.append(TMKClockView.arc(start: (eplus-erec) / emax, end: eplus/emax, color: UIColor.redColor()))
            
            let eLevels =  [TMKClockView.arc(start: (eplus-erec) / emax, end: 0.5, color: UIColor.greenColor()),
                            TMKClockView.arc(start: eplus/emax, end: 0.9, color: UIColor.redColor())]
            
            energyView.updateData(String(format:"%0.0f", eplus-erec) , units: "wh", radis: eLevels, arcs: eAreas, minValue: 0.0, maxValue: emax)
            
            return cell
            
            
        case 4:
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("verticalCellIdentifier", forIndexPath: indexPath)
            var rollView = TMKVerticalView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))
            cell.contentView.addSubview(rollView)

            rollView.updateData(ravg, minValue: rmin, maxValue: rmax, scale: 1.0)
            
            return cell

            
        case 5:
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("levelCellIdentifier", forIndexPath: indexPath)
            var pitchView = TMKLevelView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))

            pitchView.updateData(pavg, minValue: pmin, maxValue: pmax, scale: 1.0)
            
            cell.contentView.addSubview(pitchView)
            return cell
           
            
        case 6:
            
            var cell = collectionView.dequeueReusableCellWithReuseIdentifier("clockCellIdentifier", forIndexPath: indexPath)
            var tempView = TMKClockView(frame: CGRect(x:0.0, y:0.0, width: 155.0, height: 155.0))
            cell.contentView.addSubview(tempView)

            
            // Temperature
            //
            //  let's say ti 60ºC is OK
            // maxT = 90
            // minT = 0
            
            let tempOk = 60.0
            
            let tempRange = ceil(max(tmax, 90.0) / 10.0) * 10.0
            var tempAreas : [TMKClockView.arc] = []
            
            if tmin < tempOk {
                tempAreas.append(TMKClockView.arc(start: tmin / tempRange, end:min(tmax, tempOk) / tempRange, color: UIColor.greenColor()))
            }
            
            if tmax > tempOk{
                tempAreas.append(TMKClockView.arc(start: max(tmin, tempOk) / tempRange, end:tmax / tempRange, color: UIColor.redColor()))
            }
            
            
            let tempLevels : [TMKClockView.arc] = [TMKClockView.arc(start: tavg / tempRange, end: 0.5, color: UIColor.greenColor()),
                                                   TMKClockView.arc(start: tmax / tempRange, end: 0.9, color: UIColor.redColor())]
            
            
            
            tempView.updateData(String(format:"%0.0f", tmax) , units: "ºC", radis: tempLevels, arcs: tempAreas, minValue: 0.0, maxValue: tempRange)
            
            return cell
          
        default:
            
            return UICollectionViewCell()
            
            
            
        }
        
    }
    
}
