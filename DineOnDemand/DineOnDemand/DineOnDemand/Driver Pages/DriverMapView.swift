//
//  DriverMapView.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/21/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import CoreLocation
import MapKit

class DriverMapView: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var ETALabel: UILabel!
    @IBOutlet weak var map: MKMapView!
    var myLocation = CLLocationCoordinate2D()
    let locationManager = CLLocationManager()
    var street = ""; var city = ""; var zipCode = ""; var state = ""
    
    @IBAction func calculateRouteButtonTapped(_ sender: Any) {
        getDeliveryAddress()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        map.delegate = self
    }
    
    func drawingRoute(destinationCoord: CLLocationCoordinate2D){
        let sourceCoord = (locationManager.location?.coordinate)!
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoord)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoord)
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destItem = MKMapItem(placemark: destinationPlacemark)
        let destinationRequest = MKDirections.Request()
        destinationRequest.source = sourceItem
        destinationRequest.destination = destItem
        destinationRequest.transportType = .automobile
        destinationRequest.requestsAlternateRoutes = false //true if you want more than 1 route to destination
        let directions = MKDirections(request: destinationRequest)
        directions.calculate { (response, error) in
            guard let response = response else {if let error = error {print("Unable to create route to destination!")}; return}
            let route = response.routes[0]
            self.map.addOverlay(route.polyline)
            self.map.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            self.convertETATime(time: Int(route.expectedTravelTime))
        }
    }
    func convertETATime(time: Int){
        var timeInMinutes = time / 60
        var timeInHours = 0
        if(timeInMinutes > 60){
            timeInHours = timeInMinutes / 60
            timeInMinutes = timeInMinutes % 60
            if(timeInHours > 1){ self.ETALabel.text = ("\(timeInHours) Hour and \(timeInMinutes) Minutes")}
            else{ self.ETALabel.text = ("\(timeInHours) Hours and \(timeInMinutes) Minutes")}
        }
        self.ETALabel.text = ("\(timeInMinutes) Minutes")
        
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        return render
    }
    // Get's the driver's current coordinates and saves them in 'myLocation'
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        myLocation.latitude = locValue.latitude; myLocation.longitude = locValue.longitude
    }
    // Gets the delivery address and calls 'setPin'
    func getDeliveryAddress() {
        let address = DriverOrderDetails.orderData["delivery_address"] as! [String]
        street = address[0]; city = address[1]; state = address[2]; zipCode = address[3]
        setPin(streetAddress: street, city: city, state: state, zipCode: zipCode)
    }
    // Sets a pin where the delivery address is
    func setPin(streetAddress: String, city: String, state: String, zipCode: String) {
        // Format: Street Address, City, State Zip Code
        let address = "\(streetAddress), \(city), \(state) \(zipCode)"
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            guard let placemarks = placemarks, let location = placemarks.first?.location else{ print("Error finding location!") ; return}
            let latitude = location.coordinate.latitude; let longitude = location.coordinate.longitude
            print("Latitude of Address:", location.coordinate.latitude)
            print("Longitude of Address:", location.coordinate.longitude)
            let annotations = MKPointAnnotation()
            annotations.title = "Delivery Address"
            annotations.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.map.addAnnotation(annotations)
            // Zoom to the Driver's locations
            let region = MKCoordinateRegion(center: annotations.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            self.map.setRegion(region, animated: false)
            self.drawingRoute(destinationCoord: location.coordinate)
        }
    }
}
