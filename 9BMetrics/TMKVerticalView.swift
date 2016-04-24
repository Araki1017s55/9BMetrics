//
//  TMKLevelView.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 22/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//
//  Horizontal is value 0
//
//  Positives counterclockwise
//
//

import UIKit
import Foundation

class TMKVerticalView: UIView {
    
    var scale : Double    = 1.0  // Number to scale angles
    var value : Double    = 0.0// Normal angle (green)
    var minValue : Double = 30.0   // Minimum angle (red)
    var maxValue : Double = -30.0   // Maximum value (red)
    
    
        let startEndLength : CGFloat = 0.1   // Percentatge del radi
        let sphereWidth : CGFloat = 1.0
        let sphereColor = UIColor.yellowColor()
        let cursorWidth : CGFloat = 1.0
        let cursorColor = UIColor.redColor()
        let cursorSize : CGFloat = 1.0
    
        var valueLabel : UILabel = UILabel()    // value center down
        var minLabel : UILabel = UILabel()  // Minimum value left
        var maxLabel : UILabel = UILabel()  // Maximum value right
    
        var cValue :NSLayoutConstraint?
        var cMin :NSLayoutConstraint?
        var cMax :NSLayoutConstraint?
    
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
            
            valueLabel.text = String(format: "%0.1f", value)
            valueLabel.textAlignment = .Center
            valueLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
            valueLabel.textColor = UIColor.whiteColor()
            valueLabel.backgroundColor = UIColor.clearColor()
            valueLabel.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(valueLabel)
            
            var c1 = NSLayoutConstraint(item: valueLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
            
            cValue = NSLayoutConstraint(item: valueLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: r / 2.0 )
            
            
            self.addConstraint(c1)
            self.addConstraint(cValue!)
            
            minLabel.text = String(format: "%0.1f", minValue)
            minLabel.textAlignment = .Center
            minLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
            minLabel.textColor = UIColor.whiteColor()
            minLabel.backgroundColor = UIColor.clearColor()
            minLabel.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(minLabel)
            
            c1 = NSLayoutConstraint(item: minLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
            
            cMin = NSLayoutConstraint(item: minLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: -( r / 2.0) )
            
            
            self.addConstraint(c1)
            self.addConstraint(cMin!)
            
            // max values
            
            maxLabel.text = String(format: "%0.1f", maxValue)
            maxLabel.textAlignment = .Center
            maxLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
            maxLabel.textColor = UIColor.whiteColor()
            maxLabel.backgroundColor = UIColor.clearColor()
            maxLabel.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(maxLabel)
            
            c1 = NSLayoutConstraint(item: maxLabel, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
            
            cMax = NSLayoutConstraint(item: maxLabel, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: +( r / 2.0) )
            
            
            self.addConstraint(c1)
            self.addConstraint(cMax!)
            
        }
        
        func d2R(degs : Double ) -> CGFloat{
            return CGFloat(degs / 180.0 * M_PI)
        }
        
        func drawCursor(value : Double, len : CGFloat, width : CGFloat, color : UIColor, center : CGPoint ){
            
            // OK now draw cursor
            let bz = UIBezierPath()
            
            color.setStroke()
            bz.lineWidth = width
            
            let ang = d2R(value)
            
            let pt = CGPoint(x: center.x + len * CGFloat(cos(ang)), y: center.y + len * CGFloat(sin(ang)))
            
            bz.moveToPoint(center)
            bz.addLineToPoint(pt)
            
            bz.stroke()
        }
        
        func drawArc(start : Double, end : Double, r : CGFloat, width : CGFloat, color : UIColor, center : CGPoint){
            let bz = UIBezierPath()
            
            color.setStroke()
            bz.lineWidth = width * r
            
            let startAng = d2R(start)
            let endAng = d2R(end)
            
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

            // Update size and label position labels

            valueLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
            minLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
            maxLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)

            if let c = cValue {
                c.constant = r / 2.0
            }
            
            if let c = cMin {
                c.constant = -(r / 2.0)
            }
            
            if let c = cMax {
                c.constant = r / 2.0
            }
            
            let center = CGPoint(x: self.bounds.width/2.0, y:self.bounds.height/2.0)
            
            // Draw sphere
            
            sphereColor.setStroke()
            var bz = UIBezierPath()
            bz.lineWidth = sphereWidth
            
            bz.addArcWithCenter(center, radius: r, startAngle:0.0, endAngle:CGFloat(2.0 * M_PI), clockwise: true)
            
            bz.stroke()
            
            // Now put the ticks that show just top and bottom
            
            bz = UIBezierPath()
            bz.moveToPoint(CGPoint(x: center.x, y:center.y+r-l))
            bz.addLineToPoint(CGPoint(x: center.x, y:center.y+r))
            bz.stroke()
            
            bz = UIBezierPath()
            bz.moveToPoint(CGPoint(x: center.x, y:center.y-r+l))
            bz.addLineToPoint(CGPoint(x: center.x, y:center.y-r))
            bz.stroke()
            
            // Now we draw the lines :
            
            // Value line
            
            UIColor.greenColor().setStroke()
            
            bz = UIBezierPath()
            var a = d2R((value * scale) + 90.0 )
            bz.moveToPoint(CGPoint(x: center.x + r * cos(a), y:center.y + r * sin(a)))
            bz.addLineToPoint(CGPoint(x: center.x - r * cos(a), y:center.y - r * sin(a)))
            bz.stroke()

            
            UIColor.redColor().setStroke()
            
            bz = UIBezierPath()
            a = d2R((minValue * scale) + 90.0 )
            bz.moveToPoint(CGPoint(x: center.x + r * cos(a), y:center.y + r * sin(a)))
            bz.addLineToPoint(CGPoint(x: center.x - r * cos(a), y:center.y - r * sin(a)))
            bz.stroke()
            
            bz = UIBezierPath()
            a = d2R((maxValue * scale) + 90.0 )
            bz.moveToPoint(CGPoint(x: center.x + r * cos(a), y:center.y + r * sin(a)))
            bz.addLineToPoint(CGPoint(x: center.x - r * cos(a), y:center.y - r * sin(a)))
            bz.stroke()
           
            
            
            CGContextRestoreGState(aContext)
            
            // Drawing code
            
            super.drawRect(rect)
        }
        
    func updateData(value : Double, minValue : Double, maxValue : Double, scale : Double){
        
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.scale = scale
        
        self.valueLabel.text = String(format: "%0.1f", value)
        self.minLabel.text = String(format: "%0.1f", minValue)
        self.maxLabel.text = String(format: "%0.1f", maxValue)
        
            
        self.setNeedsDisplay()
            
        }
    
        
    }
