//
//  EmployeeOrdersPage.swift
//  DineOnDemand
//
//  Created by Robert Doxey on 3/23/22.
//

import UIKit
import Firebase
import FirebaseFirestore

class EmployeeOrdersPage: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let database = Firestore.firestore()
    @IBOutlet weak var table: UITableView!
    var ordersReadyForPickup = [[String: Any]](); var otherOrders = [[String: Any]]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        populateArrays()
    }
    
    @IBAction func refreshButton(_ sender: Any) {
        populateArrays()
    }
    
    func populateArrays() {
        ordersReadyForPickup = [[String: Any]](); otherOrders = [[String: Any]]()
        let dateFormatter = DateFormatter(); dateFormatter.dateFormat = "MM/dd/yy"
        let currentDate = dateFormatter.string(from: Date())
        database.collection("order")
            .whereField("restaurant_code", isEqualTo: Load.empRestaurantCode)
            .whereField("day_of_order", isEqualTo: currentDate)
            .getDocuments() { (querySnapshot, err) in
            if let err = err { print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents { let data = document.data()
                    if data["status"] as! String == "Ready for Pickup" { self.ordersReadyForPickup.append(data) }
                    else { self.otherOrders.append(data) }
                }
            }
            self.sortOrderArrays()
            self.table.reloadData()
        }
    }
    
    func sortOrderArrays() {
        self.ordersReadyForPickup.sort {
            item1, item2 in
            let date1 = item1["day_of_order"] as! String
            let date2 = item2["day_of_order"] as! String
            let time1 = item1["time_of_order"] as! String
            let time2 = item2["time_of_order"] as! String
            if date1 == date2 { return time1 > time2 } else { return date1 > date2 }
        }
        self.otherOrders.sort {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! empOrderCell
        if indexPath.section == 0 { // Use data from 'ordersReadyForPickup' array
            cell.orderedByLabel.text = "\(ordersReadyForPickup[indexPath.row]["ordered_by"]!)"
            cell.timePlacedLabel.text = "Placed at \(ordersReadyForPickup[indexPath.row]["time_of_order"]!)"
            cell.statusLabel.text = "Status: \(ordersReadyForPickup[indexPath.row]["status"]!)"
            cell.orderTotalLabel.text = "Total: $\(ordersReadyForPickup[indexPath.row]["order_total"]!)"
            cell.orderTypeLabel.text = "\(ordersReadyForPickup[indexPath.row]["order_type"]!) Order"
            cell.orderID.text = "Order ID: \(ordersReadyForPickup[indexPath.row]["order_id"]!)"
        } else if indexPath.section == 1 { // Use data from 'otherOrders' array
            cell.orderedByLabel.text = "\(otherOrders[indexPath.row]["ordered_by"]!)"
            cell.timePlacedLabel.text = "Placed at \(otherOrders[indexPath.row]["time_of_order"]!)"
            cell.statusLabel.text = "Status: \(otherOrders[indexPath.row]["status"]!)"
            cell.orderTotalLabel.text = "Total: $\(otherOrders[indexPath.row]["order_total"]!)"
            cell.orderTypeLabel.text = "\(otherOrders[indexPath.row]["order_type"]!) Order"
            cell.orderID.text = "Order ID: \(otherOrders[indexPath.row]["order_id"]!)"
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
        if section == 0 { sectionTitle = "Ready for Pickup" } else if section == 1 { sectionTitle = "Other Orders" }
        return sectionTitle
    }
    
    // Sets the number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections = 2; if otherOrders.isEmpty { numberOfSections = 1 }
        return(numberOfSections)
    }
    
    // Sets the number of rows in each section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return ordersReadyForPickup.count
        } else if section == 1 {
            return otherOrders.count
        }
        return(0)
    }
    
    // Ran when you tap a cell
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Section Tapped: \(indexPath.section)")
        table.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            // Ready for Pickup Order
            markAsPickedUpAlert(orderID: ordersReadyForPickup[indexPath.row]["order_id"] as! String, rowNumb: indexPath.row)
        } else if indexPath.section == 1 {
            // Any Other Order
            EmployeeOrderDetails.orderData = self.otherOrders[indexPath.row]
            self.performSegue(withIdentifier: "showOrderDetails", sender: self)
        }
    }
    
    func markAsPickedUpAlert(orderID: String, rowNumb: Int) {
        let alertController = UIAlertController(title: "Order Options", message: "Would you like to mark this order as picked up or view it's contents?", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Mark as Picked Up", style: .default) { _ in
            self.changeOrderStatus(orderID: orderID)
            self.populateArrays()
        }
        let viewContentsAction = UIAlertAction(title: "View Contents of Order", style: .default) { _ in
            EmployeeOrderDetails.orderData = self.ordersReadyForPickup[rowNumb]
            self.performSegue(withIdentifier: "showOrderDetails", sender: self)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in}
        alertController.addAction(cancelAction)
        alertController.addAction(viewContentsAction)
        alertController.addAction(confirmAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func changeOrderStatus(orderID: String) {
        self.database.collection("order").document("order_\(orderID)").setData([
            "status": "Order Complete",
        ], merge: true) { err in
            if let err = err { print("Error writing document: \(err)")
            } else { print("Document successfully written!") }
        }
    }
    
}

class empOrderCell: UITableViewCell {
    @IBOutlet weak var timePlacedLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var orderTotalLabel: UILabel!
    @IBOutlet weak var orderedByLabel: UILabel!
    @IBOutlet weak var orderTypeLabel: UILabel!
    @IBOutlet weak var orderID: UILabel!
}
