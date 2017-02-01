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
    func displayNewShapeWith(newShape: GMSPolygon, username: String)
    var pulledRunArray : [Run] { get set }
    
}

class MyCoordinate2D: NSObject {
    
    var longitude:Double!
    var latitude:Double!
    var hasBeenChecked = false
    
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
    var activeRun: Run?
    var existingRun: Run?
    var losingShapeCheckArray = [MyCoordinate2D]()
    var intersectionCheckList = [MyCoordinate2D]()
    var startingIntersectionPoint: MyCoordinate2D?
    
    
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
                    
                    let username = run?.value(forKey: "username") as! String
                    
                    let averageSpeed = run?.value(forKey: "speed") as! Double
                    
                    let time = run?.value(forKey: "time") as! Double
                    
                    let runCoordinates = run?.value(forKey: "coordinates") as! NSArray
                    
                    var pulledShapeArray = [MyCoordinate2D]()
                    
                    for snapCoordinate in runCoordinates{
                        let coordinate = snapCoordinate as! NSArray
                        
                        let longDict = coordinate[0] as! NSDictionary
                        let latDict = coordinate[1] as! NSDictionary
                        
                        let long:String = longDict.value(forKey: "long") as! String
                        
                        let lat:String = latDict.value(forKey: "lat") as! String
                        
                        let longCoor = Double(long)
                        
                        let latCoor = Double(lat)
                        
                        let runCoordinate = CLLocationCoordinate2D(latitude: latCoor!, longitude: longCoor!)
                        
                        pulledShapeArray.append(MyCoordinate2D(with: runCoordinate))
                        coordinateArray.append(runCoordinate)
                    }
                    
                    let pulledRun = Run(uID: uID!, coorArray: coordinateArray, shapeArray: pulledShapeArray, speed: averageSpeed, time: time, username: username)
                    
                    self.delegate?.displayNewShapeWith(newShape: pulledRun.createPulledShape(), username: pulledRun.username!)
                    self.delegate?.pulledRunArray.append(pulledRun)
                    self.pulledRunsArray.append(pulledRun)
                    
                }
            }
        }
    }
    
    func createIntersectingDictionaries(existingRun: Run, activeRun: Run) -> (previousCoor: MyCoordinate2D, newShapeDict: [MyCoordinate2D :MyCoordinate2D], pulledShapeDict: [MyCoordinate2D : MyCoordinate2D]) {
        
        var newShapeConArray = [MyCoordinate2D]()
        var pulledShapeconArray = [MyCoordinate2D]()
        
        newShapeConArray.append(MyCoordinate2D(with: (activeRun.smartArray.first?.coordinate)!))
        pulledShapeconArray.append(MyCoordinate2D(with: (existingRun.coorArray?.first)!))
        
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
            
            var loopCounter = 0
            
            for _ in 0..<((existingRun.coorArray?.count)!) {
                
                
                
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
                    
                    // insert code to not break if users are running along the same line
                    
                    if (indexNewP2 == (activeRun.smartArray.count) - 1) {
                        
                        let p4Coor = MyCoordinate2D(with: pulledP4!)
                        let p3Coor = MyCoordinate2D(with: pulledP3!)
                        
                        if pulledShapeDict[p3Coor] == nil {
                            
                            // No intersection
                            
                            pulledShapeDict[pulledShapeconArray.last!] = p4Coor
                            pulledShapeconArray.append(p4Coor)
                            
                        }
                    }
                    
                    indexPulledP3 += 1
                    indexPulledP4 += 1
                    
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
                                
                                pulledShapeDict[pulledShapeconArray.last!] = p4Coor
                                pulledShapeconArray.append(p4Coor)
                                
                                print("point a: \(pulledShapeconArray.last)\npoint b: \(p4Coor.latitude)\(p4Coor.longitude)")
                            }
                        }
                        
//                        indexPulledP3 += 1
//                        indexPulledP4 += 1
                        
                    } else if (v < 0.0 || v > 1.0){
                        print("INTERSECTION POINT NOT BETWEEN p3 and p4")
                        
                        if (indexNewP2 == (activeRun.smartArray.count) - 1) {
                            
                            let p4Coor = MyCoordinate2D(with: pulledP4!)
                            let p3Coor = MyCoordinate2D(with: pulledP3!)
                            
                            p4Coor.index = indexPulledP4
                            p3Coor.index = indexPulledP3
                            
                            if pulledShapeDict[p3Coor] == nil {
                                
                                // No intersection
                                
                                pulledShapeDict[pulledShapeconArray.last!] = p4Coor
                                pulledShapeconArray.append(p4Coor)
                                
                                print("point a: \(pulledShapeconArray.last)\npoint b: \(p4Coor.latitude)\(p4Coor.longitude)")
            
                            }
                        }
                        
//                        indexPulledP3 += 1
//                        indexPulledP4 += 1

                        
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
                        intersectCoor.index = 9999
                        
                        newShapeDict[newShapeConArray.last!] = intersectCoor
                        
                        print("point a: \(newShapeConArray.last)\npoint b: \(intersectCoor.latitude)\(intersectCoor.longitude)")
                        
                        newShapeConArray.append(intersectCoor)
                        
                        let p3Coor = MyCoordinate2D(with: pulledP3!)
                        let p4Coor = MyCoordinate2D(with: pulledP4!)
                        
                        p4Coor.index = indexPulledP4
                        p3Coor.index = indexPulledP3
                        
                        pulledShapeDict[pulledShapeconArray.last!] = intersectCoor ///////
                        
                        print("point a: \(pulledShapeconArray.last)\npoint b: \(intersectCoor.latitude)\(intersectCoor.longitude)")
                        
                        pulledShapeconArray.append(intersectCoor)
                        intersectionCheckList.append(intersectCoor)

                    }
                    if pulledShapeDict[pulledShapeconArray.last!] == nil {
                        
                        let p4Coor = MyCoordinate2D(with: pulledP4!)
                        
                        pulledShapeDict[pulledShapeconArray.last!] = p4Coor
                        
                        pulledShapeconArray.append(p4Coor)
                        
                        print("point a: \(pulledShapeconArray.last)\npoint b: \(p4Coor.latitude)\(p4Coor.longitude)")
                        
                        indexPulledP3 += 1
                        indexPulledP4 += 1
                    }
                }
                
                loopCounter += 1
                print(loopCounter)
            }

            let p1Coor = MyCoordinate2D(with: newP1)
            let p2Coor = MyCoordinate2D(with: newP2)
            
            
            p1Coor.index = indexNewP1
            p2Coor.index = indexNewP2
            
            if newShapeDict[newShapeConArray.last!] == nil {
                
                // No intersection
                
                newShapeDict[newShapeConArray.last!] = p2Coor
                newShapeConArray.append(p2Coor)
                
                print("point a: \(newShapeConArray.last)\npoint b: \(p2Coor.latitude)\(p2Coor.longitude)")
            }
            
            indexNewP1 += 1
            indexNewP2 += 1
            
            
        } // end of for loop
        
        for coor in newShapeDict {
            print("new")
            print(coor.key.coordinate())
            print(coor.value.coordinate())
            
        }
        
        for coor in pulledShapeDict {
            print("pulled")
            print(coor.key.coordinate())
            print(coor.value.coordinate())
            
        }
        
        return (previousCoor: newShapeDict.keys.first!, newShapeDict: newShapeDict, pulledShapeDict: pulledShapeDict)
    }
    
    func checkShapeIntersection(existingRun: Run, activeRun: Run, previousCoor: MyCoordinate2D, newShapeDict: [MyCoordinate2D :MyCoordinate2D], pulledShapeDict: [MyCoordinate2D : MyCoordinate2D]) {
        
        var newShapeArray = [MyCoordinate2D]()
        
        for newCoor in activeRun.smartArray {
            
            let coor = MyCoordinate2D(with: newCoor.coordinate)
            newShapeArray.append(coor)
        }
        
        var existingShapeArray = [MyCoordinate2D]()
        
        for existingCoor in existingRun.coorArray! {
            
            let coor = MyCoordinate2D(with: existingCoor)
            existingShapeArray.append(coor)
            
        }
        
        let losingRun = findLoserWithSpeed(activeRun: activeRun, existingRun: existingRun)
        
        if losingRun == activeRun {
            
            losingShapeCheckArray = Array(newShapeDict.keys)
            
            for coordinate in intersectionCheckList{
                
                if coordinate.hasBeenChecked == false{
                    
                    cutLoserShapeBeginningWith(previousCoor: coordinate, currentDict: newShapeDict, otherDict: pulledShapeDict, winningShapePath: existingShapeArray, losingShapePath: newShapeArray, isOnWinningPath: false)
                    
                    activeRun.shapeArray = losingShapeArray
                    existingRun.shapeArray = existingShapeArray
                    activeRun.storeNewShape()
                    
                    self.activeRun = activeRun
                    self.existingRun = existingRun
                }
            }
        } else {
            
            losingShapeCheckArray = Array(pulledShapeDict.keys)
            
            for coordinate in intersectionCheckList {
                
                if coordinate.hasBeenChecked == false{
                    
                    cutLoserShapeBeginningWith(previousCoor: coordinate, currentDict: pulledShapeDict, otherDict: newShapeDict, winningShapePath: newShapeArray, losingShapePath: existingShapeArray, isOnWinningPath: false)
                    
                    existingRun.shapeArray = losingShapeArray
                    
                    activeRun.shapeArray = newShapeArray
                    activeRun.storeNewShape()
                    existingRun.overwriteExistingShape()
                    
                    self.activeRun = activeRun
                    self.existingRun = existingRun
                }
            }
        }
    }
    
    func findUncheckedIntersectionIn(checkList: [MyCoordinate2D]){
        
        for coor in checkList{
            
            if coor.hasBeenChecked == false{
                startingIntersectionPoint = coor
            }
        }
        
    }
    
    func cutLoserShapeBeginningWith(previousCoor: MyCoordinate2D, currentDict: [MyCoordinate2D :MyCoordinate2D], otherDict: [MyCoordinate2D : MyCoordinate2D], winningShapePath: [MyCoordinate2D], losingShapePath: [MyCoordinate2D], isOnWinningPath: Bool){
        
        if (otherDict[previousCoor] == nil && currentDict[previousCoor] == nil) {
            print("AHHHHHHHH!!!!! \(previousCoor)")
        }
        
//        if previousCoor.hasBeenChecked == true{
//            
//            return
//            
//        }
        
        if losingShapeArray.count == 0 {
            
            var nextCoor = otherDict[previousCoor]
            
            if nextCoor?.hasBeenChecked == false {
    
                
            } else {
                
                
                
            }
            if nextCoor != nil {
                
                
                if isPointInPolygon(myPoint: otherDict[previousCoor]!, path: losingShapePath) && isOnWinningPath == false{
                    // runs while current is inside winning shape and not on intersection
                    // looking at next point to see if inside losingShape
                    
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                    
                } else if !isPointInPolygon(myPoint: otherDict[previousCoor]!, path: losingShapePath) && isOnWinningPath == false{
                    
                    //if point is not in winning polygon and not on winning path filp otherpath and hop onto other path
                    // other terms joining winning path
                    
                    let invertedDictionary = invert(originalDict: otherDict)
                    
                    nextCoor = invertedDictionary[previousCoor]
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: invertedDictionary, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                    
                } else if isPointInPolygon(myPoint: otherDict[previousCoor]!, path: winningShapePath) && isOnWinningPath == true{
                    
                    // if point is in other polygon and on winning path flip other and hop on
                    // other terms rejoin losing path
                    
                    let invertedDictionary = invert(originalDict: otherDict)
                    
                    nextCoor = invertedDictionary[previousCoor]
                    
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: invertedDictionary, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                }
                
            } else if isPointInPolygon(myPoint: previousCoor, path: winningShapePath) {
                
                if isOnWinningPath {
                    
                    // continue down path
                    nextCoor = currentDict[previousCoor]
                    
                    moveAlongCurrentPath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
                    return
                } else {
                    
                    // hop to next poiont without adding point to array
                    nextCoor = currentDict[previousCoor]
                    
                    let index = losingShapeCheckArray.index(of: previousCoor)
                    losingShapeCheckArray[index!].hasBeenChecked = true
                    
                    cutLoserShapeBeginningWith(previousCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
                    return
                }
                
            } else {
                
                // continue down path
                
                nextCoor = currentDict[previousCoor]
                moveAlongCurrentPath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
                return
            }
            
        } else if !losingShapeArray.contains(currentDict[previousCoor]!){
            
            var nextCoor = otherDict[previousCoor]
            if nextCoor != nil {
                
                if isPointInPolygon(myPoint: nextCoor!, path: losingShapePath) && isOnWinningPath == false{
                    
                    // runs while current is inside winning shape and not on intersection
                    // looking at next point to see if inside losingShape
                    
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                } else if !isPointInPolygon(myPoint: nextCoor!, path: losingShapePath) && isOnWinningPath == false{
                    
                    //if point is not in winning polygon and not on winning path filp otherpath and hop onto other path
                    // other terms joining winning path
                    
                    let invertedDictionary = invert(originalDict: otherDict)
                    
                    nextCoor = invertedDictionary[previousCoor]
                    
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: invertedDictionary, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                    
                } else if isPointInPolygon(myPoint: nextCoor!, path: winningShapePath) && isOnWinningPath == true{
                    
                    // if point is in other polygon and on winning path flip other and hop on
                    // other terms rejoin losing path
                    
                    let invertedDictionary = invert(originalDict: otherDict)
                    
                    nextCoor = invertedDictionary[previousCoor]
                    
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: invertedDictionary, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                } else if isPointInPolygon(myPoint: nextCoor!, path: losingShapePath) && isOnWinningPath == true{
                    
                    // continue down path
                    
                    moveAlongOtherShapePath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: !isOnWinningPath)
                    return
                    
                }
                
            } else if isPointInPolygon(myPoint: previousCoor, path: winningShapePath) {
                
                if isOnWinningPath {
                    nextCoor = currentDict[previousCoor]
                    
                    // continue down path
                    
                    moveAlongCurrentPath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
                    return
                } else {
                    
                    // hop to next poiont without adding point to array
                    
                    nextCoor = currentDict[previousCoor]
                    
                    let index = losingShapeCheckArray.index(of: previousCoor)
                    losingShapeCheckArray[index!].hasBeenChecked = true
                    
                    cutLoserShapeBeginningWith(previousCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
                    return
                }
                
            } else {
                
                // continue down path
                
                nextCoor = currentDict[previousCoor]
                moveAlongCurrentPath(nextCoor: nextCoor!, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
                return
            }
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
    
    
    func isPointInPolygon(myPoint: MyCoordinate2D, path: [MyCoordinate2D]) -> Bool{
        let myPath = GMSMutablePath()
        for coor in path{
            
            let myCoor = CLLocationCoordinate2D(latitude: coor.latitude, longitude: coor.longitude)
            myPath.add(myCoor)
        }
        
        let point = CLLocationCoordinate2D(latitude: myPoint.latitude, longitude: myPoint.longitude)
        
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
    
    func moveAlongCurrentPath(nextCoor: MyCoordinate2D, currentDict: [MyCoordinate2D : MyCoordinate2D], otherDict: [MyCoordinate2D : MyCoordinate2D], winningShapePath: [MyCoordinate2D], losingShapePath: [MyCoordinate2D], isOnWinningPath: Bool){
        losingShapeArray.append(nextCoor)
        
        if intersectionCheckList.contains(nextCoor){
            nextCoor.hasBeenChecked = true
        }
        
//        let index = losingShapeCheckArray.index(of: nextCoor)
//        losingShapeCheckArray[index!].hasBeenChecked = true
        
        self.cutLoserShapeBeginningWith(previousCoor: nextCoor, currentDict: currentDict, otherDict: otherDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
        return
        
    }
    
    func moveAlongOtherShapePath(nextCoor: MyCoordinate2D, currentDict: [MyCoordinate2D : MyCoordinate2D], otherDict: [MyCoordinate2D : MyCoordinate2D], winningShapePath: [MyCoordinate2D], losingShapePath: [MyCoordinate2D], isOnWinningPath: Bool){
        
//        let index = losingShapeCheckArray.index(of: nextCoor)
//        losingShapeCheckArray[index!].hasBeenChecked = true
        
        losingShapeArray.append(nextCoor)
        
        if intersectionCheckList.contains(nextCoor){
            nextCoor.hasBeenChecked = true
        }
        
        self.cutLoserShapeBeginningWith(previousCoor: nextCoor, currentDict: otherDict, otherDict: currentDict, winningShapePath: winningShapePath, losingShapePath: losingShapePath, isOnWinningPath: isOnWinningPath)
        return
    }
    
    func makeActiveShapeClockwise(){
        
        var totalCourse: Double = 0
        
        var courseArray = [Double]()
        
        for location in (activeRun?.smartArray)!{
            
            var courseDifference:Double = 0
            
            if courseArray.count > 0 {
                
                courseDifference = location.course - courseArray.last!
                
            } else {
             
                courseDifference = location.course
                
            }
            
            courseArray.append(location.course as Double)
            totalCourse += courseDifference
            
        }
        
        if totalCourse < 0 {
            
            activeRun?.smartArray.reverse()
            
        }
    }
}
