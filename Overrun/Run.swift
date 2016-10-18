//
//  Run.swift
//  Overrun
//
//  Created by Tevin Maker on 2016-10-18.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps

class Run: NSObject {

    var runLocations: [CLLocation] = []
    var smartArray:[CLLocation] = []
//    func makeSmartCoordinateArrayfrom(runLocations: [CLLocation]) -> [CLLocation] {
//        
//        var previousLocation: CLLocation?
//        
//        for location in runLocations {
//            
//            if previousLocation != nil {
//                if !((location.course - previousLocation?.course > -10) && (location.course - previousLocation?.course < 10))
//                
//            }
//            
//        }
//    }
    
    
    func createRunningLine() -> GMSPolyline {
        
        let runPath = GMSMutablePath()
        
        for location in runLocations {
            runPath.add(location.coordinate)
        }
        let polyline = GMSPolyline(path: runPath)
        return polyline
    }
    
    func createNewShape() -> GMSPolygon {
        let runPath = GMSMutablePath()
        
        for location in runLocations {
            runPath.add(location.coordinate)
        }
        let newShape = GMSPolygon(path: runPath)
        return newShape
    }
}
