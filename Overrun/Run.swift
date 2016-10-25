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
    
    func createNewShape(user: User) -> GMSPolygon {
        smartArray = makeSmartCoordinateArrayfrom(runLocations: runLocations)
    
        currentUser = user
        
        var averageSpeed: Double = 0
        
        for location in runLocations {
            averageSpeed += location.speed
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
    
    func checkShapeIntersection(existingRuns: [Run]) -> [CLLocationCoordinate2D]{
        
        var intersectingCoorArray = [CLLocationCoordinate2D]()
        
        for specificRun in existingRuns{
            
            var indexNewP1 = 0
            var indexNewP2 = 1
            
             for _ in 0..<(smartArray.count) - 1{
                
                var indexPulledP3 = 0
                var indexPulledP4 = 1
                
                for _ in 0..<(specificRun.coorArray?.count)! - 1{
                    
                    let newP1 = self.smartArray[indexNewP1].coordinate
                    let newP2 = self.smartArray[indexNewP2].coordinate
                    
                    let pulledP3 = specificRun.coorArray?[indexPulledP3]
                    let pulledP4 = specificRun.coorArray?[indexPulledP4]
                
                    let d1 = ((newP2.longitude) - (newP1.longitude))*((pulledP4?.latitude)! - (pulledP3?.latitude)!)
                    let d2 = ((newP2.latitude) - (newP1.latitude))*((pulledP4?.longitude)! - (pulledP3?.longitude)!)
                    let d = d1 - d2
                    if (d == 0) {
                        print("LINES ARE PARALLEL")
                        
                        indexPulledP3 += 1
                        indexPulledP4 += 1
                        print("P3: %d", indexPulledP3)
                        print("P4: %d", indexPulledP4)
                        
                    } else {
                        
                        let u1 = ((pulledP3?.longitude)! - (newP1.longitude))*((pulledP4?.latitude)! - (pulledP3?.latitude)!)
                        let u2 = ((pulledP3?.latitude)! - (newP1.latitude))*((pulledP4?.longitude)! - (pulledP3?.longitude)!)
                        let u = (u1 - u2)/d
                        
                        let v1 = ((pulledP3?.longitude)! - (newP1.longitude))*((newP2.latitude) - (newP1.latitude))
                        let v2 = ((pulledP3?.latitude)! - (newP1.latitude))*((newP2.longitude) - (newP1.longitude))
                        let v = (v1 - v2)/d
                        
                        if (u < 0.0 || u > 1.0){
                            print("INTERSECTION POINT NOT BETWEEN p1 and p2")
                            indexPulledP3 += 1
                            indexPulledP4 += 1
                            print("P3: %d", indexPulledP3)
                            print("P4: %d", indexPulledP4)
                        
                        } else if (v < 0.0 || v > 1.0){
                            print("INTERSECTION POINT NOT BETWEEN p3 and p4")
                            indexPulledP3 += 1
                            indexPulledP4 += 1
                            print("P3: %d", indexPulledP3)
                            print("P4: %d", indexPulledP4)
                            
                        } else {
                            
                            let intersectingCoor = CLLocationCoordinate2D(latitude: ((newP1.latitude) + u * ((newP2.latitude) - (newP1.latitude))), longitude: ((newP1.longitude) + u * ((newP2.longitude) - (newP1.longitude))))
                            print(intersectingCoor)
                            indexPulledP3 += 1
                            indexPulledP4 += 1
                            print("P3: %d", indexPulledP3)
                            print("P4: %d", indexPulledP4)
                            intersectingCoorArray.append(intersectingCoor)
                        }
                    }
                }
                if indexNewP1 == smartArray.count{
                    break
                }
                indexNewP1 += 1
                indexNewP2 += 1
                
                print("P1: %d", indexNewP1)
                print("P2: %d", indexNewP2)
            }
        }
        print(intersectingCoorArray.count)
        return intersectingCoorArray
    }
}
