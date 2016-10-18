//
//  ViewController.swift
//  Overrun
//
//  Created by Philip Ha on 2016-10-14.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import GoogleMaps

class ViewController: UIViewController, GMSMapViewDelegate, LocationManagerDelegate {

    @IBOutlet var startRunButton: UIButton!
    
    let locationManager = LocationManager()
    var mapView:GMSMapView!
    var centerCoordinate: CLLocationCoordinate2D?
    var activeRun: Run! = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = GMSMapView()
        
        
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.currentLocation.coordinate.latitude, longitude: locationManager.currentLocation.coordinate.longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.isMyLocationEnabled = true
        view.insertSubview(mapView, at: 0)
    }

    
    func locationDidLoad() {
        
//        locationManager.firedOnce = true
    }
    func updateCamera() {
        
       let updatedCamera = GMSCameraPosition(target: locationManager.currentLocation.coordinate, zoom: 6, bearing: 0, viewingAngle: 0)
        mapView.camera = updatedCamera
        
    }
 
    
    @IBAction func startRunButtonPressed(_ sender: AnyObject) {
        activeRun = Run()
        locationManager.passRunToLocationManagerForTracking(activeRun: activeRun)
    }
    
    
}
