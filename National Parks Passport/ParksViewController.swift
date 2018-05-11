//
//  ViewController.swift
//  National Parks Passport
//
//  Created by Rui Mao on 5/8/18.
//  Copyright © 2018 Rui Mao. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol HandleMapSearch {
    func dropPinZoomIn(park: Park)
}

class ParksViewController: UIViewController, CLLocationManagerDelegate  {

    @IBOutlet weak var mapView: MKMapView!
    var parks: [Park] = []
    private var locationManager: CLLocationManager!
    var resultSearchController: UISearchController? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true
        loadAllParks()
        let parkSearchTable = storyboard!.instantiateViewController(withIdentifier: "ParkSearchTable") as! ParkSearchTable
        resultSearchController = UISearchController(searchResultsController: parkSearchTable)
        resultSearchController?.searchResultsUpdater = parkSearchTable as UISearchResultsUpdating
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.delegate = self
        navigationController?.navigationBar.barTintColor = UIColor(red: 0, green: 104.0/255.0, blue: 55.0/255.0, alpha: 1.0)
        searchBar.tintColor = .white
        searchBar.placeholder = "Search for a park"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        parkSearchTable.handleMapSearchDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //lookUpCurrentLocation()
    }
    
    //set region
    
    func lookUpCurrentLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation: CLLocation = locations[0] as CLLocation
        let viewRegion = MKCoordinateRegionMakeWithDistance(currentLocation.coordinate, 4000, 4000)
        mapView.setRegion(viewRegion, animated: false)
        
    }
    
    func loadAllParks() {
        NPSAPIClient.shareInstance.fectchParks(success: { (parks: [Park]) in
            self.parks = parks
            print("Successfully loaded \(parks.count) parks")
            DispatchQueue.main.async {
                for park in self.parks {
                    self.addAnnotationForPark(park: park)
                }
            }
        }) { (error: Error?) in
            print("error \(error?.localizedDescription ?? "Problem loading parks")")
        }
    }

    
    func addAnnotationForPark(park: Park) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = park.coordinate
        annotation.title = park.name
        mapView.addAnnotation(annotation)
    }
}

extension ParksViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Park else { return nil }
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
}

extension ParksViewController: UISearchBarDelegate {

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.placeholder = "Search for a park"
    }
}

extension ParksViewController: HandleMapSearch {
    func dropPinZoomIn(park: Park) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = park.coordinate
        annotation.title = park.name
        annotation.subtitle = park.state
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(park.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
}

