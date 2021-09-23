//
//  ARRoute+DirectionsRoute.swift
//  ARNav
//
//  Created by William Dupont on 21/09/2021.
//

// MARK: - Imported from vision-ios-examples

import Foundation
import MapboxDirections
import MapboxVisionARNative

extension MapboxVisionARNative.Route {
    /**
     Create `MapboxVisionARNative.Route` instance from `MapboxDirections.Route`.
     */
    convenience init(route: MapboxDirections.Route) {
        var points = [RoutePoint]()

        route.legs.forEach {
            $0.steps.forEach { step in
                let maneuver = RoutePoint(coordinate: GeoCoordinate(lon: step.maneuverLocation.longitude, lat: step.maneuverLocation.latitude))
                points.append(maneuver)

                guard let coords = step.shape?.coordinates else { return }
                let routePoints = coords.map {
                    RoutePoint(coordinate: GeoCoordinate(lon: $0.longitude, lat: $0.latitude), maneuverType: step.maneuverType.toVisionManeuverType())
                }
                points.append(contentsOf: routePoints)
            }
        }

        self.init(points: points,
                  eta: Float(route.expectedTravelTime),
                  sourceStreetName: route.legs.first?.source?.name ?? "",
                  destinationStreetName: route.legs.last?.destination?.name ?? "")
    }
}

// MARK: - Extensions
// Switch statement of all possible AR cases that may be encountered during navigation
private extension MapboxDirections.ManeuverType {
    func toVisionManeuverType() -> MapboxVisionARNative.ManeuverType {
        switch self {
        case .depart:
            return .depart
        case .turn:
            return .turn
        case .continue:
            return .continue
        case .passNameChange:
            return .newName
        case .merge:
            return .merge
        case .takeOnRamp:
            return .onRamp
        case .takeOffRamp:
            return .offRamp
        case .reachFork:
            return .fork
        case .reachEnd:
            return .endOfRoad
        case .useLane:
            return .none
        case .takeRoundabout:
            return .roundabout
        case .takeRotary:
            return .rotary
        case .turnAtRoundabout:
            return .roundaboutTurn
        case .exitRoundabout:
            return .roundaboutExit
        case .exitRotary:
            return .rotaryExit
        case .heedWarning:
            return .notification
        case .arrive:
            return .arrive
        }
    }
}

