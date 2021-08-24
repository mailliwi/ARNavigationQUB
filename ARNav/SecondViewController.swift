//
//  SecondViewController.swift
//  ARNav
//
//  Created by William Dupont on 23/08/2021.
//

// MARK: - Imports
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
    
    // MARK: - IBActions, IBOutlets & Vars
    @IBOutlet weak var mapViewLight: MGLMapView!
    var searchController = MapboxSearchController()
    lazy var panelController = MapboxPanelController(rootViewController: searchController)
    
    // MARK: - viewDidLoad()
    // When application loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapViewConfiguration()
        searchController.delegate = self
        addChild(panelController)
        
    }
    
    // MARK: - Utility methods
    /// Configuration of the Mapbox map layout and style
    private func mapViewConfiguration() {
        // appearance
        mapViewLight.styleURL = URL(string: "mapbox://styles/mapbox/dark-v10")
        mapViewLight.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapViewLight.layer.cornerRadius = 20
        
        // center + user tracking settings
        mapViewLight.showsUserLocation = true
        mapViewLight.userTrackingMode = .follow
    }
    
    /// This function take care of annotations on the mapView
    func showAnnotation(_ annotations: [MGLAnnotation], isPOI: Bool) {
        
        // make sure annotations exist
        guard !annotations.isEmpty else {
            return
        }
        
        // if any annotation already exists, remove it
        if let existingAnnotations = mapViewLight.annotations {
            mapViewLight.removeAnnotations(existingAnnotations)
        }
        
        // add actual annotation
        mapViewLight.addAnnotations(annotations)
        
        // Show where annotation is on map with camera animation
        if annotations.count == 1, let annotation = annotations.first {
            mapViewLight.setCenter(annotation.coordinate, zoomLevel: 15, animated: true)
        } else {
            mapViewLight.showAnnotations(annotations, animated: true)
        }
        
    }
    
}

// extension of SecondViewController to allow said controller to use following delegate methods
extension SecondViewController: SearchControllerDelegate {
    
    func categorySearchResultsReceived(results: [SearchResult]) {
        let annotations = results.map {
            searchResult -> MGLPointAnnotation in
            let annotation = MGLPointAnnotation()
            annotation.coordinate = searchResult.coordinate
            annotation.title = searchResult.name
            annotation.subtitle = searchResult.address?.formattedAddress(style: .medium)
            return annotation
        }
        
        showAnnotation(annotations, isPOI: false)
        
    }
    
    func searchResultSelected(_ searchResult: SearchResult) {
        let annotation = MGLPointAnnotation()
        annotation.coordinate = searchResult.coordinate
        annotation.title = searchResult.name
        annotation.subtitle = searchResult.address?.formattedAddress(style: .medium)
        
        showAnnotation([annotation], isPOI: searchResult.type == .POI)
    }
    
    func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
        let annotation = MGLPointAnnotation()
        annotation.coordinate = userFavorite.coordinate
        annotation.title = userFavorite.name
        annotation.subtitle = userFavorite.address?.formattedAddress(style: .medium)
        
        showAnnotation([annotation], isPOI: true)
    }
    
}
