//
//  BLEHistoDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 22/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class BLEHistoDashboard: UIViewController , UIGestureRecognizerDelegate{
    
    weak var ninebot : WheelTrack?
    
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
    
    var distanceCorrection = 1.0
    var speedCorrection = 1.0
    
    @IBOutlet  weak var collectionView : UICollectionView!
    @IBOutlet weak var fTitle : UILabel!
    @IBOutlet weak var fVersion : UILabel!
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    
    static var displayableVariables : [Int] = [BLENinebot.kCurrentSpeed, BLENinebot.kTemperature,
                                               BLENinebot.kVoltage, BLENinebot.kCurrent, BLENinebot.kBattery, BLENinebot.kPitchAngle, BLENinebot.kRollAngle,
                                               BLENinebot.kvSingleMileage, BLENinebot.kAltitude, BLENinebot.kPower, BLENinebot.kEnergy]
    
    
    fileprivate let graphValue = [0, 4, 9, 10, 1, 6, 5]
    
    var graphToShow : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Register for peek
        
        registerForPreviewing(with: self, sourceView: collectionView)
        
        fTitle.text = titulo
        
        let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(BLEHistoDashboard.handleLongPress(_:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delegate = self
        lpgr.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(lpgr)
        
        if let nb = self.ninebot {
            
            
            if let wh = WheelDatabase.sharedInstance.getWheelFromUUID(uuid: nb.getUUID()){
                speedCorrection = wh.getSpeedCorrection()
                distanceCorrection = wh.getDistanceCorrection()
            }
            
            if let myUrl = nb.url{
                fTitle.text = myUrl.deletingPathExtension().lastPathComponent
            }else{
                fTitle.text = "Unknown"
            }
            
            fVersion.text = nb.getName() + "(" + nb.getVersion() + ")"
            ascent = nb.getAscent()
            descent = nb.getDescent()
            dist = nb.getCurrentValueForVariable(.Distance) / 1000.0 * distanceCorrection   // Convert to KM
            time = nb.getCurrentValueForVariable(.Duration)
            (_, maxSpeed, avgSpeed, _) = nb.getCurrentStats(.Speed)
            
            maxSpeed = maxSpeed * 3.6 * speedCorrection // Convert to km/h
            avgSpeed = avgSpeed * 3.6 * speedCorrection // Convert to km/h
            
            (bat0, bat1) = nb.getFirstLast(.Battery)
            (batMin, batMax, _, _) = nb.getCurrentStats(.Battery)
            (_, currMax, currAvg, _) = nb.getCurrentStats(.Current)
            (_, pwMax, pwAvg, _) = nb.getCurrentStats(.Power)
            batEnergy = nb.getBatteryEnergy()
            
            (tmin, tmax, tavg, _) = nb.getCurrentStats(.Temperature)
            (pmin, pmax, pavg, _) = nb.getCurrentStats(.Pitch)
            (rmin, rmax, ravg, _) = nb.getCurrentStats(.Roll)
            
            eplus = nb.getEnergyUsed() / 3600.0
            erec = nb.getEnergyRecovered() / 3600.0
            
            trackImg = nb.getImage()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.collectionView.performBatchUpdates(nil, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
    }
    
    @IBAction func goBack(_ src : AnyObject){
        
        if let nv = self.navigationController{
            _ = nv.popViewController(animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
            
        case "otherMapSegue": //graphMapSegue
            if let vc = segue.destination as? BLEMapViewController  {
                vc.dades = self.ninebot
            }
            
        case "graphicSegue":
            
            if let vc = segue.destination as? GraphViewController  {
                
                vc.ninebot = self.ninebot
                vc.shownVariable = self.graphToShow
            }
            
        default:
            break
        }
    }
    
    @IBAction func prepareForUnwind(_ segue: UIStoryboardSegue){
        
        self.dismiss(animated: true) {
            
        }
        
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if size.width > size.height{
            // graphToShow = graphValue[0]
            // self.performSegueWithIdentifier("graphicSegue", sender: self)
            
            
        }
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.portrait]
    }
    override var preferredInterfaceOrientationForPresentation : UIInterfaceOrientation {
        return .portrait
    }
    func handleLongPress(_ gestureRecognizer : UILongPressGestureRecognizer){
        
        if (gestureRecognizer.state != UIGestureRecognizerState.ended){
            return
        }
        
        let p = gestureRecognizer.location(in: self.collectionView)
        
        let indexPath : IndexPath = (self.collectionView?.indexPathForItem(at: p))!
            //do whatever you need to do
        if (indexPath as NSIndexPath).row == 0{
            self.performSegue(withIdentifier: "otherMapSegue", sender: self)
        }
        
    }
            
        
        
        //MARK: Preview Action Items
        
        override var previewActionItems : [UIPreviewActionItem] {
            let shareTrack = UIPreviewAction(title: "Share Track".localized(), style: .default)
            {(action, viewController) in
                
                if let wheel = self.ninebot {
                    if let trackUrl : URL = wheel.url as URL?{
                        
                        // get ViewController
                        
                        if let theDelegate = UIApplication.shared.delegate as? AppDelegate{
                            if let vc = theDelegate.mainController{
                                vc.shareData(trackUrl, src: vc.view, delete: false)
                            }
                            
                        }
                    }
                }
            }
            
            let openTrackIn = UIPreviewAction(title: "Open GPX In".localized(), style: .default)
            {(action, viewController) in
                if let wheel = self.ninebot {
                    if let trackUrl : URL = wheel.url as URL?{
                        
                        // get ViewController
                        
                        if let theDelegate = UIApplication.shared.delegate as? AppDelegate{
                            if let vc = theDelegate.mainController{
                                
                                vc.openFileIn(trackUrl, src: vc, delete: false)
                            }
                            
                        }
                    }
                }
                
            }
            return [shareTrack, openTrackIn]
        }
        
        
    }
    
    extension BLEHistoDashboard : UICollectionViewDelegateFlowLayout{
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            
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
            
            
            let row = (indexPath as NSIndexPath).row
            switch row {
                
            case 0...3:
                return CGSize(width: s, height: s+20.0)
                
                
            case 4...6:
                return CGSize(width: s1, height :s1 + 20.0)
                
                
            default:
                return CGSize(width: 100.0, height : 120.0)
            }
            
        }
        
        func collectionView(_ collectionView: UICollectionView,
                            layout collectionViewLayout: UICollectionViewLayout,
                            insetForSectionAt section: Int) -> UIEdgeInsets {
            return sectionInsets
        }
        
        
    }
    extension BLEHistoDashboard : UICollectionViewDelegate {
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let row = (indexPath as NSIndexPath).row
            
            switch row {
                
                // **       case 0: // Speed/map , open Map
                // **           performSegueWithIdentifier("otherMapSegue", sender: self)
                
                
            default:
                graphToShow = self.graphValue[row]
                
                performSegue(withIdentifier: "graphicSegue", sender: self)
                
                
            }
        }
        
        
    }
    
    extension BLEHistoDashboard : UICollectionViewDataSource{
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return 7
        }
        
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            return 1
        }
        
        
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            
            
            switch (indexPath as NSIndexPath).row {
                
            case 0:
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clockCellIdentifier", for: indexPath)
                
                var speedView : TMKClockView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKClockView.self){
                        speedView = v as? TMKClockView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                if let tit = title {
                    tit.text = "Speed".localized(comment: "Speed Title")
                }
                
                
                var topSpeed = defaultTopSpeed
                if maxSpeed > defaultTopSpeed {
                    topSpeed = ceil(maxSpeed / 10.0) * 10.0
                }
                
                if let sv = speedView {
                    var limits = [TMKClockView.arc(start: 0.0, end: 23.0/topSpeed, color: UIColor.green)]
                    
                    if maxSpeed > secureSpeed{
                        limits.append( TMKClockView.arc(start: 23.0/topSpeed, end: maxSpeed / topSpeed, color: UIColor.red))
                        
                    }
                    
                    
                    let speeds : [TMKClockView.arc] = [TMKClockView.arc(start: avgSpeed / topSpeed, end: 0.5, color: UIColor.green), TMKClockView.arc(start: maxSpeed / topSpeed, end: 0.9, color: UIColor.red)]
                    
                    sv.backImage = self.trackImg
                    
                    
                    sv.updateData(String(format:"%0.2f", UnitManager.sharedInstance.convertLongDistance(dist)) , units: UnitManager.sharedInstance.longDistanceUnit, radis: speeds, arcs: limits, minValue: 0.0, maxValue: UnitManager.sharedInstance.convertSpeed(topSpeed))
                }
                return cell
                
            case 1:
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clockCellIdentifier", for: indexPath)
                
                var batteryView : TMKClockView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKClockView.self){
                        batteryView = v as? TMKClockView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                
                if let tit = title {
                    tit.text = "Battery".localized(comment: "Battery Title")
                }
                
                if let bv = batteryView{
                    
                    var batAreas : [TMKClockView.arc] = []
                    
                    if batMin < 20.0 && batMax <= 20.0 {
                        batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: batMax/100.0, color: UIColor.red))
                    }else if batMin < 20.0 && batMax > 20.0 {
                        batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: 20.0/100.0, color: UIColor.red))
                        batAreas.append(TMKClockView.arc(start: 20.0 / 100.0, end: batMax/100.0, color: UIColor.green))
                    }else {
                        batAreas.append(TMKClockView.arc(start: batMin / 100.0, end: batMax/100.0, color: UIColor.green))
                    }
                    
                    let batLevels : [TMKClockView.arc] = [TMKClockView.arc(start: bat0 / 100.0, end: 0.5, color: UIColor.green),
                                                          TMKClockView.arc(start: bat1 / 100.0, end: 0.9, color: UIColor.red)]
                    
                    bv.backImage = nil
                    
                    bv.updateData(String(format:"%0.0f", (bat0 - bat1)) , units: "%", radis: batLevels, arcs: batAreas, minValue: 0.0, maxValue: 100.0)
                }
                
                return cell
                
            case 2:
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clockCellIdentifier", for: indexPath)
                
                
                var powerView : TMKClockView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKClockView.self){
                        powerView = v as? TMKClockView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                
                if let tit = title {
                    tit.text = "Power".localized(comment: "Power Title")
                }
                if let pw = powerView{
                    
                    let pwCont = 500.0
                    let pwPeak = 1000.0
                    
                    let pwRange = ceil(max(pwMax, 1500.0) / 100.0) * 100.0
                    var pwAreas : [TMKClockView.arc] = []
                    
                    pwAreas.append(TMKClockView.arc(start: 0.0 / pwRange, end:min(pwMax, pwCont) / pwRange, color: UIColor.green))
                    
                    if pwMax > pwCont {
                        pwAreas.append(TMKClockView.arc(start: pwCont / pwRange, end:min(pwMax, pwPeak) / pwRange, color: UIColor.orange))
                    }
                    
                    if pwMax > pwPeak {
                        pwAreas.append(TMKClockView.arc(start: pwPeak / pwRange, end:pwMax / pwRange, color: UIColor.red))
                    }
                    
                    let pwLevels : [TMKClockView.arc] = [TMKClockView.arc(start: pwAvg / pwRange, end: 0.5, color: UIColor.green),
                                                         TMKClockView.arc(start: pwMax / pwRange, end: 0.9, color: UIColor.red)]
                    
                    pw.backImage = nil
                    
                    pw.updateData(String(format:"%0.0f", pwMax) , units: "w", radis: pwLevels, arcs: pwAreas, minValue: 0.0, maxValue: pwRange / 100.0)
                }
                
                return cell
                
            case 3:
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clockCellIdentifier", for: indexPath)
                
                var energyView : TMKClockView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKClockView.self){
                        energyView = v as? TMKClockView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                
                if let tit = title {
                    tit.text = "Energy".localized(comment: "Energy Title")
                }
                if let ew = energyView{
                    
                    // Energy  eplus / erec
                    
                    
                    var eAreas : [TMKClockView.arc] = []
                    
                    let emax = eplus
                    
                    eAreas.append(TMKClockView.arc(start: 0.0, end: (eplus-erec) / emax, color: UIColor.green))
                    
                    eAreas.append(TMKClockView.arc(start: (eplus-erec) / emax, end: eplus/emax, color: UIColor.red))
                    
                    let eLevels =  [TMKClockView.arc(start: (eplus-erec) / emax, end: 0.5, color: UIColor.green),
                                    TMKClockView.arc(start: eplus/emax, end: 0.9, color: UIColor.red)]
                    
                    ew.backImage = nil
                    
                    ew.updateData(String(format:"%0.0f", eplus-erec) , units: "wh", radis: eLevels, arcs: eAreas, minValue: 0.0, maxValue: emax)
                }
                
                return cell
                
            case 4:
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clockCellIdentifier", for: indexPath)
                
                
                var tempView : TMKClockView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKClockView.self){
                        tempView = v as? TMKClockView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                
                if let tit = title {
                    tit.text = "T".localized(comment: "Temperature Title") + UnitManager.sharedInstance.temperatureUnit
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
                        tempAreas.append(TMKClockView.arc(start: tmin / tempRange, end:min(tmax, tempOk) / tempRange, color: UIColor.green))
                    }
                    
                    if tmax > tempOk{
                        tempAreas.append(TMKClockView.arc(start: max(tmin, tempOk) / tempRange, end:tmax / tempRange, color: UIColor.red))
                    }
                    
                    
                    let tempLevels : [TMKClockView.arc] = [TMKClockView.arc(start: tavg / tempRange, end: 0.5, color: UIColor.green),
                                                           TMKClockView.arc(start: tmax / tempRange, end: 0.9, color: UIColor.red)]
                    
                    
                    tw.backImage = nil
                    
                    tw.updateData(String(format:"%0.0f", UnitManager.sharedInstance.convertTemperature(tmax)  ) , units:  UnitManager.sharedInstance.temperatureUnit, radis: tempLevels, arcs: tempAreas, minValue: 0.0, maxValue:  UnitManager.sharedInstance.convertTemperature(tempRange))
                }
                
                return cell
                
            case 5:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "verticalCellIdentifier", for: indexPath)
                
                var rollView : TMKVerticalView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKVerticalView.self){
                        rollView = v as? TMKVerticalView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                
                if let tit = title {
                    tit.text = "Roll".localized(comment: "Roll Title")
                }
                if let rw = rollView{
                    
                    rw.updateData(ravg, minValue: rmin, maxValue: rmax, scale: 1.0)
                }
                
                return cell
                
                
            case 6:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "levelCellIdentifier", for: indexPath)
                
                var pitchView : TMKLevelView?
                var title : UILabel?
                
                for v in cell.contentView.subviews{
                    if v.isKind(of: TMKLevelView.self){
                        pitchView = v as? TMKLevelView
                    } else if v.isKind(of: UILabel.self){
                        title = v as? UILabel
                    }
                }
                
                if let tit = title {
                    tit.text = "Pitch".localized(comment: "Pitch Title")
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
    
    extension BLEHistoDashboard : UIViewControllerPreviewingDelegate{
        
        func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
            if let indexPath = collectionView.indexPathForItem(at: location), let cellAttributes = collectionView.layoutAttributesForItem(at: indexPath) {
                //This will show the cell clearly and blur the rest of the screen for our peek.
                previewingContext.sourceRect = cellAttributes.frame
                
                switch (indexPath as NSIndexPath).row {
                    
                case 0:
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let  mpc = storyboard.instantiateViewController(withIdentifier: "mapViewControllerIdentifier") as? BLEMapViewController{
                        
                        mpc.dades = self.ninebot
                        return mpc
                    }
                    
                default:
                    
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let  gc = storyboard.instantiateViewController(withIdentifier: "graphViewControllerIdentifier") as? GraphViewController{
                        
                        gc.ninebot = self.ninebot
                        graphToShow = self.graphValue[(indexPath as NSIndexPath).row]
                        gc.shownVariable = self.graphToShow
                        return gc
                    }
                    
                    
                }
                
            }
            return nil
        }
        
        func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
            
            if let mvc = viewControllerToCommit as? BLEMapViewController{
                present(mvc, animated: true, completion: nil)
            } else {
                show(viewControllerToCommit, sender: self)
            }
            
        }
        
}
