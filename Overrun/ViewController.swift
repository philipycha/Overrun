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
import SceneKit

class ViewController: UIViewController, GMSMapViewDelegate, LocationManagerDelegate, SignInDelegate, RunManagerDelegate {
    
    @IBOutlet weak var PlayerAnimationView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet var startRunButton: UIButton!
    @IBOutlet var startRunButtonView: UIView!
    @IBOutlet var endRunButtonView: UIView!
    @IBOutlet var endRunButton: UIButton!
    
    let locationManager = LocationManager()
    let runManager = RunManager()
    var mapView:GMSMapView!
    var centerCoordinate: CLLocationCoordinate2D?
    
    var activeRun: Run! = nil
    var polylineArray: [GMSPolyline] = []
    
    var pulledRunArray = [Run]()

    var currentUser: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runManager.delegate = self
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = PlayerAnimationView as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
        // configure the view
        scnView.backgroundColor = UIColor.clear
        
        // add a tap gesture recognizer
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
//        scnView.addGestureRecognizer(tapGesture)
        
        
        
        mapView = GMSMapView()
        
        endRunButtonView.isHidden = true
        
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.currentLocation.coordinate.latitude, longitude: locationManager.currentLocation.coordinate.longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
//        mapView.isMyLocationEnabled = true
        
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
        
        runManager.pullRunsFromFirebase()
        
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
        newShape.map = mapView
    }

    func updateCamera() {
        
       let updatedCamera = GMSCameraPosition(target: locationManager.currentLocation.coordinate, zoom: 17.5, bearing: mapView.camera.bearing, viewingAngle: 45)
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
            

            let newShape = activeRun.createNewShape(user: currentUser)
            
            activeRun.smartArray = activeRun.makeSmartCoordinateArrayfrom(runLocations: activeRun.runLocations)
            
//          **//Only comparing first run//**
            
//            runManager.checkShapeIntersection(existingRun: pulledRunArray.first!, activeRun: activeRun)
            
            DispatchQueue.global().async {
                
                let (previousCoor, newShapeDict, pullShapeDict) = self.runManager.createIntersectingDictionaries(existingRun: self.pulledRunArray.first!, activeRun: self.activeRun)
                
                self.runManager.checkShapeIntersection(existingRun: self.pulledRunArray.first!, activeRun: self.activeRun, previousCoor: previousCoor, newShapeDict: newShapeDict, pulledShapeDict: pullShapeDict)
                
                self.activeRun = nil
                self.locationManager.activeRun = self.activeRun
                
                DispatchQueue.main.async {
                    view.setNeedsDisplay()
                }
                
            }
            
            
//            for point in intersectingCoor {
//                let marker = GMSMarker(position: point)
//                marker.map = mapView
//            }
            
            displayNewShapeWith(newShape: newShape)

            for polyline in polylineArray {
                polyline.map = nil
            }
            
            
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
