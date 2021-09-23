//
//  ViewController.swift
//  ARNav
//
//  Created by William Dupont on 22/08/2021.
//

// MARK: - Imports
import UIKit
import ARKit
import CoreLocation

//import Mapbox
import Mapbox
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import MapboxVision
import MapboxVisionNative
import MapboxVisionAR
import MapboxVisionARNative


// Others
import Turf

// MARK: - ARCameraViewController
class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {
    
    //
    // MARK: - IBActions, IBOutlets & Vars
    
    // VisionSDK var initialisation:
    // Programatically open camera instead of using storyboard IBOulets
    
    var videoSource: CameraVideoSource!
    var visionManager: VisionManager!
    var visionARManager: VisionARManager!

    let visionARViewController = VisionARViewController()
    
    // 0.75 opcacity black label box that contains ETA, Distance and Speed data
    @IBOutlet weak var infoBoxView: UIView!
    @IBOutlet weak var estimatedTimeArrivalLabel: UILabel!
    @IBOutlet weak var distanceToDestinationLabel: UILabel!
    @IBOutlet weak var userCurrentSpeedLabel: UILabel!
    let coreLocationManager = CLLocationManager()
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationSpeed = locations[0]
        userCurrentSpeedLabel.text = "\(locationSpeed.speed)m/s"
    }
    
    
    // Shouldn't have to use an ARSCNView but if I don't then the camera feed doesn't open up
    // review
    @IBOutlet var sceneView: ARSCNView!
    
    // ViewMap button
    @IBOutlet weak var viewMapButton: UIButton!
    @IBAction func didTapButton() {
        // NOTE: above function should be renamed didTapVieMapButton
        // present secondViewController modally
        guard let secondViewController = storyboard?.instantiateViewController(identifier: "secondViewControllerID") as? SecondViewController else {
            print("Could not get VC from storyboard.")
            return
        }
        present(secondViewController, animated: true)
    }
    
    @IBOutlet var startNavigationToQUBButton: UIButton!
    @IBAction func didTapStartNavigationToQUB() {
        // When touched, start navigation to QUB
        startNav()
        print("Tapped startNav button")
    }
    
    // directions var that checks token placed in info.plist is valid
    private let directions = Directions(credentials: DirectionsCredentials())
    
    // MARK: - viewDidLoad()
    // When application loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ARKit
        // TO DELETE because not supposed to use that to get a camera feed working
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWireframe]
        sceneView.scene = SCNScene()
        
        //CLLocationManager delegate
        coreLocationManager.delegate = self
        
        // create video source
        videoSource = CameraVideoSource()
        
        // create visionManager + visionARManager
        visionManager = VisionManager.create(videoSource: videoSource)
        visionARManager = VisionARManager.create(visionManager: visionManager)
        
        // config for AR view to display AR Navigation
        visionARViewController.set(arManager: visionARManager)
        
        addARView()
        
        // invoke customisation methods
        customizeInfoBoxView()
        customizeViewMapButton()
        customizeStartNavigationToQUBButton()
        
    }
    
    //MARK: - viewWillAppear
    // start when view appears
    // this is more for resource management here
    // same as func below viewDidDisappear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visionManager.start()
        videoSource.start()
    }
    
    //MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        
        videoSource.start()
        // ARKit temporary replacement to show the camera because addARView shows a grey screen.
        startARSession()
        // Mapbox Vision AR SDK view that shows a grey screen
//        addARView()
    }
    
    //MARK: - viewDidDisappear
    // same as func above viewWillAppear
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        visionManager.stop()
        videoSource.stop()
    }
    
    // MARK: - Utility methods
    
    private func customizeViewMapButton() {
        viewMapButton.layer.cornerRadius = 20
    }
    
    private func customizeInfoBoxView() {
        infoBoxView.layer.cornerRadius = 30
    }
    
    private func customizeStartNavigationToQUBButton() {
        startNavigationToQUBButton.layer.cornerRadius = 20
    }
    
    private func startARSession() {
        // configure AR tracking session
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - startNav()
    private func startNav() {
        // ⚠️⚠️⚠️
        // Navigation query is a hack for this section,
        // since I cannot manage to link the 2 ViewControllers, I need to
        // simulate what I intend to query by manually entering user + destination coordinates
        
        // user location and destination selection + route options
        // NOTE: For the origin, choose between vars called 'origin' or 'originDynamic'
        // Can't have both at the same time. Use interchangeably and comment out the one not being used
        // 'origin' => Gets the user's current location in real time
        // 'originDynamic' => Manually entered originiating coordinates. Means user must start route from these coordinates
        let originDynamic = CLLocationCoordinate2D()
        // let origin = CLLocationCoordinate2DMake(54.580167, -5.938750)
        
        // Destination's coordinates were set as Queen's University Belfast, more
        // specifically on University Square street.
        let destination = CLLocationCoordinate2DMake(54.585166, -5.932519)
        let options = RouteOptions(coordinates: [originDynamic, destination], profileIdentifier: .automobile)
        options.includesSteps = true
        
        // query API and pass to visionARManager
        directions.calculate(options) { [weak self] (_, result) in
            guard let self = self, let response = try? result.get(), let route = response.routes?.first else { return }
            self.visionARManager.set(route: Route(route: route))
        }
    }
    
    // MARK: - addARView()
    // need to review that method so as not to hide my own UI
    /// Method that adds the AR navigation to the screen
    private func addARView() {
        addChild(visionARViewController)
        // Adding subView blocks the camera view from showing
        // camera turned on but obstructed by I don't know what
        // review
        // check link: https://www.swiftbysundell.com/basics/child-view-controllers/
//        view.addSubview(visionARViewController.view)
        visionARViewController.didMove(toParent: self)
        
    }
    
    deinit {
        // cleaning up resources by destroying modules when they're no longer used
        visionARManager.destroy()
        // free up VisionManager's resources. Need to be called AFTER destroying other modules
        visionManager.destroy()
    }
    
} // end of ViewController
