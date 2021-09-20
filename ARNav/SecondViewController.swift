//
//  SecondViewController.swift
//  ARNav
//
//  Created by William Dupont on 23/08/2021.
//

// MARK: - Imports

// Apple frameworks imports
import UIKit
import ARKit
import SceneKit
import CoreLocation
import Foundation

// Mapbox framework imports
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import MapboxSearch
import MapboxSearchUI

// Others
import Turf

class SecondViewController: UIViewController, MGLMapViewDelegate {
    
    // MARK: - IBActions, IBOutlets & Vars
    
    // Map View
    @IBOutlet weak var mapViewLight: NavigationMapView!
    
    // SearchUI
    var searchController = MapboxSearchController()
    lazy var panelController = MapboxPanelController(rootViewController: searchController)
    
    // mapViewStyle switch selector to allow user to switch the map's style
    // between Light and Dark mode.
    // Default is Light mode.
    // TODO: Fix style reverting to "light mode" when switching back and forth between ViewController and SecondViewController
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
    
    @IBOutlet weak var goButton: UIButton!
    @IBAction func didTapGoButton() {
        print("Tapped GO")
    }
    var destinationIsSet = false
    
    
    // Directions vars and lets
    let locationManager = CLLocationManager()
    /// 5 next lines taken from vision-ios-examples github 📍📍📍
    var completion: ((MapboxDirections.Route, RouteOptions) -> Void)?
    var selectedRoute: MapboxDirections.Route?
    var selectedRouteOptions: RouteOptions?
    private let directions = Directions(credentials: DirectionsCredentials())
    private var isLocationSet = false
    private let routeEdgeInsets = UIEdgeInsets(top: 100, left: 200, bottom: 100, right: 200)
    
    // MARK: - viewDidLoad()
    // When application loads
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // mapViewLight.delegate = self
        mapViewConfiguration()
        modeLabel.text = "💡"
        searchController.delegate = self
        addChild(panelController)
        
        mapViewLight.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(selectPlace)))
        
        // if destination.isSet, isEnabled = true, else isEnabled = false
        goButton.isEnabled = false
        customizeGoButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        customizeGoButton()
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
    
    private func customizeGoButton() {
        goButton.layer.cornerRadius = 15
        
        if !goButton.isEnabled {
            goButton.alpha = 0.5
        } else {
            goButton.alpha = 1
        }
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
    
    /// delegate function: selects what type of mapView is used as well as refreshed userLocation
    func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        guard !isLocationSet, let location = userLocation else { return }
        mapView.setCenter(location.coordinate, zoomLevel: 12, animated: true)
        isLocationSet = true
    }
    
    // MARK: - Directions
    
    /// gesture recogniser function that converts coordinates tapped on MapViewLight to actual coordinates and allow navigation
    @objc
    private func selectPlace(sender: UIGestureRecognizer) {
        guard sender.state == .began else { return }
        // determine userLocation and set it as origin coordinates
        guard let origin = mapViewLight.userLocation?.coordinate else { return }
        // determine where the user has long pressed and set it as destination coordinates
        let destination = mapViewLight.convert(sender.location(in: mapViewLight), toCoordinateFrom: mapViewLight)
        // creation of route steps array; holds every steps of the chosen route
        // note the profile was set as "walking" but could be changed to "Automobile" or others
        // "walking" was chosen here to allow for more flexibility during live demo because I don't own my car and can't be for sure that someone can drive while I show the app's functioning
        let options = NavigationRouteOptions(coordinates: [origin, destination], profileIdentifier: .walking)
        
        // request for directions via Directions API with all steps.
        directions.calculate(options) { [weak self] (_, result) in
            guard let self = self, let response = try? result.get(), let route = response.routes?.first else { return }
            self.mapViewLight.show([route])
            self.selectedRoute = route
            self.selectedRouteOptions = options
            self.isLocationSet = true
            self.goButton.isEnabled = true
            self.customizeGoButton()
        }
        
    }
    
    /// Button/Function that initiates the start of the route when the user presses on said button/function
    @objc
    private func goTapped() {
        guard let route = selectedRoute, let options = selectedRouteOptions else { return }
        completion?(route, options)
    }
    
} // end of SecondViewController


// MARK: - SearchControllerDelegate

// extension of SecondViewController to allow said controller to use following delegate methods
// behaves as a protocol -> means that this extension must conform to said protocol to be working
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

// MARK: - Route Extension for getting a polyline predefined shape
extension Route {
    var polyline: MGLPolyline {
        var coordinates = shape!.coordinates
        return MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
    }
}
