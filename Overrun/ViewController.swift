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
    
    @IBOutlet weak var distanceRedUI: UIImageView!
    @IBOutlet weak var distanceBlueUI: UIImageView!
    @IBOutlet weak var distancePivotView: UIView!
    @IBOutlet weak var endButtonView: UIView!
    @IBOutlet weak var redBigArchStandby: UIView!
    @IBOutlet weak var redMiddleArchStandby: UIView!
    @IBOutlet weak var middleArchStandby: UIView!
    @IBOutlet weak var bigArchStandby: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet var startRunButton: UIButton!
    @IBOutlet var startRunButtonView: UIView!
    @IBOutlet var endRunButtonView: UIView!
    @IBOutlet var endRunButton: UIButton!
    @IBOutlet weak var speedView: UIView!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var menuHeight: NSLayoutConstraint!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var ejectButton: UIButton!
    
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
        
        mapView = GMSMapView()

    
        locationManager.delegate = self
        locationManager.startLocationMonitoring()
        
        let camera = GMSCameraPosition.camera(withLatitude: locationManager.currentLocation.coordinate.latitude, longitude: locationManager.currentLocation.coordinate.longitude, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.isMyLocationEnabled = false
        
        
        view.sendSubview(toBack: endRunButton)
//        endRunButtonView.isHidden = true
        distanceLabel.isHidden = true
        distanceRedUI.isHidden = true
        menuView.isHidden = true
        ejectButton.isHidden = true
        
//        mapView.settings.zoomGestures = false
//        mapView.settings.scrollGestures = false
        
        
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
        speedView.isHidden = true
        
        runManager.pullRunsFromFirebase()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        animate.rotateSlowClockwise(view: startRunButtonView)
        animate.rotateCounterClockwise(view: middleArchStandby)
        animate.rotateClockwise(view: bigArchStandby)
        
        animate.rotateSlowClockwise(view: endButtonView)
        animate.rotateCounterClockwise(view: redMiddleArchStandby)
        animate.rotateClockwise(view: redBigArchStandby)
        
        endButtonView.isHidden = true
        redBigArchStandby.isHidden = true
        redBigArchStandby.isHidden = true
    
    }
    
    func assignCurrentUser(currentUser: User) {
        self.currentUser = currentUser
    }
    
    func displayDistance(distance: Double) {

            let distanceInt = Int(distance)
            
            let distanceStr = String(format: "%i m", distanceInt)
            distanceLabel.text = distanceStr
    }
    
    func displayUserAverageSpeed(speed: Double) {
        
        let speedFloat = Float(speed)
        
        let speedStr = String(format: "%f avg m/s", speedFloat)
        speedLabel.text = speedStr
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
        polyline.strokeColor = UIColor(colorLiteralRed: 0, green: 2, blue: 25, alpha: 0.4)
        polyline.strokeWidth = 2
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
            
            view.bringSubview(toFront: endRunButton)
            view.sendSubview(toBack: startRunButton)
            distanceView.isHidden = false
            speedView.isHidden = false
            
            distanceView.alpha = 0
            speedView.alpha = 0
            
            UIView.animate(withDuration: 0.75, delay: 1, options: [.curveEaseIn], animations: {
                
                self.speedView.alpha = 1
                self.distanceView.alpha = 1
                
                }, completion: { (false) in
                    
            })
            
            distanceLabel.isHidden = false
            distanceLabel.text = "0 m"
            
            endButtonView.isHidden = false
            redBigArchStandby.isHidden = false
            animate.fadeIn(view: endButtonView)
            animate.fadeIn(view: redBigArchStandby)
            
            animate.fadeOut(view: startRunButtonView)
            animate.fadeOut(view: bigArchStandby)
            
            distanceRedUI.isHidden = false
            animate.fadeIn(view: distanceRedUI)
            animate.fadeOut(view: distanceBlueUI)
            
            animate.pivot90CounterClockWise(view: distancePivotView)
            
            UIView.animate(withDuration: 0.5, delay: 0.5, options: [.curveEaseIn], animations: {
                self.mapView.isMyLocationEnabled = true
                }, completion: nil)

            
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
                        
            bigArchStandby.isHidden = false
            
            animate.fadeOut(view: endButtonView)
            animate.fadeOut(view: redBigArchStandby)
            
            animate.fadeIn(view: startRunButtonView)
            animate.fadeIn(view: bigArchStandby)
            
            animate.pivotBackToOrigin(view: distancePivotView)
            
            distanceBlueUI.isHidden = false
            animate.fadeIn(view: distanceBlueUI)
            animate.fadeOut(view: distanceRedUI)
            
            startRunButtonView.isHidden = false
            endRunButtonView.isHidden = true
            
            startRunButton.isHidden = false
            view.bringSubview(toFront: startRunButton)
            view.sendSubview(toBack: endRunButton)
            
            distanceView.isHidden = true
            
            if activeRun.runLocations.count > 4 {
                
                activeRun.smartArray = activeRun.makeSmartCoordinateArrayfrom(runLocations: activeRun.runLocations)
                
            } else {
                
                activeRun = nil
                locationManager.activeRun = nil
            }
            
            if activeRun != nil {
                
                if intersectingRunSet.count != 0 && activeRun.smartArray.count > 4{
                    
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
                                
                                self.mapView.clear()
                                self.runManager.pullRunsFromFirebase()
                                
                                self.view.setNeedsDisplay()
                                
                                self.activeRun = nil
                                self.locationManager.activeRun = nil
                            }
                        }
                    }
                } else if activeRun.smartArray.count > 4{
                    
                    activeRun.assignSmartArrayAsShapeArray()
                    activeRun.storeNewShape()
                    
                    let newShape = activeRun.createNewShape()
                    displayNewShapeWith(newShape: newShape, username: activeRun.username!)
                    
                    for polyline in polylineArray {
                        polyline.map = nil
                    }
                    
                    locationManager.activeRun = nil
                    self.view.setNeedsDisplay()
                    
                    activeRun = nil
                    locationManager.activeRun = nil
                }
            }
        }
    }
    
    @IBAction func MenuButtonPressed(_ sender: UIButton) {
        
        menuDropAnimation()
        
    }
    
    func menuDropAnimation() {
        
        if self.menuHeight.constant == 5 {

            
            self.menuHeight.constant = 150
            //setting menu height to 150
            
            UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
                self.view.layoutIfNeeded()
                self.menuView.isHidden = false
                self.ejectButton.isHidden = false
                }, completion: { (value: Bool) in
                    
            })
            
        }
        
        else {
            self.menuHeight.constant = 5
            
            UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.8, options: .curveLinear, animations: {
                self.view.layoutIfNeeded()
                
                self.ejectButton.isHidden = true
                
                //immediate hidden looks kinda abrupt 
                
                }, completion: { (value: Bool) in
                    self.menuView.isHidden = true
//                    self.menuView.isHidden = true
//                    self.ejectButton.isHidden = true
                    
                    //after it shoots back up there's a delay then it dissapears
                    
            })

        }
        
    }
    @IBAction func testButtonPressed(_ sender: UIButton) {
        
        let activeRun = Run(user: currentUser)
        let pulledRun = pulledRunArray.first
        
        let smartArray = [
//            CLLocation(latitude: 37.329622, longitude: -122.028357),
//            CLLocation(latitude: 37.329985, longitude: -122.028366),
//            CLLocation(latitude: 37.330456, longitude: -122.028402),
//            CLLocation(latitude: 37.330767, longitude: -122.028275),
//            CLLocation(latitude: 37.331275, longitude: -122.027719),
//            CLLocation(latitude: 37.331717, longitude: -122.024437),
//            CLLocation(latitude: 37.330811, longitude: -122.024346),
//            CLLocation(latitude: 37.329916, longitude: -122.024440),
//            CLLocation(latitude: 37.329358, longitude: -122.022671),
//            CLLocation(latitude: 37.330043, longitude: -122.025069),
//            CLLocation(latitude: 37.330457, longitude: -122.025350),
//            CLLocation(latitude: 37.330335, longitude: -122.025465),
//            CLLocation(latitude: 37.330132, longitude: -122.025588),
//            CLLocation(latitude: 37.329687, longitude: -122.026901)
            
            CLLocation(latitude: 37.329637, longitude: -122.027521),
            CLLocation(latitude: 37.330957, longitude: -122.026691),
            CLLocation(latitude: 37.329912, longitude: -122.026345),
            CLLocation(latitude: 37.330972, longitude: -122.025596),
            CLLocation(latitude: 37.329912, longitude: -122.024740),
            CLLocation(latitude: 37.328591, longitude: -122.026005),

        ]
        
        activeRun.smartArray = smartArray
        
        activeRun.averageSpeed = 20
        
        let (previousCoor, newShapeDict, pullShapeDict) = runManager.createIntersectingDictionaries(existingRun: pulledRun!, activeRun: activeRun)
        
        
        runManager.checkShapeIntersection(existingRun: pulledRun!, activeRun: activeRun, previousCoor: previousCoor, newShapeDict: newShapeDict, pulledShapeDict: pullShapeDict)
        
        
        let newShape = activeRun.createNewShape()
        displayNewShapeWith(newShape: newShape, username: activeRun.username!)
        
        self.view.setNeedsDisplay()
        
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
