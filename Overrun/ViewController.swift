//
//  ViewController.swift
//  Overrun
//
//  Created by Philip Ha on 2016-10-14.
//  Copyright © 2016 Philip Ha. All rights reserved.
//

import GoogleMaps
import FirebaseAuth
import FirebaseDatabase


class ViewController: UIViewController, GMSMapViewDelegate, LocationManagerDelegate, SignInDelegate {
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet var startRunButton: UIButton!
    @IBOutlet var startRunButtonView: UIView!
    @IBOutlet var endRunButtonView: UIView!
    @IBOutlet var endRunButton: UIButton!
    
    let locationManager = LocationManager()
    var mapView:GMSMapView!
    var centerCoordinate: CLLocationCoordinate2D?
    
    var activeRun: Run! = nil
    var polylineArray: [GMSPolyline] = []

    var currentUser: User!
    
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
        
        distanceView.isHidden = true
        
        let rootRef = FIRDatabase.database().reference()
        rootRef.child("Runs").observe(FIRDataEventType.childAdded) { (runSnap: FIRDataSnapshot) in
            print("NEW SHAPE")
        }
        
        
    }
    
    func assignCurrentUser(currentUser: User) {
        self.currentUser = currentUser
    }
    
    func displayDistance(distance: Double) {

            let distanceInt = Int(distance)
            
            let distanceStr = String(format: "%i", distanceInt)
            
            distanceLabel.text = distanceStr
        
        
    }

    func displayRunLineWith(polyline: GMSPolyline) {
        polyline.strokeColor = UIColor.black
        polyline.strokeWidth = 5
        polyline.map = mapView
        polylineArray.append(polyline)
    }
    
    func displayNewShapeWith(newShape: GMSPolygon) {
        newShape.strokeColor = UIColor.blue
        newShape.fillColor = UIColor.orange
        newShape.map = mapView
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
            distanceView.isHidden = false
        }
    }
    
    
    @IBAction func endRunButtonPressed(_ sender: AnyObject) {
        if activeRun != nil {
//          store run and send to DB
//          create shape
            
            
            startRunButtonView.isHidden = false
            endRunButtonView.isHidden = true
            distanceView.isHidden = true
            
            displayNewShapeWith(newShape: activeRun.createNewShape())

            
            for polyline in polylineArray {
                polyline.map = nil
            }
            
            activeRun = nil
            locationManager.activeRun = activeRun
        }
    }
    
    @IBAction func signOut(_ sender: UIButton) {
//        AppState.sharedInstance.signedIn = false
//        dismiss(animated: true, completion: nil)
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            dismiss(animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError.localizedDescription)")
        }
        
    }
    
}
