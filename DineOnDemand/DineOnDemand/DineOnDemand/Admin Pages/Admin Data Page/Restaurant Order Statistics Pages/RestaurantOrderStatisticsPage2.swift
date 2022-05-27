//
//  RestaurantOrderStatisticsPage2.swift
//  DineOnDemand
//
//  Created by Louie Patrizi Jr. on 4/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class RestaurantOrderStatisticsPage2: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var totalNumberOfOrdersFromRestaurantLabel: UILabel!
    @IBOutlet weak var selectedRestaurantNameLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var ordersFromRestaurant = [orderInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedRestaurantNameLabel.text = RestaurantOrderStatisticsPage.restaurantSelected
        grabOrders()
        tableView.delegate = self
        tableView.dataSource = self
    }
    override func viewDidAppear(_ animated: Bool) {
        self.totalNumberOfOrdersFromRestaurantLabel.text = ("Total Number Of Orders for this Restaurant:      \(self.ordersFromRestaurant.count)")
    }
    func grabOrders(){
        ordersFromRestaurant = [orderInfo]()
        let docRef = self.database.collection("order").addSnapshotListener{[self]
            (QuerySnapshot, err) in
            if let err = err{
                //error occurred when trying to grab the data from firestore
                print("Error occurred when grabbing documents from database.")
                print("Error is: \(err)")
            }
            else{
                for doc in QuerySnapshot!.documents {
                    let Rcode = doc["restaurant_code"] as! String
                    if(Rcode == RestaurantOrderStatisticsPage.restaurantCode){
                        let nameOnOrder = doc["ordered_by"] as! String
                        let orderID = doc["order_id"] as! String
                        let orderType = doc["order_type"] as! String
                        let dateOfOrder = doc["day_of_order"] as! String
                        ordersFromRestaurant.append(orderInfo(orderDate: dateOfOrder, nameOnOrder: nameOnOrder, orderID: orderID, orderType: orderType))}
                }
                tableView.reloadData()
            }
            //print("Names: \(self.ordersFromRestaurant)")
    }
    }
    //Table View Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.ordersFromRestaurant.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomizedOrderCell
        cell.orderIDLabel.text = ("Order ID: \(self.ordersFromRestaurant[indexPath.row].orderID)")
        cell.dateOfOrderLabel.text = ("Order Date: \(self.ordersFromRestaurant[indexPath.row].orderDate)")
        cell.nameOfOrderLabel.text = ("Name on Order: \(self.ordersFromRestaurant[indexPath.row].nameOnOrder)")
        cell.orderTypeLabel.text = ("Order Type: \(self.ordersFromRestaurant[indexPath.row].orderType)")
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
struct orderInfo {
    var orderDate : String
    var nameOnOrder : String
    var orderID : String
    var orderType : String
}

class CustomizedOrderCell: UITableViewCell {
    @IBOutlet weak var orderIDLabel: UILabel!
    @IBOutlet weak var nameOfOrderLabel: UILabel!
    @IBOutlet weak var orderTypeLabel: UILabel!
    @IBOutlet weak var dateOfOrderLabel: UILabel!
    
}
