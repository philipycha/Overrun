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
    
    var pulledRunArray = [Run]()

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
        
        mapView.settings.zoomGestures = false
        mapView.settings.scrollGestures = false
        
        
        do{
            
            if let styleUrl = Bundle.main.url(forResource: "style", withExtension: "json"){
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleUrl)
                
            }else{
                print("unable to find json")
            }
            
        }catch _ {
            print("error loading GMSMapStyle Json")
        }
        
        
        
        view.insertSubview(mapView, at: 0)
        
        distanceView.isHidden = true
        
        pullRunsFromFirebase()
        
    }
    
    func pullRunsFromFirebase() {
        
        let shapeRef = FIRDatabase.database().reference()
        shapeRef.child("Runs").observe(FIRDataEventType.value) { (shapeSnap: FIRDataSnapshot) in
            
            if let snapDict = shapeSnap.value as? NSDictionary{
                
                for snapRun in snapDict{
                    
                    let uID = snapRun.key as? String
                    
                    let run = snapRun.value as? NSDictionary
                    
                    var coordinateArray = [CLLocationCoordinate2D]()
                    
                    let runCoordinates = run?.value(forKey: "coordinates") as! NSArray
                    
                    
                    for snapCoordinate in runCoordinates{
                        let coordinate = snapCoordinate as! NSArray
                        
                        let longDict = coordinate[0] as! NSDictionary
                        let latDict = coordinate[1] as! NSDictionary
                        
                            let long:String = longDict.value(forKey: "long") as! String
                        
                            let lat:String = latDict.value(forKey: "lat") as! String
                        
                            let longCoor = Double(long)

                            let latCoor = Double(lat)
                            
                            let runCoordinate = CLLocationCoordinate2D(latitude: latCoor!, longitude: longCoor!)
                            
                            coordinateArray.append(runCoordinate)
                    }
                    
                    let pulledRun = Run(uID: uID!, coorArray: coordinateArray)
                    
                    self.displayNewShapeWith(newShape: pulledRun.createPulledShape())
                    self.pulledRunArray.append(pulledRun)
                }
            }
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
        polyline.strokeColor = UIColor.white
        polyline.strokeWidth = 5
        polyline.map = mapView
        polylineArray.append(polyline)
    }
    
    func displayNewShapeWith(newShape: GMSPolygon) {
        newShape.strokeColor = UIColor.white
        newShape.fillColor = UIColor(colorLiteralRed: 0, green: 0, blue: 50, alpha: 0.4)
        
        newShape.geodesic = true
        newShape.map = mapView
    }

    func updateCamera() {
        
       let updatedCamera = GMSCameraPosition(target: locationManager.currentLocation.coordinate, zoom: 17.5, bearing: 0, viewingAngle: 45)
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
            
            displayNewShapeWith(newShape: activeRun.createNewShape(user: currentUser))

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
