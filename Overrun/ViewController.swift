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

class ViewController: UIViewController, GMSMapViewDelegate, LocationManagerDelegate, SignInDelegate, RunManagerDelegate, CAAnimationDelegate {
    
    @IBOutlet weak var middleArchStandby: UIView!
    @IBOutlet weak var bigArchStandby: UIView!
    @IBOutlet weak var PlayerAnimationView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet var startRunButton: UIButton!
    @IBOutlet var startRunButtonView: UIView!
    @IBOutlet var endRunButtonView: UIView!
    @IBOutlet var endRunButton: UIButton!
    
    let locationManager = LocationManager()
    let animate = TransitionAnimation()
    let runManager = RunManager()
    var mapView:GMSMapView!
    var centerCoordinate: CLLocationCoordinate2D?
    
    var activeRun: Run! = nil
    var polylineArray: [GMSPolyline] = []
    
    var pulledRunArray = [Run]()
    var intersectingRunSet: Set <Run> = Set()
    
    var currentUser: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runManager.delegate = self
    
        
//        // create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//        
//        // create and add a camera to the scene
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        scene.rootNode.addChildNode(cameraNode)
//        
//        // place the camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
//        
//        // create and add a light to the scene
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light!.type = .omni
//        lightNode.position = SCNVector3(x: 0, y: 5, z: 10)
//        scene.rootNode.addChildNode(lightNode)
//        
//        // create and add an ambient light to the scene
//        let ambientLightNode = SCNNode()
//        ambientLightNode.light = SCNLight()
//        ambientLightNode.light!.type = .ambient
//        ambientLightNode.light!.color = UIColor.darkGray
//        scene.rootNode.addChildNode(ambientLightNode)
//        
//        // retrieve the ship node
//        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
//        
//        // animate the 3d object
//        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 1, z: 0, duration: 1)))
//        
//        // retrieve the SCNView
//        let scnView = PlayerAnimationView as! SCNView
//        
//        // set the scene to the view
//        scnView.scene = scene
//        
//        // allows the user to manipulate the camera
//        scnView.allowsCameraControl = false
//        
//        // show statistics such as fps and timing information
//        scnView.showsStatistics = false
//        
//        // configure the view
//        scnView.backgroundColor = UIColor.clear
        
        mapView = GMSMapView()

    
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.currentLocation.coordinate.latitude, longitude: locationManager.currentLocation.coordinate.longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.isMyLocationEnabled = false
        
        endRunButtonView.isHidden = true
        distanceLabel.isHidden = true
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        
        animate.rotateSlowClockwise(view: startRunButtonView)
        animate.rotateCounterClockwise(view: middleArchStandby)
        animate.rotateClockwise(view: bigArchStandby)
        
//        animate.rotateCounterClockwise(view: endRunButtonView)
        
        
    }
    
    func assignCurrentUser(currentUser: User) {
        self.currentUser = currentUser
    }
    
    func displayDistance(distance: Double) {

            let distanceInt = Int(distance)
            
            let distanceStr = String(format: "%i", distanceInt)
            distanceLabel.text = distanceStr
    }
    
    func dropDownAnimation(label: UILabel) {
        distanceLabel.isHidden = false
        
        let transition = CATransition()
        transition.type = kCATransitionFromTop
        transition.duration = 1
        transition.delegate = self
        label.layer.add(transition, forKey: nil)
        
    }

    func displayRunLineWith(polyline: GMSPolyline) {
        polyline.strokeColor = UIColor.white
        polyline.strokeWidth = 3
        polyline.map = mapView
        polylineArray.append(polyline)
    }
    
    func displayNewShapeWith(newShape: GMSPolygon, username: String) {
        
        if username == currentUser.userName{
            
            newShape.strokeColor = UIColor(colorLiteralRed: 0, green: 2, blue: 25, alpha: 0.4)
            newShape.fillColor = UIColor(colorLiteralRed: 0, green: 0, blue: 50, alpha: 0.2)
            
        } else {
            newShape.strokeColor = UIColor(colorLiteralRed: 100, green: 1, blue: 1, alpha: 0.4)
            newShape.fillColor = UIColor(colorLiteralRed: 50, green: 0, blue: 0, alpha: 0.2)
        }
        newShape.title = username
        newShape.map = mapView
    }

    func updateCamera() {
        
       let updatedCamera = GMSCameraPosition(target: locationManager.currentLocation.coordinate, zoom: 17.5, bearing: mapView.camera.bearing, viewingAngle: 45)
        mapView.camera = updatedCamera
    }
 
    @IBAction func startRunButtonPressed(_ sender: AnyObject) {
        if activeRun == nil {
            activeRun = Run(user: currentUser)
            locationManager.passRunToLocationManagerForTracking(activeRun: activeRun)
//            startRunButtonView.isHidden = true
            startRunButton.isHidden = true
            endRunButtonView.isHidden = false
            distanceView.isHidden = false
            dropDownAnimation(label: distanceLabel)
            mapView.isMyLocationEnabled = true
  
        }
    }
    
    func findIntersectingShapes(){
        DispatchQueue.global().async {
            for run in self.pulledRunArray{
                
                if self.runManager.isPointInPolygon(myPoint: MyCoordinate2D(with: self.locationManager.currentLocation.coordinate), path: run.shapeArray) {
                    self.intersectingRunSet.insert(run)
                }
            }
        }
    }
    
    @IBAction func endRunButtonPressed(_ sender: AnyObject) {
        if activeRun != nil {
            
            startRunButtonView.isHidden = false
            endRunButtonView.isHidden = true
            distanceView.isHidden = true
            
            activeRun.smartArray = activeRun.makeSmartCoordinateArrayfrom(runLocations: activeRun.runLocations)
            
//          **//Only comparing first run//**
            
            
            if intersectingRunSet.count != 0 {
                
                for run in intersectingRunSet{
                    
                    DispatchQueue.global().async {
                        
                        let (previousCoor, newShapeDict, pullShapeDict) = self.runManager.createIntersectingDictionaries(existingRun: run, activeRun: self.activeRun)
                        
                        self.runManager.checkShapeIntersection(existingRun: run, activeRun: self.activeRun, previousCoor: previousCoor, newShapeDict: newShapeDict, pulledShapeDict: pullShapeDict)
                        
                        self.activeRun = nil
                        self.locationManager.activeRun = self.activeRun
                        
                        DispatchQueue.main.async {
                            
                            for polyline in self.polylineArray {
                                polyline.map = nil
                            }
                            
                            self.activeRun = nil
                            self.locationManager.activeRun = nil
                            
                            self.mapView.clear()
                            self.runManager.pullRunsFromFirebase()
                            
                            self.view.setNeedsDisplay()
                        }
                    }
                }
            } else {
                
                activeRun.assignSmartArrayAsShapeArray()
                activeRun.storeNewShape()
                
                let newShape = activeRun.createNewShape()
                displayNewShapeWith(newShape: newShape, username: activeRun.username!)
                
                for polyline in polylineArray {
                    polyline.map = nil
                }
                activeRun = nil
                locationManager.activeRun = nil
                self.view.setNeedsDisplay()
            }
        }
        
        UIView.animate(withDuration: 1.0, delay: 0.1, options: [.curveEaseOut], animations: {
            self.startRunButtonView.center.y = self.startRunButton.center.y
            self.middleArchStandby.center.y = self.startRunButton.center.y
            self.bigArchStandby.center.y = self.startRunButton.center.y
            
            self.animate.revertToNormalSize(view: self.startRunButtonView)
            self.animate.revertToNormalSize(view: self.middleArchStandby)
            self.animate.revertToNormalSize(view: self.bigArchStandby)
            
            }, completion: nil)
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
