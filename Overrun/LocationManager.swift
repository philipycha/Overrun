//
//  LocationManager.swift
//  Overrun
//
//  Created by Tevin Maker on 2016-10-17.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps

protocol LocationManagerDelegate {
    func updateCamera()
    func displayRunLineWith(polyline: GMSPolyline)
    func displayDistance(distance: Double)
    func findIntersectingShapes()
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    let locationManger = CLLocationManager()
    var currentLocation = CLLocation()
    var delegate: LocationManagerDelegate?
    var firedOnce = false
    var activeRun: Run!
    
    private let sharedLocationManager = LocationManager()
    class LocationManager {
        class var sharedInstance: LocationManager {
            return self.sharedInstance
        }
    }

    func startLocationMonitoring() {
        
        if CLLocationManager.locationServicesEnabled() {
            
            if !(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.restricted) || (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.notDetermined) {
                setupLocationManager()
            } else{
                
                let alertController = UIAlertController(title: "Location services are disabled, Please go into Settings > Privacy > Location to enable them for Play", message: "", preferredStyle: .alert)
                
                let ok = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                    
                    
                })
                alertController.addAction(ok)
            }
        }
    }
    
    func setupLocationManager() {
        locationManger.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManger.distanceFilter = 10
        locationManger.delegate = self
        locationManger.requestWhenInUseAuthorization()
        locationManger.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else{
            print("no location")
            return
        }
        
        let eventDate = location.timestamp
        let howRecent = Double.abs(eventDate.timeIntervalSinceNow)
        
        
        if howRecent < 15 {
            currentLocation = location
            
            delegate?.updateCamera()
            
            if activeRun != nil {
                activeRun.runLocations.append(currentLocation)
                delegate?.displayRunLineWith(polyline: activeRun.createRunningLine())
                activeRun.calculateDistance()
                delegate?.displayDistance(distance:activeRun.totalDistance)
                delegate?.findIntersectingShapes()
            }
        }
    }
    
    func passRunToLocationManagerForTracking(activeRun: Run) {
        self.activeRun = activeRun
        
    }
}
