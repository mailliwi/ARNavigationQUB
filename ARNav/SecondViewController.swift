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

class SecondViewController: UIViewController, MGLMapViewDelegate {
    
    // MARK: - IBActions, IBOutlets & Vars
    
    // Map
    @IBOutlet weak var mapViewLight: MGLMapView!
    
    // SearchUI
    var searchController = MapboxSearchController()
    lazy var panelController = MapboxPanelController(rootViewController: searchController)
    
    // mapViewStyle switch selector to allow user to switch the map
    // between Light and Dark mode.
    // Default is Light mode.
    var mapStyleURL = "mapbox://styles/mapbox/light-v10"
    
    @IBOutlet weak var modeLabel: UILabel!
    @IBOutlet var mapStyleSwitch: UISwitch!
    @IBAction func didTapMapStyleButton(_ sender: UISwitch) {
        if (mapStyleSwitch.isOn == true) {
            mapStyleURL = "mapbox://styles/mapbox/dark-v10"
            modeLabel.text = "🌙"
            mapViewConfiguration()
        } else {
            mapStyleURL = "mapbox://styles/mapbox/light-v10"
            modeLabel.text = "☀️"
            mapViewConfiguration()
        }
    }
    
    // MARK: - viewDidLoad()
    // When application loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapViewLight.delegate = self
        mapViewConfiguration()
        modeLabel.text = "💡"
        searchController.delegate = self
        addChild(panelController)
        
    }
    
    // MARK: - Utility methods
    
    /// Configuration of the Mapbox map layout and style
    private func mapViewConfiguration() {
        
        // appearance
        mapViewLight.styleURL = URL(string: mapStyleURL)
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
    
    /// When clicking an annotation after searching for a location, this function allows the
    /// show of a callout on top of the annotation.
    /// Said callout contains subtext information on the location
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        // Always allow callouts to popup when annotations are tapped.
        return true
    }
    
}

// MARK: - SearchControllerDelegate

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
