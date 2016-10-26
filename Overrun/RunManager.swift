//
//  RunManager.swift
//  Overrun
//
//  Created by Tevin Maker on 2016-10-25.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import CoreLocation
import GoogleMaps

protocol RunManagerDelegate {
    func displayNewShapeWith(newShape: GMSPolygon)
    var pulledRunArray : [Run] { get set }
    
}

class MyCoordinate2D: Hashable, Equatable {
    
    var longitude:Double!
    var latitude:Double!
    
    var hashValue: Int{
        return Int(longitude)
    }
    
//    init(withCor) {
//        <#statements#>
//    }
    
    static func ==(lhs: MyCoordinate2D, rhs: MyCoordinate2D) -> Bool {
        return lhs.longitude == rhs.longitude &&
            rhs.latitude == lhs.latitude
    }
    
}

class RunManager: NSObject {

    var delegate: RunManagerDelegate?
    var pulledRunsArray = [Run]()
    
    private let sharedRunManager = RunManager()
    class RunManager {
        class var sharedInstance: RunManager {
            return self.sharedInstance
        }
    }
    
    func pullRunsFromFirebase() {
        
        let shapeRef = FIRDatabase.database().reference()
        shapeRef.child("Runs").observe(FIRDataEventType.value) { (shapeSnap: FIRDataSnapshot) in
            
            if let snapDict = shapeSnap.value as? NSDictionary{
                
                for snapRun in snapDict{
                    
                    let uID = snapRun.key as? String
                    
                    let run = snapRun.value as? NSDictionary
                    
                    var coordinateArray = [CLLocationCoordinate2D]()
                    
                    let runCoordinates = run?.value(forKey: "coordinates") as! NSArray
                    
                    
                    for snapCoordinate in runCoordinates{
                        let coordinate = snapCoordinate as! NSArray
                        
                        let longDict = coordinate[0] as! NSDictionary
                        let latDict = coordinate[1] as! NSDictionary
                        
                        let long:String = longDict.value(forKey: "long") as! String
                        
                        let lat:String = latDict.value(forKey: "lat") as! String
                        
                        let longCoor = Double(long)
                        
                        let latCoor = Double(lat)
                        
                        let runCoordinate = CLLocationCoordinate2D(latitude: latCoor!, longitude: longCoor!)
                        
                        coordinateArray.append(runCoordinate)
                    }
                    
                    let pulledRun = Run(uID: uID!, coorArray: coordinateArray)
                    
                    self.delegate?.displayNewShapeWith(newShape: pulledRun.createPulledShape())
                    self.delegate?.pulledRunArray.append(pulledRun)
                    self.pulledRunsArray.append(pulledRun)
                }
            }
        }
    }
    


    
    func checkShapeIntersection(existingRuns: [Run], activeRun: Run) -> [CLLocationCoordinate2D]{
        
        var newShapeDict = [CLLocation : CLLocation]()
        var pulledShapeDict = [CLLocation : CLLocation]()
        
        var intersectingCoorArray = [CLLocationCoordinate2D]()
        
        for existingRun in existingRuns{
            
            var indexNewP1 = 0
            var indexNewP2 = 1
            
            for _ in 0..<(activeRun.smartArray.count) - 1{
                
                if indexNewP2 == activeRun.smartArray.count - 1{
                    
                    indexNewP1 = 0
                }
                
                let newP1 = activeRun.smartArray[indexNewP1].coordinate
                let newP2 = activeRun.smartArray[indexNewP2].coordinate
                
                var indexPulledP3 = 0
                var indexPulledP4 = 1
                
                for _ in 0..<(existingRun.coorArray?.count)! - 1{
                    
                    if indexPulledP4 == (existingRun.coorArray?.count)! - 1{
                        
                        indexPulledP3 = 0
                    }
                    
                    let pulledP3 = existingRun.coorArray?[indexPulledP3]
                    let pulledP4 = existingRun.coorArray?[indexPulledP4]
                    
                    let d1 = ((newP2.longitude) - (newP1.longitude))*((pulledP4?.latitude)! - (pulledP3?.latitude)!)
                    let d2 = ((newP2.latitude) - (newP1.latitude))*((pulledP4?.longitude)! - (pulledP3?.longitude)!)
                    let d = d1 - d2
                    if (d == 0) {
                        print("LINES ARE PARALLEL")
                        
                        let p4Coor = CLLocation(latitude: (pulledP4?.latitude)!, longitude: (pulledP4?.longitude)!)
                        let p3Coor = CLLocation(latitude: (pulledP3?.latitude)!, longitude: (pulledP3?.longitude)!)
                        pulledShapeDict[p3Coor] = p4Coor
                        
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
                            
                            let p4Coor = CLLocation(latitude: (pulledP4?.latitude)!, longitude: (pulledP4?.longitude)!)
                            let p3Coor = CLLocation(latitude: (pulledP3?.latitude)!, longitude: (pulledP3?.longitude)!)
                            pulledShapeDict[p3Coor] = p4Coor

                            
                            indexPulledP3 += 1
                            indexPulledP4 += 1
                            print("P3: %d", indexPulledP3)
                            print("P4: %d", indexPulledP4)
                            
                        } else if (v < 0.0 || v > 1.0){
                            print("INTERSECTION POINT NOT BETWEEN p3 and p4")
                            
                            let p4Coor = CLLocation(latitude: (pulledP4?.latitude)!, longitude: (pulledP4?.longitude)!)
                            let p3Coor = CLLocation(latitude: (pulledP3?.latitude)!, longitude: (pulledP3?.longitude)!)
                            pulledShapeDict[p3Coor] = p4Coor
                            
                            indexPulledP3 += 1
                            indexPulledP4 += 1
                            print("P3: %d", indexPulledP3)
                            print("P4: %d", indexPulledP4)
                            
                        } else {
                            
                            let intersectingCoor = CLLocationCoordinate2D(latitude: ((newP1.latitude) + u * ((newP2.latitude) - (newP1.latitude))), longitude: ((newP1.longitude) + u * ((newP2.longitude) - (newP1.longitude))))
                            print(intersectingCoor)
                            intersectingCoorArray.append(intersectingCoor)
                            let p1Coor = CLLocation(latitude: newP1.latitude, longitude: newP1.longitude)
                            newShapeDict[p1Coor] = CLLocation(latitude: intersectingCoor.latitude, longitude: intersectingCoor.longitude)
                            let p3Coor = CLLocation(latitude: (pulledP3?.latitude)!, longitude: (pulledP3?.longitude)!)
                            pulledShapeDict[p3Coor] = CLLocation(latitude: intersectingCoor.latitude, longitude: intersectingCoor.longitude)
                            
                            indexPulledP3 += 1
                            indexPulledP4 += 1
                            print("P3: %d", indexPulledP3)
                            print("P4: %d", indexPulledP4)
                        }
                    }
                }
                if indexNewP1 == activeRun.smartArray.count{
                    break
                }
                
                let p1Coor = CLLocation(latitude: newP1.latitude, longitude: newP1.longitude)
                let p2Coor = CLLocation(latitude: newP2.latitude, longitude: newP2.longitude)

                newShapeDict[p1Coor] = p2Coor

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
