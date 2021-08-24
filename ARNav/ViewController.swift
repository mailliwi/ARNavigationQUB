//
//  ViewController.swift
//  ARNav
//
//  Created by William Dupont on 22/08/2021.
//

import UIKit
import ARKit
import SceneKit
import CoreLocation

import Mapbox
import MapboxDirections

import Turf

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - IBActions, IBOutlets & Vars
    
    // Use of "True North" with function startARSession()
    // It is helpful to face North prior to starting the application, as it helps
    // calibrate the whole application better.
    // More info on Apple's documentation website at the following link:
    //https://developer.apple.com/documentation/arkit/arconfiguration/worldalignment/gravityandheading
    var automaticallyFindTrueNorth = true
    
    @IBOutlet var backgroundApp: UIView!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var viewMapButton: UIButton!
    
    @IBAction func didTapButton() {
        guard let secondViewController = storyboard?.instantiateViewController(identifier: "secondViewControllerID") as? SecondViewController else {
            print("Could not get VC from storyboard.")
            return
        }
        present(secondViewController, animated: true)
    }
    
    // MARK: - viewDidLoad()
    // When application loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Camera feed setup
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
    }
    
    // When view shows on screen
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startARSession()
        customizeViewMapButton()
    }
    
    // MARK: - Utility methods
    
    /// Starts the AR Session and opens camera feed.
    private func startARSession() {
        
        // configure session
        let configuration = ARWorldTrackingConfiguration()
        
        if automaticallyFindTrueNorth {
            configuration.worldAlignment = .gravityAndHeading
        } else {
            configuration.worldAlignment = .gravity
        }
        
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func customizeViewMapButton() {
        viewMapButton.layer.cornerRadius = 20
    }
}
