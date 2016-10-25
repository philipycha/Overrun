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
    var coorArray: [CLLocationCoordinate2D]? = []
    var totalDistance:Double = 0
    var lastKnownLocation = CLLocation()
    var uID: String?
    var runTime: Double = 0
    var averageSpeed: Double = 0
    var currentUser: User?
    
    
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
    
    convenience init(uID: String, coorArray: [CLLocationCoordinate2D]) {
        self.init()
        self.uID = uID
        self.coorArray = coorArray
    }
    
    func createRunningLine() -> GMSPolyline {
        
        let runPath = GMSMutablePath()
        
        for location in runLocations {
            runPath.add(location.coordinate)
        }

        let polyline = GMSPolyline(path: runPath)
        return polyline
    }
    
    func createPulledShape() -> GMSPolygon{
        let path = GMSMutablePath()
        
        for coordinate in coorArray!{
            path.add(coordinate)
        }
        let shape = GMSPolygon(path: path)
        return shape
    }
    
    func convertToPath(coordinates: [CLLocationCoordinate2D]) -> GMSPath {
        
        let path = GMSMutablePath()
        for coor in coordinates {
            path.add(coor)
        }
        return path
    }
    
    func createNewShape(user: User, runsArray: [Run]) -> GMSPolygon {
        smartArray = makeSmartCoordinateArrayfrom(runLocations: runLocations)
    
        currentUser = user
        
        var pulledPathArray = [GMSMutablePath]()
        
        for run in runsArray {
            pulledPathArray.append(convertToPath(coordinates: run.coorArray!) as! GMSMutablePath)
        }
        
        var averageSpeed: Double = 0
        
        for location in runLocations {
            averageSpeed += location.speed
            averageSpeed = averageSpeed / Double(runLocations.count)
        }
        
        self.averageSpeed = averageSpeed
        
        let startTime = runLocations.first?.timestamp
        let endTime = runLocations.last?.timestamp
        
        let runTime = endTime?.timeIntervalSince(startTime!)
        
        self.runTime = runTime!

        let runPath = GMSMutablePath()
        
        for location in smartArray {
            runPath.add(location.coordinate)
        }
        
        let newShape = GMSPolygon(path: runPath)
        
        newShape.holes = pulledPathArray
        
        storeNewShapes()
        
        return newShape
        
    }
    
    func storeNewShapes() {
        
        let ref = FIRDatabase.database().reference()
        
        var i = 0
        
        var dbCoordinates = [[[String : String]]]()
        
        for coordinate in smartArray {
            i += 1
            
            let long = String(format: "%f", coordinate.coordinate.longitude)
            let lat = String(format: "%f", coordinate.coordinate.latitude)
            
            dbCoordinates.append([["long" : long],["lat" : lat]])
        }
        
        guard let userName = currentUser?.userName else {
            print("username is nil")
            return
        }
        
        
        let key = ref.child("Runs").childByAutoId().key
        let run = ["coordinates" : dbCoordinates,
                   "username" : userName,
                   "speed" : self.averageSpeed,
                   "time" : self.runTime
                    ] as [String : Any]

        let runsUpdates = ["/Runs/\(key)" : run]
        ref.updateChildValues(runsUpdates)
        
    }
    
    func calculateDistance() {
        if runLocations.count > 1 {
            totalDistance += (runLocations.last?.distance(from: lastKnownLocation))!
        }
        lastKnownLocation = runLocations.last!
    }
}
