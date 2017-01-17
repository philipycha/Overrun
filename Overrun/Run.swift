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
import MapKit

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
    var shapeArray = [MyCoordinate2D]()
    var username: String?
    
    convenience init(user: User) {
        self.init()
        
        self.currentUser = user
        self.username = user.userName
    }
    
    func makeSmartCoordinateArrayfrom(runLocations: [CLLocation]) -> [CLLocation] {
        
        let startTime = runLocations.first?.timestamp
        let endTime = runLocations.last?.timestamp
        
        let runTime = endTime?.timeIntervalSince(startTime!)
        
        self.runTime = runTime!
        
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
    
    func assignSmartArrayAsShapeArray(){
        
        for coor in smartArray{
            
            let myCoor = MyCoordinate2D(with: coor.coordinate)
            shapeArray.append(myCoor)
        }
    }
    
    func resverseArrayIfArrayIsNotClockwise(locationArray: [CLLocation]) -> [CLLocation] {
        
        let currentIndex = 0
        var nextIndex = 1
        var bearingCounter: Double = 0
        
        for _ in 0 ..< locationArray.count {
            
            var currentBearing = locationArray[currentIndex].course 
            let nextBearing = locationArray[nextIndex].course 
            
            bearingCounter = nextBearing - currentBearing
            currentBearing += 1
            nextIndex += 1
        }
        
        if bearingCounter > 0 {
            return locationArray
        } else {
            
            return locationArray.reversed()
        }
    }
    
    convenience init(uID: String, coorArray: [CLLocationCoordinate2D], shapeArray: [MyCoordinate2D], speed: Double, time: Double, username: String) {
        self.init()
        self.uID = uID
        self.coorArray = coorArray
        self.shapeArray = shapeArray
        self.averageSpeed = speed
        self.username = username
        self.runTime = time
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
    
    func createNewShape() -> GMSPolygon {

        let runPath = GMSMutablePath()
        
        for location in shapeArray {
            let coor = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            
            runPath.add(coor)
        }
        
        let newShape = GMSPolygon(path: runPath)
        
        
        return newShape
        
    }
    
    
    func deleteShape() {
        
        let ref = FIRDatabase.database().reference()
        
        let runRef = ref.child("Runs").child(uID!)
        
        runRef.removeValue()
        
    }
    
    func overwriteExistingShape() {
        
        let ref = FIRDatabase.database().reference()
        
        let key = ref.child("Runs").child(uID!).key
        
        var dbCoordinates = [[[String : String]]]()
        
        var i = 0
        for coordinateValue in shapeArray {
            i += 1
            
            let coordinate = coordinateValue.coordinate()
            
            let long = String(format: "%f", coordinate.longitude)
            let lat = String(format: "%f", coordinate.latitude)
            
            dbCoordinates.append([["long" : long],["lat" : lat]])
        }

        guard let nameStr = username else{
            
            return
        }
        
        let run = ["coordinates" : dbCoordinates,
                   "username" : nameStr,
                   "speed" : self.averageSpeed,
                   "time" : self.runTime
                    ] as [String : Any]

        let childUpdates = ["/Runs/\(key)" : run]
        
        ref.updateChildValues(childUpdates)
    }
    
    
    func storeNewShape() {
        
        let ref = FIRDatabase.database().reference()
        
        var i = 0
        
        var dbCoordinates = [[[String : String]]]()
        
        for coordinateValue in shapeArray {
            i += 1
            
            let coordinate = coordinateValue.coordinate()
            
            let long = String(format: "%f", coordinate.longitude)
            let lat = String(format: "%f", coordinate.latitude)
            
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
    
    func calculateAvgSpeed(){
        var averageSpeed: Double = 0
        
        if runLocations.count > 1 {
            
            for location in runLocations {
                averageSpeed += location.speed
            }
            
            averageSpeed = averageSpeed / Double(runLocations.count)
            
            self.averageSpeed = averageSpeed
            
        }
        
    }
}
