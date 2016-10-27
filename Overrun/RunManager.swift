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
import MapKit

protocol RunManagerDelegate {
    func displayNewShapeWith(newShape: GMSPolygon)
    var pulledRunArray : [Run] { get set }
    
}

class MyCoordinate2D: NSObject {
    
    var longitude:Double!
    var latitude:Double!
    
    override var hash: Int {
        return (longitude + latitude).hashValue
    }
    
    init(with coordinate: CLLocationCoordinate2D) {
        super.init()
        
        longitude = coordinate.longitude
        latitude = coordinate.latitude
    }
    
    func coordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? MyCoordinate2D {
            return longitude == object.longitude &&
                latitude == object.latitude
        } else {
            return false
        }
    }
}

class RunManager: NSObject {

    var losingShapeArray = [MyCoordinate2D]()
    var delegate: RunManagerDelegate?
    var pulledRunsArray = [Run]()
    var winningRun = Run()
    var losingRun = Run()
    
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
    
    func checkShapeIntersection(existingRun: Run, activeRun: Run){
        
        var newShapeDict = [MyCoordinate2D : MyCoordinate2D]()
        var pulledShapeDict = [MyCoordinate2D : MyCoordinate2D]()
        
        var intersectingCoorArray = [CLLocationCoordinate2D]()
        
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
                    
                    if (indexNewP2 == (activeRun.smartArray.count) - 1) {
                        
                        let p4Coor = MyCoordinate2D(with: pulledP4!)
                        let p3Coor = MyCoordinate2D(with: pulledP3!)
                        
                        pulledShapeDict[p3Coor] = p4Coor
                        
                        print("KeyP3: \(p3Coor)")
                        print("ValueP4: \(p4Coor)")
                    }
                    
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
                        
                        if (indexNewP2 == (activeRun.smartArray.count) - 1) {
                            
                            let p4Coor = MyCoordinate2D(with: pulledP4!)
                            let p3Coor = MyCoordinate2D(with: pulledP3!)
                            
                            pulledShapeDict[p3Coor] = p4Coor
                            
                            print("KeyP3: \(p3Coor)")
                            print("ValueP4: \(p4Coor)")
                            
                        }
                        
                        indexPulledP3 += 1
                        indexPulledP4 += 1
                        print("P3: %d", indexPulledP3)
                        print("P4: %d", indexPulledP4)
                        
                    } else if (v < 0.0 || v > 1.0){
                        print("INTERSECTION POINT NOT BETWEEN p3 and p4")
                        
                        if (indexNewP2 == (activeRun.smartArray.count) - 1) {
                            
                            let p4Coor = MyCoordinate2D(with: pulledP4!)
                            let p3Coor = MyCoordinate2D(with: pulledP3!)
                            
                            pulledShapeDict[p3Coor] = p4Coor
                            
                            print("KeyP3: \(p3Coor)")
                            print("ValueP4: \(p4Coor)")
                            
                        }
                        
                        indexPulledP3 += 1
                        indexPulledP4 += 1
                        print("P3: %d", indexPulledP3)
                        print("P4: %d", indexPulledP4)
                        
                    } else {
                        
                        let intersectingCoor = CLLocationCoordinate2D(latitude: ((newP1.latitude) + u * ((newP2.latitude) - (newP1.latitude))), longitude: ((newP1.longitude) + u * ((newP2.longitude) - (newP1.longitude))))
                        print(intersectingCoor)
                        intersectingCoorArray.append(intersectingCoor)
                        
                        let intersectCoor = MyCoordinate2D(with: intersectingCoor)
                        
                        let p1Coor = MyCoordinate2D(with: newP1)
                        let p2Coor = MyCoordinate2D(with: newP2)
                    
                        newShapeDict[p1Coor] = intersectCoor
                        
                        print("KeyP1: \(p1Coor)")
                        print("ValueIntersect: \(intersectCoor)")
                        
                        newShapeDict[intersectCoor] = p2Coor
                        
                        print("KeyIntersect: \(intersectCoor)")
                        print("ValueP1: \(p1Coor)")
                        
                        let p3Coor = MyCoordinate2D(with: pulledP3!)
                        let p4Coor = MyCoordinate2D(with: pulledP4!)
                        
                        pulledShapeDict[p3Coor] = intersectCoor
                        
                        print("KeyP3: \(p3Coor)")
                        print("ValueIntersect: \(intersectCoor)")
                        
                        pulledShapeDict[intersectCoor] = p4Coor
                        
                        print("KeyIntersect: \(intersectCoor)")
                        print("ValueP3: \(p3Coor)")
                        
                        
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
            
            let p1Coor = MyCoordinate2D(with: newP1)
            let p2Coor = MyCoordinate2D(with: newP2)
            
            newShapeDict[p1Coor] = p2Coor
            
            print("KeyP1: \(p1Coor)")
            print("ValueP2: \(p2Coor)")
            
            indexNewP1 += 1
            indexNewP2 += 1
            
//            print("P1: %d", indexNewP1)
//            print("P2: %d", indexNewP2)
        }
        
        let losingRun = findLoserWithSpeed(activeRun: activeRun, existingRun: existingRun)
        
        if losingRun == activeRun {
            
            cutLoserShapeBeginningWith(previousCoor: MyCoordinate2D(with: activeRun.smartArray.last!.coordinate), losingDict: newShapeDict, winningDict: pulledShapeDict)
            activeRun.shapeArray = losingShapeArray
            for coor in existingRun.coorArray!{
                
                let location = MyCoordinate2D(with: coor)
                existingRun.shapeArray?.append(location)
            }
            activeRun.storeNewShape()
            existingRun.storeNewShape()
            
            
        } else {
            
            let existingCoor = CLLocation(latitude: (existingRun.coorArray?.last?.latitude)!, longitude: (existingRun.coorArray?.first?.longitude)!)
            
            let myExistingCoor = MyCoordinate2D(with: existingCoor.coordinate)
            
            cutLoserShapeBeginningWith(previousCoor: myExistingCoor, losingDict: pulledShapeDict, winningDict: newShapeDict)
            
            existingRun.shapeArray = losingShapeArray
            
            for coor in activeRun.smartArray {
                
                let myCoor = MyCoordinate2D(with: coor.coordinate)
                activeRun.shapeArray?.append(myCoor)
            }
            
            activeRun.storeNewShape()
            existingRun.storeNewShape()
        }
    }
    
    func cutLoserShapeBeginningWith(previousCoor: MyCoordinate2D, losingDict: [MyCoordinate2D :MyCoordinate2D], winningDict: [MyCoordinate2D : MyCoordinate2D]){
        
        var nextCoor = winningDict[previousCoor]
        
        if losingShapeArray.count == 0 {
            if nextCoor == nil {
                
                nextCoor = losingDict[previousCoor]
                losingShapeArray.append(nextCoor!)
                self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: winningDict, winningDict: losingDict)
                
            }
            
            nextCoor = winningDict[previousCoor]
            losingShapeArray.append(nextCoor!)
            self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: losingDict, winningDict: winningDict)
            
        } else if losingDict[losingShapeArray.last!] != losingShapeArray.first!   {
            
            if nextCoor == nil {
                
                nextCoor = losingDict[previousCoor]
                losingShapeArray.append(nextCoor!)
                self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: winningDict, winningDict: losingDict)
                
            }
            
            nextCoor = winningDict[previousCoor]
            losingShapeArray.append(nextCoor!)
            self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: losingDict, winningDict: winningDict)

        }
    }
    
    func findLoserWithSpeed(activeRun: Run, existingRun: Run) -> Run{
        
        if existingRun.averageSpeed > activeRun.averageSpeed {
            return activeRun
        } else {
            return existingRun
        }
        
    }
}
