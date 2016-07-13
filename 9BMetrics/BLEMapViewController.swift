//
//  BLEMapViewController.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 8/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import MapKit

class BLEMapViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    weak var dades : WheelTrack?
    
    var fullRect = MKMapRect(origin: MKMapPoint(x:0.0, y:0.0), size: MKMapSize(width: 100.0, height: 100.0))
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        self.mapView.removeOverlays(self.mapView.overlays)
        self.addTrack()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func addTrack(){
        
        if let nb = self.dades {
            var locs = nb.locationArray()
            
            if locs.count <= 0{
                return
            }
            
          
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
            
            
            let polyline = MKPolyline(coordinates: &locs, count: locs.count)
            mapView.addOverlay(polyline)
            
            mapView.setVisibleMapRect(fullRect, animated: false )
        }
    }
    
    @IBAction func reload(src: AnyObject){
        mapView.setVisibleMapRect(fullRect, animated: true)
    }
    
    @IBAction func selectMap(src: AnyObject){
        
        if let sc = src as? UISegmentedControl{
            
            let v = sc.selectedSegmentIndex
            
            switch v {
                
                
            case 0:
                self.mapView.mapType = MKMapType.Standard
                
            case 1:
                self.mapView.mapType = MKMapType.Satellite
               
                
            case 2:
                self.mapView.mapType = MKMapType.Hybrid
                
                
            default:
                
                self.mapView.mapType = MKMapType.Standard
              
            }
        }
        
        
    }
 
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBar.hidden = true
        super.viewWillAppear(animated)
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        if let poly = overlay as? MKPolyline{
            let routeLineView = MKPolylineRenderer(polyline: poly)
            routeLineView.fillColor = UIColor.redColor()
            routeLineView.lineCap = CGLineCap.Round
            routeLineView.lineWidth = 4.0
            routeLineView.strokeColor = UIColor.redColor()
            return routeLineView
            
        }else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    override func previewActionItems() -> [UIPreviewActionItem] {
        let shareGPX = UIPreviewAction(title: "Share GPX", style: .Default)
            {(action, viewController) in
                
                if let wheel = self.dades {
                    if let gpxurl = wheel.getGPXURL(){
                        
                        // get ViewController 
                        
                        if let theDelegate = UIApplication.sharedApplication().delegate as? AppDelegate{
                            if let vc = theDelegate.mainController{
                                vc.shareFile(gpxurl, src: vc.view, delete: false)
                            }
                        
                        }
                    }
                }
            }
        
        let openInTraces = UIPreviewAction(title: "Open GPX In", style: .Default)
        {(action, viewController) in
            if let wheel = self.dades {
                if let gpxurl = wheel.getGPXURL(){
                    
                    // get ViewController
                    
                    if let theDelegate = UIApplication.sharedApplication().delegate as? AppDelegate{
                        if let vc = theDelegate.mainController{

                            vc.openFileIn(gpxurl, src: vc, delete: false)
                        }
                        
                    }
                }
            }
        
        }

        
        return [shareGPX, openInTraces]
    }
    
    
 
}

