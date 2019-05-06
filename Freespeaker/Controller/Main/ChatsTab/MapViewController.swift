//
//  MapViewController.swift
//  Freespeaker
//
//  Created by Andrii Zakharenkov on 4/30/19.
//  Copyright © 2019 Andrii Zakharenkov. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var location: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Map"
        setupUI()
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "In Maps", style: .plain, target: self, action: #selector(openLocationInMaps))
        ]
    }
    
    fileprivate func setupUI() {
        guard let coordinate = location?.coordinate else { return }
        
        var region = MKCoordinateRegion()
        region.center.longitude = coordinate.longitude
        region.center.latitude = coordinate.latitude
        
        region.span.latitudeDelta = 0.01
        region.span.longitudeDelta = 0.01
        
        mapView.setRegion(region, animated: false)
        mapView.showsUserLocation = true
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
    }
    
    @objc fileprivate func openLocationInMaps() {
        guard let coords = location?.coordinate else { return }
        let regionDist: CLLocationDistance = 1000
        let regionSpan = MKCoordinateRegion(center: coords, latitudinalMeters: regionDist, longitudinalMeters: regionDist)
        
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        
        let placemark = MKPlacemark(coordinate: coords, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "User Location"
        mapItem.openInMaps(launchOptions: options)
    }
}
