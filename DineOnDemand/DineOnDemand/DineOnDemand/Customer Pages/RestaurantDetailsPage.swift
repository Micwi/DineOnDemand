//
//  RestaurantDetailsPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 2/26/22.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseFirestore

class RestaurantDetailsPage: UIViewController, CLLocationManagerDelegate {
    
    private let database = Firestore.firestore()
    static var restaurantCode = ""
    static var restaurantName = ""
    
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var streetAddressLabel: UILabel!
    @IBOutlet weak var cityStateZipCodeLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var xMilesLabel: UILabel!
    
    @IBOutlet weak var daysOfWeekLabel: UILabel!
    @IBOutlet weak var hoursLabel: UILabel!
    
    @IBOutlet weak var orderButton: RoundedButton!
    
    var myLocation = CLLocationCoordinate2D()
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPhoneNumberButton()
        getCurrentLocation()
        getRestaurantData(); getRestaurantHours()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        unlockTabBar()
        CategoryFoods.bagItems = [order]()
    }
    
    func unlockTabBar() {
        self.tabBarController?.tabBar.items?[0].isEnabled = true; self.tabBarController?.tabBar.items?[1].isEnabled = true
    }
    
    func resetGiftCardOnOrder() {
        Bag.giftCardValue = 0; Bag.remainingGiftCardBalance = 0
    }
    
    func setupPhoneNumberButton() {
        phoneNumberLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(callNumber))
        phoneNumberLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc func callNumber() {
        var phoneNumber = phoneNumberLabel.text!
        phoneNumber = phoneNumber.filter("0123456789.".contains)
        if let url = URL(string: "tel://+1\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func getRestaurantData() {
        let docRef = self.database.collection("restaurant").document("restaurant_\(RestaurantDetailsPage.restaurantCode)")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            let restaurantLongitude = "\(data["longitude"]!)"; let restaurantLatitude = "\(data["latitude"]!)"
            self.restaurantNameLabel.text = data["name"]! as? String
            self.streetAddressLabel.text = data["address_street"]! as? String
            let city = data["address_city"]! as! String; let state = data["address_state"]! as! String
            let zipCode = data["address_zipcode"]! as! String
            self.phoneNumberLabel.text = data["phone_number"]! as? String
            self.cityStateZipCodeLabel.text = "\(city), \(state) \(zipCode)"
            self.xMilesLabel.text = self.calculateDistance(longitude: restaurantLongitude, latitude: restaurantLatitude) + " miles"
        }
    }
    
    func getRestaurantHours() {
        let docRef = self.database.collection("restaurant").document("restaurant_\(RestaurantDetailsPage.restaurantCode)").collection("hours").document("current_hours")
        docRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                return
            }
            self.showHours(data: data)
            self.checkIfOpen(data: data)
        }
    }
    
    func showHours(data: [String: Any]) {
        self.daysOfWeekLabel.text = "Sunday\n\nMonday\n\nTuesday\n\nWednesday\n\nThursday\n\nFriday\n\nSaturday"
        self.hoursLabel.text = "\(data["sunday_hours"]!)\n\n\(data["monday_hours"]!)\n\n\(data["tuesday_hours"]!)\n\n\(data["wednesday_hours"]!)\n\n \(data["thursday_hours"]!)\n\n\(data["friday_hours"]!)\n\n\(data["saturday_hours"]!)"
    }
    
    // Checks if the selected restaurant is open or closed
    func checkIfOpen(data: [String: Any]) {
        var currentTimeDate = Date()
        let dayOfWeekFormatter = DateFormatter(); dayOfWeekFormatter.dateFormat = "EEEE"
        let todaysDayOfTheWeekString = dayOfWeekFormatter.string(from: currentTimeDate).lowercased()
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "h:mm a"
        let hours = data["\(todaysDayOfTheWeekString)_hours"] as! String
        let hoursSplit = hours.components(separatedBy: " - ")
        let currentTimeString = dateFormatter.string(from: currentTimeDate)
        let openingTimeString = hoursSplit[0]; let closingTimeString = hoursSplit[1]
        currentTimeDate = (dateFormatter.date(from: currentTimeString)?.addingTimeInterval(-18000))! // Subtracting 5 hours
        let openingTimeDate = dateFormatter.date(from: openingTimeString)?.addingTimeInterval(-14400) // Subtracting 4 hours
        let closingTimeDate = dateFormatter.date(from: closingTimeString)?.addingTimeInterval(-18000) // Subtracting 5 hours
        
        if currentTimeDate.addingTimeInterval(3600) > openingTimeDate! && currentTimeDate.addingTimeInterval(3600) < closingTimeDate! {
            // Runs when the current time is past the opening time but before the closing time
            print("Restaurant is Open. Current time is between opening time and closing time.")
            orderButton.isEnabled = true; orderButton.alpha = 1.0
        } else if currentTimeDate.addingTimeInterval(3600) > closingTimeDate!.addingTimeInterval(-3600) {
            // Runs when the current time is past the closing time (closed for the night)
            print("Restaurant has stopped taking orders for the night.")
            orderButton.isEnabled = false; orderButton.alpha = 0.5
        } else if currentTimeDate.addingTimeInterval(3600) < openingTimeDate! {
            // Runs when the opening time is after the current time (not opened yet)
            print("Restaurant has not opened yet.")
            orderButton.isEnabled = false; orderButton.alpha = 0.5
        }
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
    
    func calculateDistance(longitude: String, latitude: String) -> String {
        let userLocation = CLLocation(latitude: myLocation.latitude, longitude: myLocation.longitude)
        let restaurantLocation = CLLocation(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
        let distance = userLocation.distance(from: restaurantLocation) / 1609.344
        print("Distance from Restaurant: ", distance)
        return "\(String(format:"%.00f", distance))"
    }
}
