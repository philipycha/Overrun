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
    @IBOutlet var startRunButtonView: UIView!
    @IBOutlet var endRunButtonView: UIView!
    @IBOutlet var endRunButton: UIButton!
    
    let locationManager = LocationManager()
    var mapView:GMSMapView!
    var centerCoordinate: CLLocationCoordinate2D?
    var activeRun: Run! = nil
    var polylineArray: [GMSPolyline] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = GMSMapView()
        
        endRunButtonView.isHidden = true
        
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.currentLocation.coordinate.latitude, longitude: locationManager.currentLocation.coordinate.longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.isMyLocationEnabled = true
        view.insertSubview(mapView, at: 0)
        
    }

    func displayRunLineWith(polyline: GMSPolyline) {
        polyline.strokeColor = UIColor.black
        polyline.strokeWidth = 5
        polyline.map = mapView
        polylineArray.append(polyline)
    }

    func updateCamera() {
        
       let updatedCamera = GMSCameraPosition(target: locationManager.currentLocation.coordinate, zoom: 17, bearing: 0, viewingAngle: 0)
        mapView.camera = updatedCamera
    }
 
    @IBAction func startRunButtonPressed(_ sender: AnyObject) {
        if activeRun == nil {
            activeRun = Run()
            locationManager.passRunToLocationManagerForTracking(activeRun: activeRun)
            startRunButtonView.isHidden = true
            endRunButtonView.isHidden = false
            
        }
    }
    
    @IBAction func endRunButtonPressed(_ sender: AnyObject) {
        if activeRun != nil {
//          store run and send to DB
//          create shape
            activeRun = nil
            locationManager.activeRun = activeRun
            startRunButtonView.isHidden = false
            endRunButtonView.isHidden = true
            for polyline in polylineArray {
                polyline.map = nil
            }
            
        }
        
    }
    
}
