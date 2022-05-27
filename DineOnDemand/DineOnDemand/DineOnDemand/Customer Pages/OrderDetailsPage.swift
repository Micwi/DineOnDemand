//
//  OrderDetailsPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import CoreLocation
import MapKit

class OrderDetailsPage: UIViewController {
    
    private let database = Firestore.firestore()
    
    static var orderData = [String: Any]() // This contains all data about the selected order
    
    @IBOutlet weak var addressLabel1: UILabel!
    @IBOutlet weak var addressLabel2: UILabel!
    
    @IBOutlet weak var orderStatusLabel: UILabel!
    @IBOutlet weak var orderContentsTextView: UITextView!
    
    @IBOutlet weak var map: MKMapView!
    
    var checkForStatusChange = Timer()
    var retrieveDriverLocation = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshOrderData(); getContentsOfOrder()
        self.checkForStatusChange = Timer.scheduledTimer(timeInterval: 3.5, target: self, selector: #selector(self.getLatestData), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        checkForStatusChange.invalidate()
        retrieveDriverLocation.invalidate()
    }
    
    // Checks if the selected order is a pickup or delivery order
    func checkOrderType() {
        if OrderDetailsPage.orderData["order_type"] as! String == "Pickup" {
            // Run code here to prepare the view for a pickup type order - show restaurant as a pin on the map
            getRestaurantAddressData()
        } else if OrderDetailsPage.orderData["order_type"] as! String == "Delivery" {
            // Run code here to prepare the view for a delivery type order - show driver's location on the map
            getDeliveryAddressData()
            if OrderDetailsPage.orderData["status"] as! String == "Out for Delivery" {
                setDriverPin()
                self.retrieveDriverLocation = Timer.scheduledTimer(timeInterval: 3.5, target: self, selector: #selector(self.getLatestDriverCoordinates), userInfo: nil, repeats: true)
            }
        }
    }
    
    @objc func getLatestDriverCoordinates() { setDriverPin() }
    
    @objc func getLatestData() { refreshOrderData() }
    
    func setDriverPin() {
        // Get the latest Driver coordinates from the database and set the pin to these coordinates
        let docRef = self.database.collection("order").document("order_\(OrderDetailsPage.orderData["order_id"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            if data["status"] as! String == "Out for Delivery" {
                print("Checking for new location.")
                let latitude = data["driver_latitude"] as! CLLocationDegrees
                let longitude = data["driver_longitude"] as! CLLocationDegrees
                for annotation in self.map.annotations { if annotation.title == "Driver" { self.map.removeAnnotation(annotation) } }
                // Set the Driver's location as a pin
                let annotations = MKPointAnnotation()
                annotations.title = "Driver"
                annotations.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                self.map.addAnnotation(annotations)
                // Zoom to the Driver's locations
                let region = MKCoordinateRegion(center: annotations.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.map.setRegion(region, animated: false)
            } else if data["status"] as! String == "Delivered" {
                self.retrieveDriverLocation.invalidate(); self.map.removeAnnotation(self.map.annotations.last!)
            }
        }
    }
    
    func refreshOrderData() {
        let docRef = self.database.collection("order").document("order_\(OrderDetailsPage.orderData["order_id"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            OrderDetailsPage.orderData = data
            self.orderStatusLabel.text = OrderDetailsPage.orderData["status"] as? String
            self.checkOrderType()
        }
    }
    
    // Show each item/it's cost and the total cost of the order
    func getContentsOfOrder() {
        let docRef = self.database.collection("order").document("order_\(OrderDetailsPage.orderData["order_id"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let result = data["foods_in_order"] as! [String]
            self.orderContentsTextView.text = "Order Details\n\n"
            for i in result { self.orderContentsTextView.text += "• \(i)\n" }
            if OrderDetailsPage.orderData["gift_card_applied"] as! Double != 0 {
                let formattedGCValue = String(format: "%.2f", OrderDetailsPage.orderData["gift_card_applied"]! as! Double)
                self.orderContentsTextView.text += "\nGift Card Applied: $\(formattedGCValue)"
            }
            self.orderContentsTextView.text += "\nOrder Total: $\(OrderDetailsPage.orderData["order_total"]!)"
        }
    }
    
    // For Pickup Orders
    func getRestaurantAddressData() {
        let docRef = self.database.collection("restaurant").document("restaurant_\(OrderDetailsPage.orderData["restaurant_code"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let city = data["address_city"] as! String; let state = data["address_state"] as! String
            let street = data["address_street"] as! String; let zipCode = data["address_zipcode"] as! String
            self.addressLabel1.text = street; self.addressLabel2.text = "\(city), \(state) \(zipCode)"
            
            // Shows restaurant's pin on the map
            let annotations = MKPointAnnotation()
            annotations.title = data["name"] as? String
            annotations.coordinate = CLLocationCoordinate2D(latitude: data["latitude"] as! CLLocationDegrees, longitude: data["longitude"] as! CLLocationDegrees)
            self.map.setRegion(MKCoordinateRegion(center: annotations.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
            self.map.addAnnotation(annotations)
        }
    }
    
    // For Delivery Orders
    func getDeliveryAddressData() {
        let deliveryAddressData = OrderDetailsPage.orderData["delivery_address"] as! [String]
        let street = deliveryAddressData[0]; let city = deliveryAddressData[1]
        let state = deliveryAddressData[2]; let zipCode = deliveryAddressData[3]
        addressLabel1.text = street; addressLabel2.text = "\(city), \(state) \(zipCode)"
        setDeliveryAddressPin(streetAddress: street, city: city, state: state, zipCode: zipCode)
    }
    
    // Sets a pin where the delivery address is
    func setDeliveryAddressPin(streetAddress: String, city: String, state: String, zipCode: String) {
        let address = "\(streetAddress), \(city), \(state) \(zipCode)"
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            let location = placemarks?.first?.location
            let latitude = location!.coordinate.latitude; let longitude = location!.coordinate.longitude
            let annotations = MKPointAnnotation()
            annotations.title = "Delivery Address"
            annotations.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.map.addAnnotation(annotations)
            if OrderDetailsPage.orderData["status"] as! String != "Out for Delivery" {
                let region = MKCoordinateRegion(center: annotations.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.map.setRegion(region, animated: false)
            }
        }
    }
    
}
