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
    var userTrackingMode: MGLUserTrackingMode?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        

        mapView.setUserTrackingMode(.follow, animated: false)
        
        mapView.showsUserLocation = true
        
        mapView.styleURL = MGLStyle.darkStyleURL(withVersion: 8);
        
        mapView.setUserTrackingMode(.follow, animated: false)
        
        let center = locationManager.currentLocation.coordinate
        
        mapView.setCenter(center, zoomLevel: 7, direction: 0, animated: false)
        
//        mapView.setTargetCoordinate(, animated: false)
        
        
        view.addSubview(mapView)
    }
    
    func locationDidLoad() {
        
//        locationManager.firedOnce = true
    }
    
    func updateCamera() {
        

//        print("\(locationManager.currentLocation)")
//        mapView.setCenter(locationManager.currentLocation.coordinate, zoomLevel: 7, direction: 359, animated: true)

    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        // Wait for the map to load before initiating the first camera movement.
        
        // Create a camera that rotates around the same center point, rotating 180°.
        // `fromDistance:` is meters above mean sea level that an eye would have to be in order to see what the map view is showing.

        let camera = MGLMapCamera(lookingAtCenter: mapView.centerCoordinate, fromDistance: 500, pitch: 15, heading: 180)
//
//        //         Animate the camera movement over 5 seconds.
        mapView.setCamera(camera, withDuration: 5, animationTimingFunction: CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        
    }
}

