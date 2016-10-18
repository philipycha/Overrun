//
//  ViewController.swift
//  Overrun
//
//  Created by Philip Ha on 2016-10-14.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import GoogleMaps

class ViewController: UIViewController, GMSMapViewDelegate, LocationManagerDelegate {

    
    let locationManager = LocationManager()
    var mapView:GMSMapView!
    var centerCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = GMSMapView()

        
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.currentLocation.coordinate.latitude, longitude: locationManager.currentLocation.coordinate.longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        view = mapView
    }
    
//    override func loadView() {
//        // Create a GMSCameraPosition that tells the map to display the
//        // coordinate -33.86,151.20 at zoom level 6.
//        
//        
//    }

    
    func locationDidLoad() {
        
//        locationManager.firedOnce = true
    }
    
    func updateCamera() {
        
       let updatedCamera = GMSCameraPosition(target: locationManager.currentLocation.coordinate, zoom: 6, bearing: 0, viewingAngle: 0)
        mapView.camera = updatedCamera
        
    }
    
}
