//
//  DriverOrderDetails.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/24/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import CoreLocation
import MapKit

class DriverOrderDetails: UIViewController, CLLocationManagerDelegate {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var map: MKMapView!
    var myLocation = CLLocationCoordinate2D()
    let locationManager = CLLocationManager()
    
    var updateDriverLocation = Timer()
    
    static var orderData = [String: Any]()
    @IBOutlet weak var streetAddressLabel: UILabel!
    @IBOutlet weak var cityStateZipLabel: UILabel!
    @IBOutlet weak var orderDetailsTextArea: UITextView!
    @IBOutlet weak var takeOnButton: RoundedButton!
    @IBOutlet weak var deliveredButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getNewData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        print("View Did Disappear")
        updateDriverLocation.invalidate()
    }
    
    func getNewData() {
        let orderID = DriverOrderDetails.orderData["order_id"] as! String
        let docRef = self.database.collection("order").document("order_\(orderID)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            DriverOrderDetails.orderData = data
            self.setupButtons(); self.getContentsOfOrder(); self.getDeliveryAddress()
            self.updateDriverLocation = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.getCurrentLocation), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func takeOnButtonTapped(_ sender: Any) {
        self.doubleCheckStatus()
    }
    
    func doubleCheckStatus() {
        let docRef = self.database.collection("order").document("order_\(DriverOrderDetails.orderData["order_id"]!)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            self.takeOnButton.isEnabled = false; self.takeOnButton.alpha = 0.35
            self.deliveredButton.isEnabled = true; self.deliveredButton.alpha = 1.0
            let orderStatus = data["status"] as! String
            if orderStatus == "Preparing to Deliver" {
                self.changeOrderStatus(newStatus: "Out for Delivery")
            } else if orderStatus == "Out for Delivery" {
                self.alreadyTakenOnAlert()
            }
        }
    }
    
    func alreadyTakenOnAlert() {
        let alertController = UIAlertController(title: "Already Taken On", message: "This order has already been taken on by another driver.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Okay", style: .default) { _ in }
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func markAsDeliveredAlert() {
        let alertController = UIAlertController(title: "Mark as Delivered", message: "Are you sure you want to mark this order as Delivered? This cannot be undone.", preferredStyle: .alert)
        let noAction = UIAlertAction(title: "No", style: .default) { _ in }
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.changeOrderStatus(newStatus: "Delivered")
            self.deliveredButton.isEnabled = false; self.deliveredButton.alpha = 0.35
        }
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func deliveredButtonTapped(_ sender: Any) {
        markAsDeliveredAlert()
    }
    
    func changeOrderStatus(newStatus: String) {
        let orderID = DriverOrderDetails.orderData["order_id"] as! String
        self.database.collection("order").document("order_\(orderID)").setData([
            "status": newStatus,
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else {
                if newStatus == "Out for Delivery" { self.updateCurrentCoordinates() }
                else if newStatus == "Delivered" { self.updateDriverLocation.invalidate(); self.removeCoordinates(orderID: orderID) }
            }
        }
    }
    
    func removeCoordinates(orderID: String) {
        self.database.collection("order").document("order_\(orderID)").setData([
            "driver_latitude": FieldValue.delete(),
            "driver_longitude": FieldValue.delete()
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
    func getContentsOfOrder() {
        let result = DriverOrderDetails.orderData["foods_in_order"] as! [String]
        self.orderDetailsTextArea.text = "Order Details\n\n"
        for i in result { self.orderDetailsTextArea.text += "• \(i)\n" }
        if DriverOrderDetails.orderData["gift_card_applied"] as! Double != 0 {
            let formattedGCValue = String(format: "%.2f", DriverOrderDetails.orderData["gift_card_applied"]! as! Double)
            self.orderDetailsTextArea.text += "\nGift Card Applied: $\(formattedGCValue)"
        }
        self.orderDetailsTextArea.text += "\nOrder Total: $\(DriverOrderDetails.orderData["order_total"]!)"
    }
    
    func setupButtons() {
        let orderStatus = DriverOrderDetails.orderData["status"] as! String
        if orderStatus == "Preparing to Deliver" {
            self.takeOnButton.isEnabled = true; self.takeOnButton.alpha = 1.0
            self.deliveredButton.isEnabled = false; self.deliveredButton.alpha = 0.35
        } else {
            // Ran when the order is already being delivered by another driver
            self.takeOnButton.isEnabled = false; self.takeOnButton.alpha = 0.35
            self.deliveredButton.isEnabled = true; self.deliveredButton.alpha = 1.0
        }
    }
    
    // Gets the delivery address and calls 'setPin'
    func getDeliveryAddress() {
        let address = DriverOrderDetails.orderData["delivery_address"] as! [String]
        let street = address[0]; let city = address[1]; let state = address[2]; let zipCode = address[3]
        streetAddressLabel.text = street; cityStateZipLabel.text = "\(city), \(state) \(zipCode)"
        setPin(streetAddress: street, city: city, state: state, zipCode: zipCode)
    }
    
    // Sets a pin where the delivery address is
    func setPin(streetAddress: String, city: String, state: String, zipCode: String) {
        // Format: Street Address, City, State Zip Code
        let address = "\(streetAddress), \(city), \(state) \(zipCode)"
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            let location = placemarks?.first?.location
            let latitude = location!.coordinate.latitude; let longitude = location!.coordinate.longitude
            print("Latitude of Address:", location!.coordinate.latitude)
            print("Longitude of Address:", location!.coordinate.longitude)
            let annotations = MKPointAnnotation()
            annotations.title = "Delivery Address"
            annotations.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.map.addAnnotation(annotations)
            // Zoom to the Driver's locations
            let region = MKCoordinateRegion(center: annotations.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.map.setRegion(region, animated: false)
        }
    }
    
    // Requests the driver's current location
    @objc func getCurrentLocation() {
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            self.updateCurrentCoordinates()
        }
    }
    
    // Get's the driver's current coordinates and saves them in 'myLocation'
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        myLocation.latitude = locValue.latitude; myLocation.longitude = locValue.longitude
    }
    
    // Updates the driver's coordinates in the database after getting the driver's latest location
    func updateCurrentCoordinates() {
        let orderID = DriverOrderDetails.orderData["order_id"] as! String
        // Update the order with new coordinates of current location
        self.database.collection("order").document("order_\(orderID)").setData([
            "driver_latitude": myLocation.latitude,
            "driver_longitude": myLocation.longitude
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Driver Coordinates Updated!") }
        }
    }
    
}
