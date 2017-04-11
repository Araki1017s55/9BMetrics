//
//  BLEMapDashboard.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 14/2/17.
//  Copyright © 2017 Paco Gorina. All rights reserved.
//
// Test to implement a Map whith Dashboard data in it.
//
// Pure experimental
//

import UIKit
import CoreBluetooth
import MapKit
import AVFoundation

class BLEMapDashboard : BLEGenericDashboard, MKMapViewDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var fSpeedLabel: UILabel!
    @IBOutlet weak var fDistanceLabel: UILabel!
    
    @IBOutlet weak var fBattery: TMKClockView!
    @IBOutlet weak var fTemperature: TMKClockView!
    @IBOutlet weak var fCurrent: UILabel!
    
    @IBOutlet weak var bRecenter: UIButton!
    
    var polyTrack : MKPolyline?
    var newPolyTrack : MKPolyline?
    
    
    var fullRect = MKMapRect(origin: MKMapPoint(x:0.0, y:0.0), size: MKMapSize(width: 100.0, height: 100.0))
    
    let sphereColor = UIColor.black
    let labelColor = UIColor.black
    
    var batTop = 1.0
    var batOk = 0.2
    
    let tempTop = 90.0
    let tempOK = 60.0
    
    
    
    var tempAreas : [TMKClockView.arc] = []
    var battAreas : [TMKClockView.arc] = []
    
    var lastLongitude : Double = 0.0
    var lastLatitude : Double = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        battAreas = [TMKClockView.arc(start: 0.0, end: batOk/batTop, color: UIColor.red),
                     TMKClockView.arc(start: batOk/batTop, end: 1.0, color: UIColor.green)]
        
        
        tempAreas = [TMKClockView.arc(start: 0.0, end: tempOK / tempTop, color: UIColor.green),
                     TMKClockView.arc(start: tempOK / tempTop, end: 1.0, color: UIColor.red)]
        
        
        
        self.fTemperature.sphereColor = sphereColor
        self.fTemperature.labelsColor = labelColor
        self.fTemperature.label.textColor = labelColor
        self.fTemperature.unitsLabel.textColor = labelColor
        
        self.fBattery.sphereColor = sphereColor
        self.fBattery.labelsColor = labelColor
        self.fBattery.label.textColor = labelColor
        self.fBattery.unitsLabel.textColor = labelColor
        
        self.mapView.delegate = self
        
    }
    
    @IBAction func recenter(){
        self.mapView.setUserTrackingMode(.followWithHeading, animated: true)
        
    }
    
    @IBAction func whereIam(){
        
        if let track = client?.datos {
            if let loc = track.lastLocation(){
                CLGeocoder().reverseGeocodeLocation(loc,
                                                    completionHandler: {(placemarks:[CLPlacemark]?, error:Error?) -> Void in
                                                        if let placemarks = placemarks {
                                                            let placemark = placemarks[0]
                                                            
                                                            NSLog("p : %@", placemark)
                                                            

                                                        }
                })
                
            }
        }
    }
    
    override func updateName(_ name : String){
        self.mapView.userTrackingMode = .followWithHeading
    }
    
    override func prepareForUpdate(_ track: WheelTrack) {
        
    }
    
    override func updateUI(_ track : WheelTrack){
        
        // Check if current position has changed
        
        
        if positionHasChanged(track){
            newPolyTrack = getTrack(track)
            updateTrack(track)
            
        }
        
        // Here update values
        
        self.fDistanceLabel.text = String(format:"%@", UnitManager.sharedInstance.formatDistance(track.getCurrentValueForVariable(.Distance) * self.distanceCorrection)) // In m, yd, or km, mi
        self.fSpeedLabel.text = UnitManager.sharedInstance.formatSpeed(track.getCurrentValueForVariable(.Speed) * self.speedCorrection)
        self.fCurrent.text = String(format:"%0.2fA", track.getCurrentValueForVariable(.Current))
        
        let b = track.getCurrentValueForVariable(.Battery)
        let t = UnitManager.sharedInstance.convertTemperature(track.getCurrentValueForVariable(.Temperature))
        let volt = track.getCurrentValueForVariable(.Voltage)
        
        let battLevels = [TMKClockView.arc(start: b / 100.0, end: 0.5, color: UIColor.red)]
        let tempLevels = [TMKClockView.arc(start: track.getCurrentValueForVariable(.Temperature) / self.tempTop, end: 0.5, color: UIColor.red)]
        
        self.fBattery.updateData(String(format:"%0.1f", volt) , units: "V", radis: battLevels, arcs: self.battAreas, minValue: 0, maxValue: 100.0)
        
        self.fTemperature.updateData(String(format:"%0.1f", t) ,
                                     units: UnitManager.sharedInstance.temperatureUnit,
                                     radis: tempLevels,
                                     arcs: self.tempAreas,
                                     minValue: UnitManager.sharedInstance.convertTemperature(0.0),
                                     maxValue: UnitManager.sharedInstance.convertTemperature(self.tempTop))
        
        
    }
    
    override func hasStopped(_ not : Notification){
        
        super.hasStopped(not)
        
        self.mapView.userTrackingMode = .none
    }
    
    //MARK: Auxiliary Functions
    
    func updateTrack(_ track : WheelTrack){
        
        if track.countLogForVariable(.Longitude) < 2 {
            return
        }
        
        
        if let poly = polyTrack{
            mapView.remove(poly)
        }
        
        if let np = newPolyTrack {
            polyTrack = np
            mapView.add(polyTrack!)
            newPolyTrack = nil
            //mapView.setNeedsDisplay()
        }
        
    }
    
    
    
    func getTrack(_ track : WheelTrack) -> MKPolyline?{
        
        if track.countLogForVariable(.Longitude) < 2{
            return nil
        }
        
        var locs = track.locationArray()
        
        let pt0 = MKMapPointForCoordinate(locs[0])
        
        var xmin = pt0.x
        var ymin = pt0.y
        var xmax = pt0.x
        var ymax = pt0.y
        
        for loc in locs {
            let pt = MKMapPointForCoordinate(loc)
            
            xmin = min(pt.x, xmin)
            ymin = min(pt.y, ymin)
            xmax = max(pt.x, xmax)
            ymax = max(pt.y, ymax)
        }
        
        let deltax = xmax-xmin
        let deltay = ymax-ymin
        
        xmin = xmin - deltax * 0.10
        xmax = xmax + deltax * 0.10
        ymin = ymin - deltay * 0.10
        ymax = ymax + deltay * 0.10
        
        let orig = MKMapPoint(x: xmin, y: ymin)
        let size = MKMapSize(width: (xmax-xmin), height: (ymax-ymin))
        
        fullRect = MKMapRect(origin: orig, size: size)
        
        return MKPolyline(coordinates: &locs, count: locs.count)
    }
    
    func positionHasChanged(_ track : WheelTrack) -> Bool{
        let lon = track.getCurrentValueForVariable(.Longitude)
        let lat = track.getCurrentValueForVariable(.Latitude)
        
        if lon == lastLongitude && lat == lastLongitude{
            return false
        } else {
            lastLongitude = lon
            lastLatitude = lat
            return true
        }
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let poly = overlay as? MKPolyline{
            let routeLineView = MKPolylineRenderer(polyline: poly)
            routeLineView.fillColor = UIColor.red
            routeLineView.lineCap = CGLineCap.round
            routeLineView.lineWidth = 4.0
            routeLineView.strokeColor = UIColor.red
            return routeLineView
            
        }else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
        NSLog("Stopped Locating User")
    }
    
    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if mode != .followWithHeading{
            bRecenter.isHidden = false
        } else {
            bRecenter.isHidden = true
        }
    }
    
}
