//
//  TMKLevelView.swift
//  9BMetrics
//
//  Created by Francisco Gorina Vanrell on 22/4/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class TMKLevelView: UIView {
    
    
    var scale : Double    = 1.0  // Number to scale angles
    var value : Double    = 0.0// Normal angle (green)
    var minValue : Double = 30.0   // Minimum angle (red)
    var maxValue : Double = -30.0   // Maximum value (red)
    
    
    let startEndLength : CGFloat = 0.1   // Percentatge del radi
    let sphereWidth : CGFloat = 1.0
    let sphereColor = UIColor.yellow
    let cursorWidth : CGFloat = 1.0
    let cursorColor = UIColor.red
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
        valueLabel.textAlignment = .center
        valueLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        valueLabel.textColor = UIColor.white
        valueLabel.backgroundColor = UIColor.clear
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(valueLabel)
        
        cValue = NSLayoutConstraint(item: valueLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: -(r/2.0))
        
        var c1 = NSLayoutConstraint(item: valueLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0 )
        
        
        self.addConstraint(c1)
        self.addConstraint(cValue!)
        
        minLabel.text = String(format: "%0.1f", minValue)
        minLabel.textAlignment = .center
        minLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        minLabel.textColor = UIColor.white
        minLabel.backgroundColor = UIColor.clear
        minLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(minLabel)
        
        c1 = NSLayoutConstraint(item: minLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        
        cMin = NSLayoutConstraint(item: minLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: +( r / 2.0) )
        
        
        self.addConstraint(c1)
        self.addConstraint(cMin!)
        
        // max values
        
        maxLabel.text = String(format: "%0.1f", maxValue)
        maxLabel.textAlignment = .center
        maxLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        maxLabel.textColor = UIColor.white
        maxLabel.backgroundColor = UIColor.clear
        maxLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(maxLabel)
        
        c1 = NSLayoutConstraint(item: maxLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        
        cMax = NSLayoutConstraint(item: maxLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: -( r / 2.0) )
        
        
        self.addConstraint(c1)
        self.addConstraint(cMax!)
        
    }
    
    func d2R(_ degs : Double ) -> CGFloat{
        return CGFloat(degs / 180.0 * M_PI)
    }
    
    func drawCursor(_ value : Double, len : CGFloat, width : CGFloat, color : UIColor, center : CGPoint ){
        
        // OK now draw cursor
        let bz = UIBezierPath()
        
        color.setStroke()
        bz.lineWidth = width
        
        let ang = d2R(value)
        
        let pt = CGPoint(x: center.x + len * CGFloat(cos(ang)), y: center.y + len * CGFloat(sin(ang)))
        
        bz.move(to: center)
        bz.addLine(to: pt)
        
        bz.stroke()
    }
    
    func drawArc(_ start : Double, end : Double, r : CGFloat, width : CGFloat, color : UIColor, center : CGPoint){
        let bz = UIBezierPath()
        
        color.setStroke()
        bz.lineWidth = width * r
        
        let startAng = d2R(start)
        let endAng = d2R(end)
        
        bz.addArc(withCenter: center, radius: r * (1.0-width), startAngle:startAng, endAngle:endAng, clockwise: true)
        
        bz.stroke()
        
    }
    
    
    
    override func draw(_ rect: CGRect) {
        
        // Get graphics context
        let aContext = UIGraphicsGetCurrentContext()
        
        aContext?.saveGState()
        
        // Get the radius
        
        let r : CGFloat = (min(self.bounds.width, self.bounds.height) / 2.0)-1.0
        let l  : CGFloat = r * startEndLength
        
        // Update size labels and position
        
        valueLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        minLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        maxLabel.font = UIFont(name: ".SFUIText-Light", size: r / 4.0)
        
        if let c = cValue {
            c.constant = -(r / 2.0)
        }
        
        if let c = cMin {
            c.constant = (r / 2.0)
        }
        
        if let c = cMax {
            c.constant = -(r / 2.0)
        }
        
        let center = CGPoint(x: self.bounds.width/2.0, y:self.bounds.height/2.0)
        
        // Draw sphere
        
        sphereColor.setStroke()
        var bz = UIBezierPath()
        bz.lineWidth = sphereWidth
        
        bz.addArc(withCenter: center, radius: r, startAngle:0.0, endAngle:CGFloat(2.0 * M_PI), clockwise: true)
        
        bz.stroke()
        
        // Now put the ticks that show just top and bottom
        
        bz = UIBezierPath()
        bz.move(to: CGPoint(x: center.x - r + l, y:center.y))
        bz.addLine(to: CGPoint(x: center.x - r, y:center.y))
        bz.stroke()
        
        bz = UIBezierPath()
        bz.move(to: CGPoint(x: center.x + r - l, y:center.y))
        bz.addLine(to: CGPoint(x: center.x + r, y:center.y))
        bz.stroke()
        
        // Now we draw the lines :
        
        // Value line
        
        UIColor.green.setStroke()
        
        bz = UIBezierPath()
        var a = -d2R((value * scale) )
        bz.move(to: CGPoint(x: center.x + r * cos(a), y:center.y + r * sin(a)))
        bz.addLine(to: CGPoint(x: center.x - r * cos(a), y:center.y - r * sin(a)))
        bz.stroke()
        
        
        UIColor.red.setStroke()
        
        bz = UIBezierPath()
        a = -d2R((minValue * scale) )
        bz.move(to: CGPoint(x: center.x + r * cos(a), y:center.y + r * sin(a)))
        bz.addLine(to: CGPoint(x: center.x - r * cos(a), y:center.y - r * sin(a)))
        bz.stroke()
        
        bz = UIBezierPath()
        a = -d2R((maxValue * scale))
        bz.move(to: CGPoint(x: center.x + r * cos(a), y:center.y + r * sin(a)))
        bz.addLine(to: CGPoint(x: center.x - r * cos(a), y:center.y - r * sin(a)))
        bz.stroke()
        
        
        
        aContext?.restoreGState()
        
        // Drawing code
        
        super.draw(rect)
    }
    
    func updateData(_ value : Double, minValue : Double, maxValue : Double, scale : Double){
        
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


