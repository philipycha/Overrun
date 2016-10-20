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
import FirebaseDatabase

class Run: NSObject {

    var runLocations: [CLLocation] = []
    var smartArray:[CLLocation] = []
    var totalDistance:Double = 0
    var lastKnownLocation = CLLocation()
    func makeSmartCoordinateArrayfrom(runLocations: [CLLocation]) -> [CLLocation] {
        var smartArray: [CLLocation] = []
        var previousLocation: CLLocation?
        
        for location in runLocations {
            
            if previousLocation != nil {
                if !((location.course - (previousLocation?.course)! > -5) && (location.course - (previousLocation?.course)! < 5)){
                    smartArray.append(previousLocation!)
                }
            }
            previousLocation = location
        }
        return smartArray
    }
    
    
    func createRunningLine() -> GMSPolyline {
        
        let runPath = GMSMutablePath()
        
        for location in runLocations {
            runPath.add(location.coordinate)
        }
        let polyline = GMSPolyline(path: runPath)
        return polyline
    }
    
    func createNewShape() -> GMSPolygon {
        smartArray = makeSmartCoordinateArrayfrom(runLocations: runLocations)
        
        let runPath = GMSMutablePath()
        
        for location in smartArray {
            runPath.add(location.coordinate)
        }
        let newShape = GMSPolygon(path: runPath)
        
        storeNewShapes()
        
        return newShape
        
    }
    
    func storeNewShapes() {
        
        let ref = FIRDatabase.database().reference()
        
        var i = 0
        
//        var dbCoordinates = [[ String : [[String : String]]]]()
        var dbCoordinates = [[[String : String]]]()
        
        for coordinate in smartArray {
            i += 1
            
            let long = String(format: "%f", coordinate.coordinate.longitude)
            let lat = String(format: "%f", coordinate.coordinate.latitude)
            
//            let indexStr = String(format: "%i", i)
            
//            let indexValue = [, ["lat" : lat]]
            
            dbCoordinates.append([["long" : long],["lat" : lat]])

        }
        
        let key = ref.child("Runs").childByAutoId().key
        let run = ["coordinates" : dbCoordinates]
        
        let childUpdates = ["/Runs/\(key)" : run]
        ref.updateChildValues(childUpdates)
    
        
    }
    
    func calculateDistance() {
        if runLocations.count > 1 {
            totalDistance += (runLocations.last?.distance(from: lastKnownLocation))!
        }
        lastKnownLocation = runLocations.last!
    }
}
