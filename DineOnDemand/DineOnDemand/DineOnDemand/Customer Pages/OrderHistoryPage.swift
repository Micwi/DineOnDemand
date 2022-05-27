//
//  OrderHistoryPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/22/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class OrderHistoryPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    
    @IBOutlet weak var table: UITableView!
    var currentOrders = [[String: Any]](); var pastOrders = [[String: Any]]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        print("View Appeared")
        populateArrays()
    }
    
    func populateArrays() {
        currentOrders = [[String: Any]](); pastOrders = [[String: Any]]()
        let userID = FirebaseAuth.Auth.auth().currentUser?.uid ?? "nil"
        database.collection("order").whereField("account_id", isEqualTo: userID).getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    let orderStatus = data["status"] as! String
                    if orderStatus == "Order Complete" || orderStatus == "Delivered" { self.pastOrders.append(data) }
                    else { self.currentOrders.append(data) }
                }
            }
            self.sortOrderArrays()
            self.table.reloadData()
        }
    }
    
    func sortOrderArrays() {
        self.currentOrders.sort {
            item1, item2 in
            let date1 = item1["day_of_order"] as! String
            let date2 = item2["day_of_order"] as! String
            let time1 = item1["time_of_order"] as! String
            let time2 = item2["time_of_order"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
        self.pastOrders.sort {
            item1, item2 in
            let date1 = item1["day_of_order"] as! String
            let date2 = item2["day_of_order"] as! String
            let time1 = item1["time_of_order"] as! String
            let time2 = item2["time_of_order"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
    }
    
    // Populates the cells with data
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! orderCell
        if indexPath.section == 0 { // Use data from 'currentOrders' array
            cell.restaurantNameLabel.text = "\(currentOrders[indexPath.row]["restaurant_name"]!)"
            cell.dateTimePlacedLabel.text = "Placed \(currentOrders[indexPath.row]["day_of_order"]!) at \(currentOrders[indexPath.row]["time_of_order"]!)"
            cell.statusLabel.text = "Status: \(currentOrders[indexPath.row]["status"]!)"
            cell.orderTotalLabel.text = "Total: $\(currentOrders[indexPath.row]["order_total"]!)"
            cell.orderIDLabel.text = "Order ID: \(currentOrders[indexPath.row]["order_id"]!)"
        } else if indexPath.section == 1 { // Use data from 'pastOrders' array
            cell.restaurantNameLabel.text = "\(pastOrders[indexPath.row]["restaurant_name"]!)"
            cell.dateTimePlacedLabel.text = "Placed \(pastOrders[indexPath.row]["day_of_order"]!) at \(pastOrders[indexPath.row]["time_of_order"]!)"
            cell.statusLabel.text = "Status: \(pastOrders[indexPath.row]["status"]!)"
            cell.orderTotalLabel.text = "Total: $\(pastOrders[indexPath.row]["order_total"]!)"
            cell.orderIDLabel.text = "Order ID: \(pastOrders[indexPath.row]["order_id"]!)"
        }
        return(cell)
    }
    
    // Sets the height of the cells
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return(123)
    }
    
    // Sets the section titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = String()
        if section == 0 { sectionTitle = "Current Orders" } else if section == 1 { sectionTitle = "Past Orders" }
        return sectionTitle
    }
    
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if pastOrders.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return currentOrders.count
        } else if section == 1 {
            return pastOrders.count
        }
        return(0)
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
        print("Selected Section: \(indexPath.section)")
        if indexPath.section == 0 {
            // Current Order
            OrderDetailsPage.orderData = self.currentOrders[indexPath.row]
        } else if indexPath.section == 1 {
            // Past Order
            OrderDetailsPage.orderData = self.pastOrders[indexPath.row]
        }
        self.performSegue(withIdentifier: "showOrderDetails", sender: self)
    }
    
}

class orderCell: UITableViewCell {
    @IBOutlet weak var dateTimePlacedLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var orderTotalLabel: UILabel!
    @IBOutlet weak var restaurantNameLabel: UILabel!
    @IBOutlet weak var orderIDLabel: UILabel!
}
