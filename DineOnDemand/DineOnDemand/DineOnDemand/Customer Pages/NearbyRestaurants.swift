//
//  NearbyRestaurants.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/15/22.
//

import UIKit
import MapKit
import CoreLocation
import Foundation
import Firebase
import FirebaseFirestore

class NearbyRestaurants: UIViewController, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var table: UITableView!
    
    var myLocation = CLLocationCoordinate2D()
    @IBOutlet weak var map: MKMapView!
    var restaurantInformation = [[String: Any]]()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getCurrentLocation()
        getRestaurantData()
    }
    
    func getCurrentLocation() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        myLocation.latitude = locValue.latitude; myLocation.longitude = locValue.longitude
    }
    
    func getRestaurantData() {
        database.collection("restaurant").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let restaurantLongitude = "\(data["longitude"]!)"; let restaurantLatitude = "\(data["latitude"]!)"
                    self.restaurantInformation.append(["code": data["code"]!, "name": data["name"]!, "latitude": data["latitude"]!, "longitude": data["longitude"]!, "street": data["address_street"]!, "state": data["address_state"]!, "city": data["address_city"]!, "zipCode": data["address_zipcode"]!, "distance": self.calculateDistance(longitude: restaurantLongitude, latitude: restaurantLatitude)])
                }
                self.sortBasedOnDistance()
                self.setupMapAndTable()
            }
        }
    }
    
    func calculateDistance(longitude: String, latitude: String) -> String {
        let userLocation = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        let restaurantLocation = CLLocation(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
        let distance = userLocation.distance(from: restaurantLocation) / 1609.344
        print("Distance from Restaurant: ", distance)
        return "\(String(format:"%.00f", distance))"
    }
    
    func sortBasedOnDistance() {
        self.restaurantInformation.sort {
            item1, item2 in
            let distance1 = item1["distance"] as! String
            let distance2 = item2["distance"] as! String
            return distance1 < distance2
        }
    }
    
    func setupMapAndTable() {
        map.setRegion(MKCoordinateRegion(center: myLocation, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
        map.delegate = self
        mapAnnotations(locations: restaurantInformation)
        table.reloadData()
    }
    
    func mapAnnotations(locations: [[String : Any]]){
        for location in locations {
            let annotations = MKPointAnnotation()
            annotations.title = location["name"] as? String
            annotations.coordinate = CLLocationCoordinate2D(latitude: location["latitude"] as! CLLocationDegrees, longitude: location["longitude"] as! CLLocationDegrees)
            map.addAnnotation(annotations)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(75)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return(restaurantInformation.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "restaurantCell", for: indexPath) as! RestaurantCell
        cell.restaurantNameLabel.text = (restaurantInformation[indexPath.row]["name"] as! String)
        cell.streetAddressLabel.text = (restaurantInformation[indexPath.row]["street"] as! String)
        let city = (restaurantInformation[indexPath.row]["city"]!); let state = (restaurantInformation[indexPath.row]["state"]!)
        let zipCode = (restaurantInformation[indexPath.row]["zipCode"]!)
        cell.cityStateZipCodeLabel.text = "\(city), \(state) \(zipCode)"
        cell.distanceLabel.text = (restaurantInformation[indexPath.row]["distance"] as! String) + " miles"
        return(cell)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Row Tapped: \(indexPath.row)")
        RestaurantDetailsPage.restaurantCode = restaurantInformation[indexPath.row]["code"] as! String
        RestaurantDetailsPage.restaurantName = restaurantInformation[indexPath.row]["name"] as! String
        self.performSegue(withIdentifier: "showRestaurantDetails", sender: self)
        table.deselectRow(at: indexPath, animated: true)
    }
    
}

class RestaurantCell: UITableViewCell, UITextFieldDelegate {
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var streetAddressLabel: UILabel!
    @IBOutlet weak var cityStateZipCodeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
}
