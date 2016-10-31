//
//  OverrunTests.swift
//  OverrunTests
//
//  Created by Tevin Maker on 2016-10-28.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Overrun

class OverrunTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
//    
//    func testIsAPointOnAShapeEdgeInSideTheShape() {
//        
//        let runManager = RunManager()
//        
//        let run = Run()
//        
//        let shapeArray = [
//                            MyCoordinate2D(with: CLLocationCoordinate2D(latitude: 1, longitude: 1)),
//                            MyCoordinate2D(with: CLLocationCoordinate2D(latitude: 1, longitude: 5)),
//                            MyCoordinate2D(with: CLLocationCoordinate2D(latitude: 5, longitude: 1)),
//                            MyCoordinate2D(with: CLLocationCoordinate2D(latitude: 5, longitude: 5)),
//        ]
//        
//        let point = MyCoordinate2D(with: CLLocationCoordinate2D(latitude: 1, longitude: 1))
//        
//        
//        let isPointInShape = runManager.isPointInPolygon(myPoint: point, path: shapeArray)
//        
//        
//    
//    }
//    
    
    func testToDetermineIfTwoDictionariesAreCreatedWithCyclicalArray() {
        
        let runManager = RunManager()
        
        let pulledRun = Run()
        let activeRun = Run()
        
        let smartArray = [
                        CLLocation(latitude: 100, longitude: 100),
                        CLLocation(latitude: 70, longitude: 30),
                        CLLocation(latitude: 30, longitude: 30),
                        CLLocation(latitude: 20, longitude: 70),
                        CLLocation(latitude: 40, longitude: 90)
        ]
        
        let coorArray = [
                            CLLocationCoordinate2D(latitude: 10, longitude: 10),
                            CLLocationCoordinate2D(latitude: 50, longitude: 20),
                            CLLocationCoordinate2D(latitude: 60, longitude: 60),
                            CLLocationCoordinate2D(latitude: 30, longitude: 50)
        ]
        
        pulledRun.coorArray = coorArray
        activeRun.smartArray = smartArray
        pulledRun.averageSpeed = 10
        activeRun.averageSpeed = 50
        
        let user1 = User(userName: "PHIL", email: "PHIL", uid: "PHIL")
        let user2 = User(userName: "McTesterson", email: "McTesterson", uid: "McTesterson")
        
        activeRun.currentUser = user1
        
        pulledRun.currentUser = user2
        
        let (previousCoor, newShapeDict, pullShapeDict) = runManager.createIntersectingDictionaries(existingRun: pulledRun, activeRun: activeRun)
        
        for (key, value) in pullShapeDict{
            
            print("pulled -- key: \(key.coordinate()), value: \(value.coordinate())")
            
        }
        
        print("")
        
        for (key, value) in newShapeDict{
            
            print("new -- key: \(key.coordinate()), value: \(value.coordinate())")
            
        }
            
        runManager.checkShapeIntersection(existingRun: pulledRun, activeRun: activeRun, previousCoor: previousCoor, newShapeDict: newShapeDict, pulledShapeDict: pullShapeDict)
        
        for coor in coorArray {
            
            let myCoor = MyCoordinate2D(with: coor)
            
            XCTAssertNotNil(pullShapeDict[myCoor], "\(coor) has no value in pulledShapeDict")
            
        }
        
        for coor in smartArray {
            
            let myCoor = MyCoordinate2D(with: coor.coordinate)
                
                XCTAssertNotNil(newShapeDict[myCoor], "\(coor.coordinate) has no value in pulledShapeDict")
            
        }
        
    }
    
}
