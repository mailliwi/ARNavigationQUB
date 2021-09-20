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

//import Mapbox
import MapboxDirections
import MapboxNavigation
import MapboxSearch
import MapboxSearchUI

import Turf

class SecondViewController: UIViewController, MGLMapViewDelegate {
    
    // MARK: - IBActions, IBOutlets & Vars
    
    // Map view
    @IBOutlet weak var mapViewLight: MGLMapView!
    
    // SearchUI
    var searchController = MapboxSearchController()
    lazy var panelController = MapboxPanelController(rootViewController: searchController)
    
    // mapViewStyle switch selector to allow user to switch the map's style
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
    
    // Directions
    let locationManager = CLLocationManager()
    let directions = Directions.shared
    
    // MARK: - viewDidLoad()
    // When application loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        mapViewLight.delegate = self
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
        
        // center map on User + User tracking mode
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
    
    
    // MARK: - Directions
    
    /// functions that requests directions through the Mapbox Directions API.
    func directionsQuery(with arrivalLocation: CLLocation) {
        // determine user's current location and stores it in var
        let userCurrentLocation = CLLocationCoordinate2D()
        
        // departure and arrival locations coordinates
        let routeWaypoints = [
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: userCurrentLocation.latitude, longitude: userCurrentLocation.longitude), name: "start:"),
            Waypoint(coordinate: CLLocationCoordinate2D(latitude: arrivalLocation.coordinate.latitude, longitude: arrivalLocation.coordinate.longitude), name: "end:"),
        ]
        
        // Set profile to walking or driving
        // Here it has been set to walking to allow experiencing/testing the application where cars cannot go
        // It will be much calmer and quieter :)
        let routeOptions = RouteOptions(waypoints: routeWaypoints, profileIdentifier: .automobile)
        routeOptions.includesSteps = true
        
        
        // query initiation
        let _ = directions.calculate(routeOptions) { (routes, errorHandler) in
            // error handling switch
            switch errorHandler {
            
            // if failure to get route
            case .failure(let error):
                print("Error calculating route: \(error)")
            // otherwise, if successful
            case .success(let response):
                guard let route = response.routes?.first, let leg = route.legs.first else {
                    return
                }
                
                
                print("Route initialization successful: \(leg)")
                var polyline = [CLLocationCoordinate2D]()
                
                /*
                for step in leg.steps {
                    let coordinate =
                }*/
                
            }
        }
    }
} // end of SecondViewController


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
