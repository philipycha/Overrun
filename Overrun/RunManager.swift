//
//  RunManager.swift
//  Overrun
//
//  Created by Tevin Maker on 2016-10-25.
//  Copyright © 2016 Philip Ha. All rights reserved.



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

//extension Dictionary {
//    
//    func invert() -> Dictionary <Any:Hashable, Any:Hashable> {
//        
//        var invertedDictionary = [Any: Any]()
//        
//        for (key, value) in self{
//            invertedDictionary[value] = key
//        }
//        
//        return invertedDictionary
//    }
//    
//}

class MyCoordinate2D: NSObject {
    
    var longitude:Double!
    var latitude:Double!
    
    var index:Int?
    
    
    
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
    var onWinningPath = false
    
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
    
    func createIntersectingDictionaries(existingRun: Run, activeRun: Run) -> (previousCoor: MyCoordinate2D, newShapeDict: [MyCoordinate2D :MyCoordinate2D], pulledShapeDict: [MyCoordinate2D : MyCoordinate2D]) {
        
        var newShapeDict = [MyCoordinate2D : MyCoordinate2D]() // active run
        var pulledShapeDict = [MyCoordinate2D : MyCoordinate2D]() // existing run
        
        var intersectingCoorArray = [CLLocationCoordinate2D]() // All intersecting coordinates between lines from different shapes
        
        var indexNewP1 = 0
        var indexNewP2 = 1
        
        for _ in 0..<(activeRun.smartArray.count) {
            
            if indexNewP1 == activeRun.smartArray.count - 1{
                
                indexNewP2 = 0
            }
            
            let newP1 = activeRun.smartArray[indexNewP1].coordinate
            let newP2 = activeRun.smartArray[indexNewP2].coordinate
            
            var indexPulledP3 = 0
            var indexPulledP4 = 1
            
            for _ in 0..<(existingRun.coorArray?.count)! {
                
                if indexPulledP3 == (existingRun.coorArray?.count)! - 1{
                    
                    indexPulledP4 = 0
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
                       
                        if pulledShapeDict[p3Coor] == nil {
                            
                            // No intersection
                            
                            pulledShapeDict[p3Coor] = p4Coor
                            
                            print("KeyP3: \(p3Coor)")
                            print("ValueP4: \(p4Coor)")
                            
                        }
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
                            
                            if pulledShapeDict[p3Coor] == nil {
                                
                                // No intersection
                                
                                pulledShapeDict[p3Coor] = p4Coor
                                
                                print("KeyP3: \(p3Coor)")
                                print("ValueP4: \(p4Coor)")
                            }
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
                            
                            p4Coor.index = indexPulledP4
                            p3Coor.index = indexPulledP3
                            
                            if pulledShapeDict[p3Coor] == nil {
                                
                                // No intersection
                                
                                pulledShapeDict[p3Coor] = p4Coor
                                
                                print("KeyP3: \(p3Coor)")
                                print("ValueP4: \(p4Coor)")
                                
                            }
                        }
                        
                        indexPulledP3 += 1
                        indexPulledP4 += 1
                        print("P3: %d", indexPulledP3)
                        print("P4: %d", indexPulledP4)
                        
                    } else {
                        // Lines do intersect 
                        
                        let intersectingCoor = CLLocationCoordinate2D(latitude: ((newP1.latitude) + u * ((newP2.latitude) - (newP1.latitude))), longitude: ((newP1.longitude) + u * ((newP2.longitude) - (newP1.longitude))))
                        print(intersectingCoor)
                        intersectingCoorArray.append(intersectingCoor)
                        
                        let intersectCoor = MyCoordinate2D(with: intersectingCoor)
                        
                        let p1Coor = MyCoordinate2D(with: newP1)
                        let p2Coor = MyCoordinate2D(with: newP2)
                        
                        p1Coor.index = indexNewP1
                        p2Coor.index = indexNewP2
                        intersectCoor.index = 9999999999999
                    
                        newShapeDict[p1Coor] = intersectCoor
                        
                        print("KeyP1: \(p1Coor)")
                        print("ValueIntersect: \(intersectCoor)")
                        
                        newShapeDict[intersectCoor] = p2Coor
                        
                        print("KeyIntersect: \(intersectCoor)")
                        print("ValueP1: \(p1Coor)")
                        
                        let p3Coor = MyCoordinate2D(with: pulledP3!)
                        let p4Coor = MyCoordinate2D(with: pulledP4!)
                        
                        p4Coor.index = indexPulledP4
                        p3Coor.index = indexPulledP3
                        
                        pulledShapeDict[p3Coor] = intersectCoor ///////
                        
                        print("KeyP3: \(p3Coor)")
                        print("ValueIntersect: \(intersectCoor)")
                        
                        pulledShapeDict[intersectCoor] = p4Coor ////////
                        
                        print("KeyIntersect: \(intersectCoor)")
                        print("ValueP3: \(p3Coor)")
                        
                        
                        indexPulledP3 += 1
                        indexPulledP4 += 1
                        print("P3: %d", indexPulledP3)
                        print("P4: %d", indexPulledP4)
                    }
                }
            }
//            if indexNewP1 == activeRun.smartArray.count{
//                break
//            }
            
            
            
            let p1Coor = MyCoordinate2D(with: newP1)
            let p2Coor = MyCoordinate2D(with: newP2)
            

            p1Coor.index = indexNewP1
            p2Coor.index = indexNewP2
            
            if newShapeDict[p1Coor] == nil {
                
                // No intersection

                
                newShapeDict[p1Coor] = p2Coor
                
                print("KeyP1: \(p1Coor)")
                print("ValueP2: \(p2Coor)")

            }
            
            indexNewP1 += 1
            indexNewP2 += 1

            

//            print("P1: %d", indexNewP1)
//            print("P2: %d", indexNewP2)
        } // end of for loop
        
        return (previousCoor: newShapeDict.keys.first!, newShapeDict: newShapeDict, pulledShapeDict: pulledShapeDict)
    }
    
    func checkShapeIntersection(existingRun: Run, activeRun: Run, previousCoor: MyCoordinate2D, newShapeDict: [MyCoordinate2D :MyCoordinate2D], pulledShapeDict: [MyCoordinate2D : MyCoordinate2D]) {
     
        
        
        let losingRun = findLoserWithSpeed(activeRun: activeRun, existingRun: existingRun)
        
        if losingRun == activeRun {
            
            cutLoserShapeBeginningWith(previousCoor: newShapeDict.keys.first!, losingDict: newShapeDict, winningDict: pulledShapeDict)
            activeRun.shapeArray = losingShapeArray
            for coor in existingRun.coorArray!{
                
                let location = MyCoordinate2D(with: coor)
                existingRun.shapeArray?.append(location)
            }
        } else {
            
            cutLoserShapeBeginningWith(previousCoor: pulledShapeDict.keys.first!, losingDict: pulledShapeDict, winningDict: newShapeDict)
            
            existingRun.shapeArray = losingShapeArray
            
            for coor in activeRun.smartArray {
                
                let myCoor = MyCoordinate2D(with: coor.coordinate)
                activeRun.shapeArray?.append(myCoor)
            }
        }
        activeRun.storeNewShape()
        existingRun.storeNewShape()
    }

    func cutLoserShapeBeginningWith(previousCoor: MyCoordinate2D, losingDict: [MyCoordinate2D :MyCoordinate2D], winningDict: [MyCoordinate2D : MyCoordinate2D]){
        
        var nextCoor = winningDict[previousCoor]
        
        if (winningDict[previousCoor] == nil && losingDict[previousCoor] == nil) {
            print("AHHHHHHHH!!!!! \(previousCoor)")
        }
        
        if losingShapeArray.count == 0 {
            if nextCoor == nil {
                
                nextCoor = losingDict[previousCoor]
                losingShapeArray.append(nextCoor!)
                self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: losingDict, winningDict: winningDict)
                
            } else {
//
//                var invertedWinningDict = [MyCoordinate2D : MyCoordinate2D]()
//                
//                if onWinningPath == false{
//                    invertedWinningDict = invert(originalDict: winningDict)
//                    onWinningPath = true
//                
                    nextCoor = winningDict[previousCoor]
                    losingShapeArray.append(nextCoor!)
                    self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: winningDict, winningDict: losingDict)
                
//                } else {
//                    self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: winningDict, winningDict: losingDict)
//
//                }
            }
        
        } else if losingDict[previousCoor] != losingShapeArray.first!   {
            
            if nextCoor == nil {
                
                nextCoor = losingDict[previousCoor]
                losingShapeArray.append(nextCoor!)
                self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: losingDict, winningDict: winningDict)
                
                
            } else {
                
                nextCoor = winningDict[previousCoor]
                losingShapeArray.append(nextCoor!)
                self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: winningDict, winningDict: losingDict)

                
//                var invertedWinningDict = [MyCoordinate2D : MyCoordinate2D]()
                
//                if onWinningPath == false{
//                    invertedWinningDict = invert(originalDict: winningDict)
//                    onWinningPath = true
//                } else {
//                    self.cutLoserShapeBeginningWith(previousCoor: nextCoor!, losingDict: winningDict, winningDict: losingDict)
//                    
//                }
            }
        }
        
        for coordinate in losingShapeArray{
            
            print("lat: \(coordinate.latitude) long: \(coordinate.longitude)")
        }
    }
    
    func findLoserWithSpeed(activeRun: Run, existingRun: Run) -> Run{
        
        if existingRun.averageSpeed > activeRun.averageSpeed {
            return activeRun
        } else {
            return existingRun
        }
        
    }
    

    func invert(originalDict: [MyCoordinate2D : MyCoordinate2D]) -> [MyCoordinate2D : MyCoordinate2D] {
        
        var invertedDictionary = [MyCoordinate2D : MyCoordinate2D]()
        
        for (key, value) in originalDict{
            invertedDictionary[value] = key
        }
        
        return invertedDictionary
    }
        //            let disPulledArray = buildShapeFromKeys(shapeDict: pulledShapeDict)
        //            let disNewArray = buildShapeFromKeys(shapeDict: newShapeDict)
        
        //        for (coor, value) in pulledShapeDict {
        //
        //            print("Key lat: \(coor.latitude), long: \(coor.longitude)")
        //            print("Value lat: \(pulledShapeDict[coor]?.coordinate().latitude), long: \(pulledShapeDict[coor]?.coordinate().longitude)")
        //            print("Value \(value)")
        //        }
        //
        //        for (coor, value) in newShapeDict {
        //
        //            print("lat: \(coor.latitude), long: \(coor.longitude)")
        //            print("Value lat: \(newShapeDict[coor]?.coordinate().latitude), long: \(newShapeDict[coor]?.coordinate().longitude)")
        //            print("Value \(value)")
        //        }
        //            print(disNewArray)
        //            print(disPulledArray)
        //            activeRun.storeNewShape()
        //            existingRun.storeNewShape()
        //        }
    
        //    func buildShapeFromKeys(shapeDict: [MyCoordinate2D:MyCoordinate2D]) -> [MyCoordinate2D]{
        //
        //
        //        var shapeCoorArray = [MyCoordinate2D]()
        //        let keyArray = Array(shapeDict.keys).map{ $0 }
        //        for key in keyArray {
        //            shapeCoorArray.append(shapeDict[key]!)
        //        }
        //        return shapeCoorArray
        //    }
        
    
    func isPointInPolygon(point: CLLocationCoordinate2D, path: [MyCoordinate2D], isInPolygon: Bool) -> Bool{
        let myPath = GMSMutablePath()
        for coor in path{
            
            let myCoor = CLLocationCoordinate2D(latitude: coor.latitude, longitude: coor.longitude)
            myPath.add(myCoor)
        }
    
        if (GMSGeometryContainsLocation(point, myPath, true)) {
           return true
        } else {
           return false
        }
    }
    
    func isPointOnPath(point: CLLocationCoordinate2D, path: [MyCoordinate2D], isOnPath: Bool) -> Bool{
        let myPath = GMSMutablePath()
        for coor in path{
            
            let myCoor = CLLocationCoordinate2D(latitude: coor.latitude, longitude: coor.longitude)
            myPath.add(myCoor)
        }
        
        if (GMSGeometryIsLocationOnPath(point, myPath, true)) {
            return true
        } else {
            return false
        }
    }

    

}
