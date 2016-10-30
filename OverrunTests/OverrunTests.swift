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
    
    func testToDetermineIfTwoDictionariesAreCreatedWithCyclicalArray() {
        
        let runManager = RunManager()
        
        let pulledRun = Run()
        let activeRun = Run()
        
        let smartArray = [
                        CLLocation(latitude: 40, longitude: 40),
                        CLLocation(latitude: 60, longitude: 40),
                        CLLocation(latitude: 70, longitude: 60),
                        CLLocation(latitude: 60, longitude: 100),
                        CLLocation(latitude: 40, longitude: 100)
        ]
        
        let coorArray = [
                            CLLocationCoordinate2D(latitude: 50, longitude: 50),
                            CLLocationCoordinate2D(latitude: 50, longitude: 80),
                            CLLocationCoordinate2D(latitude: 80, longitude: 80),
                            CLLocationCoordinate2D(latitude: 80, longitude: 50)
        ]
        
        pulledRun.coorArray = coorArray
        activeRun.smartArray = smartArray
        pulledRun.averageSpeed = 10
        activeRun.averageSpeed = 50
        
        
        let (previousCoor, newShapeDict, pullShapeDict) = runManager.createIntersectingDictionaries(existingRun: pulledRun, activeRun: activeRun)
            
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
