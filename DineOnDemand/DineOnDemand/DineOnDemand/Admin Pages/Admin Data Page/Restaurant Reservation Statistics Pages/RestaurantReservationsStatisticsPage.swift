//
//  RestaurantReservationsStatisticsPage.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class RestaurantReservationsStatisticsPage: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    private let database = Firestore.firestore()
    var RestaurantData = [RestaurantInfo]()
    static var restaurantSelected = ""
    static var restaurantCode = ""
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getRestaurantData()
        
    }
    func getRestaurantData(){
        RestaurantData = [RestaurantInfo]()
        let docRef = self.database.collection("restaurant").addSnapshotListener{[self]
            (QuerySnapshot, err) in
            if let err = err{
                //error occurred when trying to grab the data from firestore
                print("Error occurred when grabbing documents from database.")
                print("Error is: \(err)")
            }
            else{
                for doc in QuerySnapshot!.documents {
                    let name = doc["name"] as! String
                    let city = doc["address_city"] as! String
                    let street = doc["address_street"] as! String
                    let state = doc["address_state"] as! String
                    let zipCode = doc["address_zipcode"] as! String
                    let phoneNumber = doc["phone_number"] as! String
                    let restaurantCode = doc["code"] as! String
                    self.RestaurantData.append(RestaurantInfo(restaurantName: name, restaurantCity: city, restaurantStreet: street, restaurantState: state, restaurantZipCode: zipCode, restaurantPhoneNumber: phoneNumber, restaurantCode: restaurantCode))
                }
                tableView.reloadData()
            }
            //print("Names: \(self.RestaurantData)")
        }
    }
    
    //Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.RestaurantData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Custom_RestaurantCell
        cell.restaurantNameLabel.text = ("\(self.RestaurantData[indexPath.row].restaurantName)")
        cell.restaurantAddressLabel.text = (" \(self.RestaurantData[indexPath.row].restaurantStreet), \(self.RestaurantData[indexPath.row].restaurantCity)\n \(self.RestaurantData[indexPath.row].restaurantState), \(self.RestaurantData[indexPath.row].restaurantZipCode) ")
        cell.restaurantPhoneNumberLabel.text = (" \(self.RestaurantData[indexPath.row].restaurantPhoneNumber)")
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Restaurant Clicked: \(self.RestaurantData[indexPath.row].restaurantName) ")
        RestaurantReservationsStatisticsPage.restaurantSelected = self.RestaurantData[indexPath.row].restaurantName
        RestaurantReservationsStatisticsPage.restaurantCode = self.RestaurantData[indexPath.row].restaurantCode
        self.performSegue(withIdentifier: "clickRestaurantToReservationsStatsSegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
class Custom_RestaurantCell: UITableViewCell {
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var restaurantAddressLabel: UILabel!
    @IBOutlet weak var restaurantPhoneNumberLabel: UILabel!
    
    
}
