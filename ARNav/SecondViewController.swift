//
//  SecondViewController.swift
//  ARNav
//
//  Created by William Dupont on 23/08/2021.
//

import UIKit
import ARKit
import SceneKit
import CoreLocation

import Mapbox
import MapboxDirections
import MapboxSearch
import MapboxSearchUI

import Turf

class SecondViewController: UIViewController {

    @IBOutlet weak var mapViewLight: MGLMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapConfiguration()
        
    }
    
    private func mapConfiguration() {
        // appearance
        mapViewLight.styleURL = URL(string: "mapbox://styles/mapbox/dark-v10")
        mapViewLight.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapViewLight.layer.cornerRadius = 20
        
        // center + user tracking settings
        mapViewLight.showsUserLocation = true
        mapViewLight.userTrackingMode = .followWithHeading
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
