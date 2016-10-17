//
//  ViewController.swift
//  Overrun
//
//  Created by Philip Ha on 2016-10-14.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import Mapbox

class ViewController: UIViewController, MGLMapViewDelegate, LocationManagerDelegate {
    
    let locationManager = LocationManager()
    let mapView = MGLMapView()
    var centerCoordinate: CLLocationCoordinate2D?
    var camera: MGLMapCamera?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        
        mapView.showsUserLocation = true
        
        mapView.styleURL = MGLStyle.outdoorsStyleURL(withVersion: 9);
        
        // User Location
        centerCoordinate = locationManager.currentLocation.coordinate
        
//        guard let centerCoordinate = centerCoordinate else {
//            print("no centerCoordinate")
//            return
//        }
        
        // Optionally set a starting point.
        
        view.addSubview(mapView)
    }
    
    func updateCamera() {
        // User Location
        centerCoordinate = locationManager.currentLocation.coordinate
        
        guard let centerCoordinate = centerCoordinate else {
            print("no centerCoordinate")
            return
        }
        let updatedCamera = MGLMapCamera(lookingAtCenter: centerCoordinate, fromDistance: 100, pitch: 20, heading: 0)

        mapView.camera = updatedCamera
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Wait for the map to load before initiating the first camera movement.
        
        // Create a camera that rotates around the same center point, rotating 180°.
        // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.
        let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 4500, pitch: 15, heading: 180)
        
        // Animate the camera movement over 5 seconds.
        mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
    }
}

