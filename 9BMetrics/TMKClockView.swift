//
//  TMKClockView.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 21/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit
import Foundation

class TMKClockView: UIView {
    
    struct arc {
        var start : Double
        var end : Double
        var color : UIColor
    }

    let openAngle = 30.0
    let startEndLength : CGFloat = 0.1   // Percentatge del radi
    let sphereWidth : CGFloat = 1.0
    var sphereColor = UIColor.yellowColor()
    let cursorWidth : CGFloat = 1.0
    let cursorColor = UIColor.redColor()
    let cursorSize : CGFloat = 0.9
    
    var minValue = 0.0
    var maxValue = 100.0
    
    var label : UILabel = UILabel()
    var unitsLabel : UILabel = UILabel()
    var labelsColor = UIColor.whiteColor()
    
    var backImage : UIImage?

    
    var radis : [arc] = []
    var arcs : [arc] = []
    
    var arcWidth : CGFloat = 0.1     // Percentage of r
    
    
    
    var value = ""
    
    var units = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    func setup(){
        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0)-1.0

        label.text = String(format: "%0.2f", value)
        label.textAlignment = .Center
        //label.font = UIFont.systemFontOfSize(r / 4.0)
        
        label.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        
        label.textColor = UIColor.whiteColor()
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
        unitsLabel.textColor = UIColor.whiteColor()
        unitsLabel.backgroundColor = UIColor.clearColor()
        //label!.bounds = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 20.0)
        unitsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(unitsLabel)
        
        c1 = NSLayoutConstraint(item: unitsLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
        
        c2 = NSLayoutConstraint(item: unitsLabel, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: -(r / 12.0) )
        
        
        self.addConstraint(c1)
        self.addConstraint(c2)
        
        

        
    }
    
    func d2R(degs : Double ) -> CGFloat{
        return CGFloat(degs / 180.0 * M_PI)
    }
    
    func valueToAngle(val : Double) -> CGFloat{
        
        let angle = val * (360.0 - (2 * openAngle)) + (-270.0 + openAngle)
        
        return d2R(angle)
    }
    
    func drawCursor(value : Double, len : CGFloat, width : CGFloat, color : UIColor, center : CGPoint ){
        
        let semiBlackColor : UIColor

        if let bc = self.backgroundColor{
            semiBlackColor = bc.colorWithAlphaComponent(0.5)
        }else{
            semiBlackColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        }

        // OK now draw cursor
        
        let bz = UIBezierPath()
        bz.lineCapStyle = .Round
        let ang = valueToAngle(value)
        let pt = CGPoint(x: center.x + len * CGFloat(cos(ang)), y: center.y + len * CGFloat(sin(ang)))
        bz.moveToPoint(center)
        bz.addLineToPoint(pt)
        
        bz.lineWidth = width + 2.0
        semiBlackColor.setStroke()

        bz.stroke()
        
        color.setStroke()
        bz.lineWidth = width
        bz.stroke()

    }

    func drawArc(start : Double, end : Double, r : CGFloat, width : CGFloat, color : UIColor, center : CGPoint){
        let bz = UIBezierPath()
        
        color.setStroke()
        bz.lineWidth = width * r
        
        let startAng = valueToAngle(start)
        let endAng = valueToAngle(end)
        
        bz.addArcWithCenter(center, radius: r * (1.0-width), startAngle:startAng, endAngle:endAng, clockwise: true)
        
        bz.stroke()
    
    }

    
    
    override func drawRect(rect: CGRect) {
        
        // Get graphics context
        let aContext = UIGraphicsGetCurrentContext()
        
        CGContextSaveGState(aContext)
        
        // Get the radius
        
        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0)-1.0
        let l  : CGFloat = r * startEndLength
        let start = d2R(-270+openAngle)
        let end = d2R(90.0-openAngle)
        
        let center = CGPoint(x: self.bounds.width/2.0, y:self.bounds.height/2.0)
        
        if let img = backImage{
            
            let side = sqrt((r * r) / 2.0) * 2.0
            
            let rect = CGRect(x: center.x - side/2.0, y: center.y - side/2.0, width: side, height: side)
            
            img.drawInRect(rect)
        }
        
        
        // Draw sphere
        
        sphereColor.setStroke()
        let bz = UIBezierPath()
        bz.lineWidth = sphereWidth
        
        if l > 0.0 {
            
            let pt0 = CGPoint(x: center.x + (r - l) * CGFloat(cos(start)), y: center.y + (r - l) * CGFloat(sin(start)))
            let pt1 = CGPoint(x: center.x + r * CGFloat(cos(start)), y: center.y + r * CGFloat(sin(start)))

            bz.moveToPoint(pt0)
            bz.addLineToPoint(pt1)
         }
        
        bz.addArcWithCenter(center, radius: r, startAngle:start, endAngle:end, clockwise: true)
        
        if l > 0.0 {
            let pt0 = CGPoint(x: center.x + (r - l) * CGFloat(cos(end)), y: center.y + (r - l) * CGFloat(sin(end)))
            bz.addLineToPoint(pt0)
        }
        
        bz.stroke()
        
        // Now put the labels for min and max value
        
        var ptl = CGPoint(x: center.x + (r + l) * CGFloat(cos(start)), y: center.y + (r + l) * CGFloat(sin(start)))
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .Center
        
        let xfont = UIFont(name: ".SFUIText-Light", size: r / 6.0)
        
        let attributes = [
            NSFontAttributeName: xfont!,
            NSForegroundColorAttributeName: labelsColor,
            NSParagraphStyleAttributeName: paraStyle
        ]
        // NSFontAttributeName: UIFont.systemFontOfSize(r / 6.0)
        
        let minS = NSString(format:"%0.0f", minValue)
        let minSiz = minS.sizeWithAttributes(attributes)
        let minRect = CGRect(x: ptl.x - (minSiz.width / 2.0), y: ptl.y - (minSiz.height / 2.0), width: minSiz.width, height: minSiz.height)

        minS.drawInRect(minRect, withAttributes: attributes)
        
        ptl = CGPoint(x: center.x + (r + l) * CGFloat(cos(end)), y: center.y + (r + l) * CGFloat(sin(end)))
        
        let maxS = NSString(format:"%0.0f", maxValue)
        let maxSiz = maxS.sizeWithAttributes(attributes)
        let maxRect = CGRect(x: ptl.x - (maxSiz.width / 2.0), y: ptl.y - (maxSiz.height / 2.0), width: maxSiz.width, height: maxSiz.height)
        
        maxS.drawInRect(maxRect, withAttributes: attributes)
        
        // Now the arcs
        
        for a in arcs {
            drawArc(a.start, end: a.end, r: r, width: arcWidth, color: a.color, center: center)
        }
        
        for a in radis {
            
            drawCursor(a.start, len: r * cursorSize, width: cursorWidth, color: a.color, center: center)
        }
        
        
        
        CGContextRestoreGState(aContext)
        
        // Drawing code
        
        super.drawRect(rect)
    }
    
    func updateData(value : String, units : String, radis : [arc], arcs : [arc], minValue : Double, maxValue : Double){
        
        self.label.text = value
        self.value = value
        self.unitsLabel.text = units
        self.units = units
        self.radis = radis
        self.arcs = arcs
        self.minValue = minValue
        self.maxValue = maxValue
        
        self.setNeedsDisplay()
        
    }
 
}
