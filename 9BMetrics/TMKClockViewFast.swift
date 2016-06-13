//
//  TMKClockView.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 21/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import Foundation

class TMKClockViewFast: UIView {
    
    let openAngle = 30.0
    let startEndLength : CGFloat = 0.1   // Percentatge del radi
    let sphereWidth : CGFloat = 1.0
    var sphereColor = UIColor.blackColor()
    let cursorWidth : CGFloat = 1.0
    let cursorColor = UIColor.redColor()
    let cursorSize : CGFloat = 0.9
    
    var minValue = 0.0
    var maxValue = 100.0
    
    var label : UILabel = UILabel()
    var unitsLabel : UILabel = UILabel()
    var labelsColor = UIColor.whiteColor()
    
    var backImage : UIImage?
    
    
    var radis : [TMKClockView.arc] = []
    var arcs : [TMKClockView.arc] = []
    
    var arcWidth : CGFloat = 0.1     // Percentage of r
    
    
    
    var value : Double = 0.0
    
    var units = ""
    
    var cursor  : CAShapeLayer?
  
    override init(frame: CGRect) {
        super.init(frame: frame)
       // self.setup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //self.setup()
    }

    func setup(){
        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0)-1.0
        
       // self.addSubview(self.backView(self.bounds))
        // Back layer
        
        self.layer.addSublayer(self.backLayer(self.bounds))
        // We create the cursor view
        
        // Add Arcs
        
        for arcLayer in self.arcLayers(self.bounds, arcs: self.arcs){
            self.layer.addSublayer(arcLayer)
        }
 
        label.text = String(format: "%0.2f", value)
        label.textAlignment = .Center
        //label.font = UIFont.systemFontOfSize(r / 4.0)
        
        label.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        
        label.textColor = labelsColor
        label.backgroundColor = UIColor.clearColor()
        //label!.bounds = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 20.0)
        label.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(label)
        
        var c1 = NSLayoutConstraint(item: label, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
        
        var c2 = NSLayoutConstraint(item: label, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: -(r / 8.0) - (r * 0.1) )
        
            
        self.addConstraint(c1)
        self.addConstraint(c2)
  
        unitsLabel.text = String(format: "%@", units)
        unitsLabel.textAlignment = .Center
        //unitsLabel.font = UIFont.systemFontOfSize(r / 6.0)
        unitsLabel.font = UIFont(name: ".SFUIText-Light", size: r / 6.0)
        unitsLabel.textColor = labelsColor
        unitsLabel.backgroundColor = UIColor.clearColor()
        //label!.bounds = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 20.0)
        unitsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(unitsLabel)
        
        
        c1 = NSLayoutConstraint(item: unitsLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
        
        c2 = NSLayoutConstraint(item: unitsLabel, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: -(r / 12.0) )
        
        
        self.addConstraint(c1)
        self.addConstraint(c2)

        // Add min and max values 
        
        
        
        // Add Cursor Layer
        
        self.cursor = cursorLayer(self.bounds)
        self.layer.addSublayer(self.cursor!)
        
        // Set cursor value to 0
        
        if let acursor = self.cursor{
            
            let angle = self.valueToAngle(0.0)
            let tr = CATransform3DMakeRotation(angle, 0.0, 0.0 , 1.0)
            
            UIView.animateWithDuration(0.05, animations: {
                
                acursor.transform = tr
                
            })
        }

       
        
        
    }
    
    func arcLayers(rect: CGRect, arcs : [TMKClockView.arc]) -> [CAShapeLayer]{
        
        var out : [CAShapeLayer] = []
        
        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0) * cursorSize
        let w = r * arcWidth
        
        let center = CGPoint(x: self.bounds.width/2.0, y:self.bounds.height/2.0)
        
        for arc in arcs {
            
            
            
            let back = CAShapeLayer()
            back.frame = rect
            
            let startAng = valueToAngle(arc.start)
            let endAng = valueToAngle(arc.end)

            
            let path = CGPathCreateMutable()
            CGPathAddArc(path, nil, center.x, center.y, r, CGFloat(startAng), CGFloat(endAng), false)
            back.path = path
            back.lineWidth = w
            back.lineCap = kCALineCapButt

            back.strokeColor = arc.color.CGColor
            back.fillColor = UIColor.clearColor().CGColor
            back.rasterizationScale = UIScreen.mainScreen().scale * 2.0;
            back.shouldRasterize = true
            
            out.append(back)
            
        }
        
        return out
        
    }
    
    func cursorLayer (rect: CGRect) -> CAShapeLayer{
        
        let cursor = CAShapeLayer()
        cursor.frame = rect
        let path = CGPathCreateMutable()

        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0) - 1.0
        let l  : CGFloat = r * cursorSize

        CGPathMoveToPoint(path, nil, CGRectGetMidX(rect), CGRectGetMidY(rect))
        CGPathAddLineToPoint(path, nil, CGRectGetMidX(rect) + l, CGRectGetMidY(rect))
        cursor.path = path
        cursor.lineWidth = 1.0
        cursor.lineCap = kCALineCapRound
        cursor.strokeColor = cursorColor.CGColor
        
        // see for rasterization advice http://stackoverflow.com/questions/24316705/how-to-draw-a-smooth-circle-with-cashapelayer-and-uibezierpath
        cursor.rasterizationScale = UIScreen.mainScreen().scale;
        cursor.shouldRasterize = true
        
        
        return cursor
        
    }

    func backLayer(rect: CGRect) -> CAShapeLayer{
        
        let back = CAShapeLayer()
        back.frame = rect
        
        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0)-1.0
        let l  : CGFloat = r * startEndLength
        let start = valueToAngle(0.0)
        let end = valueToAngle(1.0)
        
        let center = CGPoint(x: self.bounds.width/2.0, y:self.bounds.height/2.0)
        
        let path = CGPathCreateMutable()
        
        let pt0 = CGPoint(x: center.x + (r - l) * CGFloat(cos(start)), y: center.y + (r - l) * CGFloat(sin(start)))
        let pt1 = CGPoint(x: center.x + r * CGFloat(cos(start)), y: center.y + r * CGFloat(sin(start)))

        
        CGPathMoveToPoint(path, nil, pt0.x, pt0.y)
        CGPathAddLineToPoint(path, nil, pt1.x, pt1.y)
        CGPathAddArc(path, nil, center.x, center.y, r, start, end, false)
        let pt2 = CGPoint(x: center.x + (r - l) * CGFloat(cos(end)), y: center.y + (r - l) * CGFloat(sin(end)))
        CGPathAddLineToPoint(path, nil, pt2.x, pt2.y)
        
        back.path = path
        back.lineWidth = 1.0
        back.lineCap = kCALineCapRound
        back.strokeColor = sphereColor.CGColor
        back.fillColor = UIColor.clearColor().CGColor
        back.rasterizationScale = UIScreen.mainScreen().scale * 2.0;
        back.shouldRasterize = true
        return back
    }
    
    
    func updateData(displayValue : String, units : String, value : Double, minValue : Double, maxValue : Double){
        
        
        self.label.text = displayValue
        self.value = value
        self.unitsLabel.text = units
        self.units = units
        self.minValue = minValue
        self.maxValue = maxValue
        
        if let acursor = self.cursor{
            
            let angle = self.valueToAngle((value - minValue) / (maxValue - minValue))
            let tr = CATransform3DMakeRotation(angle, 0.0, 0.0 , 1.0)
            
            UIView.animateWithDuration(0.05, animations: {
                
                acursor.transform = tr
                
            })
        }
        
        self.setNeedsDisplay()
        
    }
    
    
    func d2R(degs : Double ) -> CGFloat{
        return CGFloat(degs / 180.0 * M_PI)
    }
    
    func valueToAngle(val : Double) -> CGFloat{
        
        
        //return d2R(val*360.0)
        let angle = val * (360.0 - (2 * openAngle)) + (-270.0 + openAngle)
        
        return d2R(angle)
    }

 
}
