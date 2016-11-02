//
//  TransitionAnimation.swift
//  Overrun
//
//  Created by Philip Ha on 2016-10-31.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import UIKit
import QuartzCore
import GoogleMaps

class TransitionAnimation: NSObject {
    
    var mapView:GMSMapView!

    func rotateClockwise(view:UIView) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat(M_PI * 2)
        rotateAnimation.duration = 10.0
        rotateAnimation.repeatCount = Float.infinity
        view.layer.add(rotateAnimation, forKey: "transform.rotation")
    }
    
    func rotateSlowClockwise(view:UIView) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0
        rotateAnimation.toValue = CGFloat(M_PI * 2)
        rotateAnimation.duration = 30.0
        rotateAnimation.repeatCount = Float.infinity
        view.layer.add(rotateAnimation, forKey: "transform.rotation")
    }
    
    func rotateCounterClockwise(view:UIView) {
        let rotateReverseAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateReverseAnimation.fromValue = 0
        rotateReverseAnimation.toValue = CGFloat(-M_PI * 2)
        rotateReverseAnimation.duration = 7
        rotateReverseAnimation.repeatCount = Float.infinity
        
        view.layer.add(rotateReverseAnimation, forKey: "transform.rotation")
    }
    
    func drawLine(startPointX:CGFloat, startPointY:CGFloat, endPointX:CGFloat, endPointY:CGFloat) {
        
        let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: startPointX, y: startPointY))
        path.addLine(to: CGPoint(x: endPointX, y: endPointY))
        
        let pathLayer = CAShapeLayer()
        
        pathLayer.frame = mapView.bounds
        pathLayer.path = path.cgPath
        pathLayer.strokeColor = UIColor.white.cgColor
        pathLayer.fillColor = nil
        pathLayer.lineWidth = 2.0
        pathLayer.lineJoin = kCALineJoinBevel
        
        pathAnimation.duration = 2
        pathAnimation.fromValue = 0.0
        pathAnimation.toValue = 1.0
        
        ////Animation will happen right away
        pathLayer.add(pathAnimation, forKey: nil)

    }
    
}
